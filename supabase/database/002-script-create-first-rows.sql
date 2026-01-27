## SEED DE REGISTROS INICIAIS

-- =========================================
-- SEED COMPLETO (para usuário existente)
-- user_id: 980e2765-1993-4018-8eb9-f777d606976a
-- Cria/atualiza: profiles + 3 folders + 3 prompts + 1 subscription
-- =========================================

do $$
declare
  v_user_id uuid := '980e2765-1993-4018-8eb9-f777d606976a';

  -- IDs fixos gerados para o seed (pode trocar se quiser)
  v_folder_marketing uuid := 'c2e4f0e4-1b12-4c3b-9c24-6b99d3c7d8b1';
  v_folder_dev       uuid := '0f3f7d52-1f80-4b0c-9c1a-5a2d4a8b2a9a';
  v_folder_support   uuid := '7b4d9e61-ff6e-4ab0-9a3a-1d6b8b0d1c3e';

  v_prompt_1 uuid := '6d9fb0a4-0f6c-4e5f-8b25-0f7d9d2a1c11';
  v_prompt_2 uuid := 'b8f2c1d7-7b9a-4f46-9f8d-0a5b2c9d7e21';
  v_prompt_3 uuid := '3d7c5e2a-1a8f-4b13-8c2a-9d7e1f0b2c33';

  v_stripe_customer_id text := 'cus_test_980e2765_johny_blaze_001';
  v_stripe_subscription_id text := 'sub_test_980e2765_johny_blaze_001';
begin
  -- 1) PROFILES
  -- Trigger handle_new_user pode já ter criado profile.
  -- Aqui fazemos UPSERT e setamos premium + stripe_customer_id para o exemplo completo.
  insert into public.profiles (user_id, plan, stripe_customer_id)
  values (v_user_id, 'premium', v_stripe_customer_id)
  on conflict (user_id) do update
    set plan = excluded.plan,
        stripe_customer_id = excluded.stripe_customer_id;

  -- 2) FOLDERS (3 exemplos)
  -- Atenção: existe unique index (user_id, lower(name)).
  -- Se já existir uma pasta com mesmo nome (case-insensitive), isso vai falhar.
  insert into public.folders (id, user_id, name)
  values
    (v_folder_marketing, v_user_id, 'Marketing'),
    (v_folder_dev,       v_user_id, 'Desenvolvimento'),
    (v_folder_support,   v_user_id, 'Suporte');

  -- 3) PROMPTS (3 exemplos)
  -- Atenção: unique index (user_id, folder_id, lower(name)).
  insert into public.prompts (id, user_id, folder_id, name, content)
  values
    (
      v_prompt_1,
      v_user_id,
      v_folder_marketing,
      'Post para Redes Sociais',
      'Crie um post engajador para [plataforma] sobre [tema]. Inclua CTA e use um tom [tom].'
    ),
    (
      v_prompt_2,
      v_user_id,
      v_folder_dev,
      'Revisão de Código',
      'Revise o código [código] e dê feedback sobre performance, segurança, legibilidade e boas práticas.'
    ),
    (
      v_prompt_3,
      v_user_id,
      v_folder_support,
      'Resposta de Suporte',
      'Responda com empatia ao cliente sobre [problema]. Seja claro e ofereça uma solução em etapas.'
    );

  -- 4) SUBSCRIPTIONS (espelho do Stripe)
  -- Atenção: stripe_subscription_id é UNIQUE.
  insert into public.subscriptions (
    user_id,
    stripe_subscription_id,
    stripe_customer_id,
    status,
    price_id,
    product_id,
    currency,
    interval,
    interval_count,
    current_period_start,
    current_period_end,
    cancel_at_period_end,
    canceled_at,
    ended_at
  )
  values (
    v_user_id,
    v_stripe_subscription_id,
    v_stripe_customer_id,
    'active',
    'price_test_monthly_001',
    'prod_test_premium_001',
    'usd',
    'month',
    1,
    now(),
    now() + interval '30 days',
    false,
    null,
    null
  );

  raise notice 'Seed concluído para user_id=% | folders=(%,%,%) | prompts=(%,%,%) | stripe=(%,%)',
    v_user_id,
    v_folder_marketing, v_folder_dev, v_folder_support,
    v_prompt_1, v_prompt_2, v_prompt_3,
    v_stripe_customer_id, v_stripe_subscription_id;
end
$$;
