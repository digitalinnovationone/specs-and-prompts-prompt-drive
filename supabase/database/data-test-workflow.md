# Data Test 

## usuário de teste
uuid: 980e2765-1993-4018-8eb9-f777d606976a
user: jb@dio.me
pass: 12345678



## ➡️ Endpoints:

### 🧑 [Users]

#### Create User

#### Login User

### 📁 [Folders]

#### ➕ Criar Pasta

```js
POST: `{{SUPABASE_URL}}/rest/v1/folders`
```

[Headers]
apikey: {{SUPABASE_ANON_KEY}}
Authorization: Bearer {{USER_ACCESS_TOKEN}}
Content-Type: application/json
Prefer: return=representation

[Body]
```json
{
  "user_id": "980e2765-1993-4018-8eb9-f777d606976a",
  "name": "Marketing"
}
```

Você precisa enviar user_id, porque sua coluna é NOT NULL e não tem default.
O RLS vai garantir que esse user_id é igual a auth.uid() (policy with check).

[Expect]
`201 Created` (ou 200 dependendo de config) + o JSON da pasta (se você usou Prefer: return=representation).

[Throws]
`401 Unauthorized`: faltou/está inválido o Authorization: Bearer <token>.
`403 Forbidden:` RLS bloqueou (ex.: token de outro usuário, ou user_id não bate com o auth.uid()).
`409 Conflict:` você já tem pasta com o mesmo nome case-insensitive (por causa do unique index (user_id, lower(name))).


#### ✏️ Atualizar Pasta

```js
PATCH: `{{SUPABASE_URL}}/rest/v1/folders?id=eq.{{FOLDER_ID}}`
```

[Headers]
apikey: {{SUPABASE_ANON_KEY}}
Authorization: Bearer {{USER_ACCESS_TOKEN}}
Content-Type: application/json
Prefer: return=representation

[Body]
```json
{
  "name": "Marketing - Johny"
}
```

[Expect]
`Status 200` OK
Resposta com um array contendo a pasta atualizada (por causa do Prefer: return=representation).
Seu trigger set_updated_at() vai atualizar updated_at automaticamente.


[Throws]
`403 Forbidden:` o access_token não é do dono da pasta (RLS bloqueou).
`409 Conflict:` já existe outra pasta do mesmo usuário com name igual (case-insensitive), por causa do unique index (user_id, lower(name)).
0 linhas afetadas: o id está errado ou não pertence ao usuário do token.


#### 🗑️ Deletar Pasta
```js
DELETE: `{{SUPABASE_URL}}/rest/v1/folders?id=eq.{{FOLDER_ID}}`
```

[Headers]
apikey: {{SUPABASE_ANON_KEY}}
Authorization: Bearer {{USER_ACCESS_TOKEN}}
Prefer: return=representation

[Body]
(não tem body)

[Throws]
`401 Unauthorized` faltou/expirou o Authorization: Bearer <token>.
`403 Forbidden` o token não é do dono da pasta (RLS bloqueia).
`200 com array vazio (ou 204)` nenhum registro bateu com o filtro (id errado ou não pertence ao usuário).


#### 📚 Listar Pastas
```js
GET: `{{SUPABASE_URL}}/rest/v1/folders?select=id,name,created_at,updated_at&order=created_at.desc`
```

[Headers]
apikey: {{SUPABASE_ANON_KEY}}
Authorization: Bearer {{USER_ACCESS_TOKEN}}

[Body]
(não tem body)

[Throws]

--- 


### 📄 [Prompts]

#### ➕ Criar prompt

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
  "user_id": "980e2765-1993-4018-8eb9-f777d606976a",
  "folder_id": "c2e4f0e4-1b12-4c3b-9c24-6b99d3c7d8b1",
  "name": "Post para Redes Sociais",
  "content": "Crie um post engajador para [plataforma] sobre [tema]. Inclua CTA e use um tom [tom]."
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

---

#### ✏️ Atualizar prompt

variaveis:
{{PROMPT_ID}} = "6d9fb0a4-0f6c-4e5f-8b25-0f7d9d2a1c11"

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
  "name": "Post para Instagram",
  "content": "Crie um post curto e engajador para Instagram sobre [tema]. Inclua CTA."
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

---

#### 🗑️ Deletar Prompt

variaveis:
{{PROMPT_ID}} = "6d9fb0a4-0f6c-4e5f-8b25-0f7d9d2a1c11"

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

---

#### 📚 Listar Prompt

```js
GET: `{{SUPABASE_URL}}/rest/v1/prompts?select=id,user_id,folder_id,name,content,created_at,updated_at&order=created_at.desc`
```

[Headers]

* apikey: {{SUPABASE_ANON_KEY}}
* Authorization: Bearer {{USER_ACCESS_TOKEN}}

[Body]

* (nenhum)

O RLS vai retornar **somente** prompts do usuário autenticado (`auth.uid() = user_id`), mesmo sem você filtrar.

[Expect]

* `200 OK` + array JSON de prompts do usuário.

[Throws]

* `401 Unauthorized`: token ausente/ inválido.
* `403 Forbidden`: raro em SELECT aqui, mas pode ocorrer se configuração/policy estiver inconsistente.

