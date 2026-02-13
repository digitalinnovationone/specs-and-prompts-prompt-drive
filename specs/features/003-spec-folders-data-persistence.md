# Feature Context
Quero implementar a persistência de dados, na hora de criar, atualizar e deletar as pastas (folders), da minha aplicação, com o supabase

## Constraints (guard rails)
- Sempre utilize uma chamada fetch
- No `Authorization`, sempre passe no Bearer a acess token do usuário logado, que está em `USER_ACCESS_TOKEN`
- Caso não tenha nenhum valor em `USER_ACCESS_TOKEN`, qualquer ação fetch não deve ser executada, e deve redirecionar automaticamente para a tela de login

## API Requests
Todas as requisições nesse processo serão feitas no arquivo `app/scripts/api.js`, aonde se encontram já as declarações dos métodos para isso

### Create Folder ➡️
- adapte a função abaixo
```js
  createFolder: (payload) => {
    console.log('[API] createFolder', payload);
    // Future: fetch POST /api/folders
  },
```

- para a chamada abaixo
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
  "user_id": [usuário do id logado no state],
  "name": [nome da pasta dado pelo usuário]
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



### Atualizar Folder ➡️
- adapte a função abaixo
```js
  updateFolder: (payload) => {
    console.log('[API] updateFolder', payload);
  }
```

- para a chamada abaixo
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
  "name": [nome atualizado pelo usuário]
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

### Delete Folder ➡️

- adapte a função abaixo
```js
  deleteFolder: (payload) => {
    console.log('[API] deleteFolder', payload);
  },
```

- para a chamada abaixo
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