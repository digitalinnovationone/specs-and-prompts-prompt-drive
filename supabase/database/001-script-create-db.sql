-- =========================================
-- 0) EXTENSIONS (UUID generation)
-- =========================================
create extension if not exists pgcrypto;

-- =========================================
-- 1) TABLES
-- =========================================

-- 1.1) profiles
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,

  plan text not null default 'free'
    check (plan in ('free', 'premium')),

  -- Stripe mapping (customer)
  stripe_customer_id text unique,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_plan on public.profiles(plan);


-- 1.2) folders
create table if not exists public.folders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  name text not null
    check (char_length(trim(name)) > 0),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- IMPORTANT (PostgreSQL): UNIQUE constraint cannot use expressions like lower(name).
-- Use a UNIQUE INDEX for case-insensitive uniqueness per user.
create unique index if not exists uq_folders_user_lower_name
  on public.folders (user_id, lower(name));

create index if not exists idx_folders_user_id
  on public.folders(user_id);

create index if not exists idx_folders_user_lower_name
  on public.folders(user_id, lower(name));


-- 1.3) prompts
create table if not exists public.prompts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  folder_id uuid not null references public.folders(id) on delete cascade,

  name text not null
    check (char_length(trim(name)) > 0),
  content text not null
    check (char_length(trim(content)) > 0),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Case-insensitive uniqueness of prompt name within the same folder for the same user
create unique index if not exists uq_prompts_user_folder_lower_name
  on public.prompts (user_id, folder_id, lower(name));

create index if not exists idx_prompts_user_id
  on public.prompts(user_id);

create index if not exists idx_prompts_user_folder
  on public.prompts(user_id, folder_id);

create index if not exists idx_prompts_user_lower_name
  on public.prompts(user_id, lower(name));


-- 1.4) subscriptions (Stripe mirror)
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  stripe_subscription_id text not null unique,
  stripe_customer_id text not null,

  status text not null, -- e.g. active, trialing, past_due, canceled, unpaid, incomplete...
  price_id text,
  product_id text,
  currency text,
  interval text,        -- month/year
  interval_count int,

  current_period_start timestamptz,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  canceled_at timestamptz,
  ended_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_subscriptions_user_id
  on public.subscriptions(user_id);

create index if not exists idx_subscriptions_status
  on public.subscriptions(status);

create index if not exists idx_subscriptions_customer
  on public.subscriptions(stripe_customer_id);

-- =========================================
-- 2) GENERIC updated_at TRIGGER
-- =========================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_folders_updated_at on public.folders;
create trigger trg_folders_updated_at
before update on public.folders
for each row execute function public.set_updated_at();

drop trigger if exists trg_prompts_updated_at on public.prompts;
create trigger trg_prompts_updated_at
before update on public.prompts
for each row execute function public.set_updated_at();

drop trigger if exists trg_subscriptions_updated_at on public.subscriptions;
create trigger trg_subscriptions_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

-- =========================================
-- 3) DATA INTEGRITY TRIGGERS
-- =========================================

-- 3.1) Ensure prompt.folder belongs to the same user_id
create or replace function public.enforce_prompt_folder_ownership()
returns trigger as $$
begin
  if not exists (
    select 1
    from public.folders f
    where f.id = new.folder_id
      and f.user_id = new.user_id
  ) then
    raise exception 'Folder does not belong to user';
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_enforce_prompt_folder_ownership on public.prompts;
create trigger trg_enforce_prompt_folder_ownership
before insert or update of folder_id, user_id
on public.prompts
for each row execute function public.enforce_prompt_folder_ownership();


-- 3.2) Enforce FREE prompt limit (5) on INSERT (optional but recommended)
create or replace function public.enforce_free_prompt_limit()
returns trigger as $$
declare
  v_plan text;
  v_count int;
begin
  select p.plan into v_plan
  from public.profiles p
  where p.user_id = new.user_id;

  if coalesce(v_plan, 'free') = 'free' then
    select count(*) into v_count
    from public.prompts
    where user_id = new.user_id;

    if v_count >= 5 then
      raise exception 'Free plan limit reached (5 prompts)';
    end if;
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_enforce_free_prompt_limit on public.prompts;
create trigger trg_enforce_free_prompt_limit
before insert on public.prompts
for each row execute function public.enforce_free_prompt_limit();

-- =========================================
-- 4) RLS (Row Level Security)
-- =========================================
alter table public.profiles enable row level security;
alter table public.folders enable row level security;
alter table public.prompts enable row level security;
alter table public.subscriptions enable row level security;

-- =========================================
-- 5) POLICIES
-- =========================================

-- 5.1) profiles: CRUD own
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
using (auth.uid() = user_id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
with check (auth.uid() = user_id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "profiles_delete_own" on public.profiles;
create policy "profiles_delete_own"
on public.profiles for delete
using (auth.uid() = user_id);


-- 5.2) folders: CRUD own
drop policy if exists "folders_crud_own" on public.folders;
create policy "folders_crud_own"
on public.folders for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);


-- 5.3) prompts: CRUD own
drop policy if exists "prompts_crud_own" on public.prompts;
create policy "prompts_crud_own"
on public.prompts for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);


-- 5.4) subscriptions: select own ONLY (writes must be via service role/webhooks)
drop policy if exists "subscriptions_select_own" on public.subscriptions;
create policy "subscriptions_select_own"
on public.subscriptions for select
using (auth.uid() = user_id);

-- =========================================
-- 6) OPTIONAL: AUTO-CREATE PROFILE ON SIGNUP
-- =========================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (user_id, plan)
  values (new.id, 'free')
  on conflict (user_id) do nothing;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
