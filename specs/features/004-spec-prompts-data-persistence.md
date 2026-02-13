# Feature Context
Quero implementar a persistência de dados, na hora de criar, atualizar e deletar os prompts, da minha aplicação, com o supabase

## Constraints (guard rails)
- Sempre utilize uma chamada fetch
- No `Authorization`, sempre passe no Bearer a acess token do usuário logado, que está em `USER_ACCESS_TOKEN`
- Caso não tenha nenhum valor em `USER_ACCESS_TOKEN`, qualquer ação fetch não deve ser executada, e deve redirecionar automaticamente para a tela de login
- Sempre pegue o id correto da folder em `promptFolderId` antes de realizar qualquer operação
- Implemente os tratamentos de erros para cada [Throws]

## API Requests
Todas as requisições nesse processo serão feitas no arquivo `app/scripts/api.js`, aonde se encontram já as declarações dos métodos para isso

### Create Prompt ➡️
- adapte a função abaixo
```js
  createPrompt: (payload) => {
    console.log('[API] createPrompt', payload);
    // Future: fetch POST /api/prompts
  }
```

- para a chamada abaixo

```js
POST: `{{SUPABASE_URL}}/rest/v1/prompts`
```

[Headers]

* apikey: {{SUPABASE_ANON_KEY}}
* Authorization: Bearer {{USER_ACCESS_TOKEN}}
* Content-Type: application/json
* Prefer: return=representation

[Body]

```json
{
  "user_id":[user id que está no state],
  "folder_id": o id da pasta selecionada (`promptFolderId`) value,
  "name": [input do usuario vindo da modal do campo `promptNome`],
  "content": [input vindo da modal do campo `promptConteudo`]"
}
```

Você precisa enviar `user_id` e `folder_id`, porque são `NOT NULL` e não têm default.
O RLS vai garantir que `user_id = auth.uid()`.
O trigger `enforce_prompt_folder_ownership` garante que o `folder_id` pertence ao mesmo `user_id`.
Se o usuário estiver no plano `free`, o trigger `enforce_free_prompt_limit` bloqueia acima de 5 prompts.

[Expect]

* `201 Created` (ou `200`) + JSON do prompt (se usou `Prefer: return=representation`).

[Throws]

* `400 Bad Request`: faltou `name/content` ou vieram vazios (CHECK `char_length(trim(...)) > 0`).
* `401 Unauthorized`: token ausente/ inválido.
* `403 Forbidden`: RLS bloqueou (token de outro usuário ou `user_id` não bate com `auth.uid()`).
* `409 Conflict`: já existe prompt com mesmo `name` (case-insensitive) no mesmo `folder_id` para esse `user_id` (unique index `(user_id, folder_id, lower(name))`).
* `500 / 400` com mensagem `Folder does not belong to user`: trigger de ownership bloqueou.
* `500 / 400` com mensagem `Free plan limit reached (5 prompts)`: limite do plano free atingido.



### Update Prompt ➡️
- adapte a função abaixo
```js
  updatePrompt: (payload) => {
    console.log('[API] updatePrompt', payload);
    // Future: fetch PUT /api/prompts/:promptId
  }
```

- para a chamada abaixo

variaveis:
{{PROMPT_ID}} = [id do prompt selecionado]

```js
PATCH: `{{SUPABASE_URL}}/rest/v1/prompts?id=eq.{{PROMPT_ID}}`
```

[Headers]

* apikey: {{SUPABASE_ANON_KEY}}
* Authorization: Bearer {{USER_ACCESS_TOKEN}}
* Content-Type: application/json
* Prefer: return=representation

[Body] (exemplo: atualizando nome e conteúdo)

```json
{
  "name": [input do usuario vindo da modal do campo `promptNome`],
  "content": [input vindo da modal do campo `promptConteudo`]
}
```

Você **não precisa** reenviar `user_id` e `folder_id` se não for alterá-los.
O `updated_at` será atualizado automaticamente (trigger `set_updated_at`).
Se você tentar alterar `folder_id` (ou `user_id`), o trigger de ownership valida se a pasta é do mesmo usuário.

[Expect]

* `200 OK` + JSON atualizado (se usou `Prefer: return=representation`).

[Throws]

* `401 Unauthorized`: token ausente/ inválido.
* `403 Forbidden`: RLS bloqueou (você não é dono do registro).
* `409 Conflict`: ao renomear, colidiu com outro prompt no mesmo folder (case-insensitive).
* `400 Bad Request`: `name/content` vazio (falha no CHECK).
* `500 / 400` com mensagem `Folder does not belong to user`: ao trocar `folder_id` para pasta de outro usuário.

### Delete Prompt ➡️

- adapte a função abaixo
```js
  deletePrompt: (payload) => {
    console.log('[API] deletePrompt', payload);
    // Future: fetch DELETE /api/prompts/:promptId
  },
```

- para a chamada abaixo

variaveis:
{{PROMPT_ID}} = [id do prompt selecionado]

```js
DELETE: `{{SUPABASE_URL}}/rest/v1/prompts?id=eq.{{PROMPT_ID}}`
```

[Headers]

* apikey: {{SUPABASE_ANON_KEY}}
* Authorization: Bearer {{USER_ACCESS_TOKEN}}
* Prefer: return=representation

[Body]

* (nenhum)

[Expect]

* `200 OK` + JSON removido (se usou `Prefer: return=representation`)
  ou
* `204 No Content` (se não pediu representação)

[Throws]

* `401 Unauthorized`: token ausente/ inválido.
* `403 Forbidden`: RLS bloqueou (você não é dono do prompt).