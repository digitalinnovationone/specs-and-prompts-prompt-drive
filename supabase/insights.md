- Dica prática: criar profiles automaticamente em on_auth_user_created (trigger) ou via Edge Function.

5) Como isso encaixa com seus fluxos

Auth Supabase define auth.uid().
App faz CRUD em folders/prompts (RLS garante isolamento).

Stripe webhook atualiza subscriptions e também profiles.plan = premium/free conforme status (ex.: active/trialing => premium; demais => free).

Limite free (5 prompts): engine.js + (opcionalmente) trigger no DB.

- regra de atualização via webhook