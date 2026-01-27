Com base no seu conhecimento do meu banco postgre no supabase, gere pra mim o detalhamento das chamadas da tabela prompt (`public.prompts`) no padrão `PostgREST`

Crie as 4 operações abaixo:
#### Criar prompt
#### Atualizar prompt
#### Deletar Prompt
#### Listar Prompt


Quero no mesmo formato do padrão abaixo, e deixe no formato markdown a resposta

EXEMPLO
``` 
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

[Resposta_Esperada]
`201 Created` (ou 200 dependendo de config) + o JSON da pasta (se você usou Prefer: return=representation).

[Erros_comuns]
`401 Unauthorized`: faltou/está inválido o Authorization: Bearer <token>.
`403 Forbidden:` RLS bloqueou (ex.: token de outro usuário, ou user_id não bate com o auth.uid()).
`409 Conflict:` você já tem pasta com o mesmo nome case-insensitive (por causa do unique index (user_id, lower(name))).
``` 
