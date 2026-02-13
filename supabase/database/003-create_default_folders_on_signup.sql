-- =========================================
-- Trigger: Criar pastas e prompts padrão para novos usuários
-- =========================================
-- Quando um novo perfil é criado (após signup), cria duas pastas
-- com prompts de exemplo.
-- =========================================

create or replace function public.handle_new_user_default_folders()
returns trigger as $$
declare
  v_folder_emails_id uuid;
  v_folder_formalidade_id uuid;
begin
  -- 1) Pasta "templates de emails" com prompt de e-mail com variáveis
  insert into public.folders (user_id, name)
  values (new.user_id, 'templates de emails')
  returning id into v_folder_emails_id;

  insert into public.prompts (user_id, folder_id, name, content)
  values (
    new.user_id,
    v_folder_emails_id,
    'Template de e-mail com variáveis',
    'Crie um template de e-mail profissional que utilize as seguintes variáveis: {{nome}}, {{empresa}}, {{assunto}}. O e-mail deve ser claro, objetivo e permitir personalização fácil. Inclua uma saudação apropriada e uma despedida profissional.'
  );

  -- 2) Pasta "tom de formalidade" com prompt de resposta cordial
  insert into public.folders (user_id, name)
  values (new.user_id, 'tom de formalidade')
  returning id into v_folder_formalidade_id;

  insert into public.prompts (user_id, folder_id, name, content)
  values (
    new.user_id,
    v_folder_formalidade_id,
    'Responder e-mail de forma cordial',
    'Responda ao e-mail abaixo de maneira cordial e profissional, mantendo um tom de formalidade adequado. Seja educado, objetivo e prestativo, preservando a mensagem original mas com linguagem clara e receptiva.'
  );

  return new;
end;
$$ language plpgsql security definer;

-- Trigger: dispara após inserção de novo perfil (criado pelo handle_new_user no signup)
drop trigger if exists trg_profiles_default_folders on public.profiles;
create trigger trg_profiles_default_folders
after insert on public.profiles
for each row execute function public.handle_new_user_default_folders();
