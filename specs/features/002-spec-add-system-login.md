# Feature Context
Vamos criar uma tela de login inicial, essa tela deve conter: 
- um campo de `e-mail`
- um campo de `senha`
- botão de login
- botão de `criar nova conta`

## UI/UX
- A tela de login, deve ter o mesmo estilo de css e padrão visual que a nossa aplicação

## Constraints (guard rails)
- use o supabase apenas no modo `fetch`
- Deve criar (se não existir) no Chrome.storage.local uma variável chamada `USER_ACCESS_TOKEN` após a chamada do `api.doLogin()`
- Se não tiver nenhum value dentro do `USER_ACCESS_TOKEN`, ele sempre deve ser direcionado novamente para a tela de login
- Caso tenha algum valor dentro da `USER_ACCESS_TOKEN`, ele deve usar o id (do json user.id) retornado do usuário, para fazer o load inicial

## API Requests
Todas as requisições nesse processo

### Login ➡️
- deve ser implemetado do arquivo `app/scripts/api.js`
- a function deve ser `api.doLogin()`
- a função, deve receber como parametros [email] e [password]
- em caso de erro, deve exibir alguma mensagem de toast
- deve adaptar a chamada abaixo
- o retorno, caso bem sucedido deve armazenar o token de acesso no `USER_ACCESS_TOKEN` no Chrome.storage.local

```js
POST: `{{SUPABASE_URL}}/auth/v1/token?grant_type=password`
```

[Headers]
apikey: {{SUPABASE_ANON_KEY}}
Content-Type: application/json

[Body]

```json
{
  "email": [email],
  "password": [password]
}
```

Essa chamada **não é PostgREST** (não usa `/rest/v1/...`).
Ela usa o **Supabase Auth REST API** para login via senha (`grant_type=password`).

[Expect]
`200 OK` com JSON contendo, em geral:

* `access_token` (JWT)
* `refresh_token`
* `expires_in`
* `token_type` (geralmente `bearer`)
* `user` (objeto do usuário)

[Throws]
`400 Bad Request`: credenciais inválidas, payload inválido, ou `grant_type` incorreto.
`401 Unauthorized`: `apikey` ausente/inválida, ou login negado (varia conforme configuração).
`422 Unprocessable Entity`: dados inválidos (varia conforme config).
`429 Too Many Requests`: rate limit.
`500 Internal Server Error`: erro inesperado no serviço de auth.


### Create User ➡️
- Caso o usuário entre na função de `criar nova conta`, ele deve adaptar o request abaixo
- a function deve ser `api.createuser()`
- Essa tela, deve pedir [email], [senha], [nome]
- caso execute com sucesso, deve retornar um toast de `usuário criado com sucesso sucesso`,depois uma tela de `redirecionando` e retornar a tela de login inicial

```js
POST: `{{SUPABASE_URL}}/auth/v1/signup`
```

[Headers]
apikey: {{SUPABASE_ANON_KEY}}
Authorization: Bearer {{SUPABASE_ANON_KEY}}
Content-Type: application/json

[Body]

```json
{
  "email": [email],
  "password": [senha],
  "data": {
    "full_name": [nome]
  }
}
```

Essa chamada **não é PostgREST** (não usa `/rest/v1/...`).
Ela usa o **Supabase Auth REST API** (`/auth/v1/signup`).
No signup, normalmente o `Authorization` usa a mesma chave pública (anon) no formato `Bearer`.

[Expect]
`200 OK` (ou `201` dependendo do fluxo/projeto) com o JSON do usuário/sessão.
Se **email confirmation** estiver habilitado, você pode receber usuário sem sessão até confirmar o email.

[Throws]
`400 Bad Request`: email inválido, senha fraca, ou payload inválido.
`401 Unauthorized`: apikey inválida/ausente.
`422 Unprocessable Entity`: dados inválidos (varia conforme config).
`429 Too Many Requests`: limite/rate limit.
`500 Internal Server Error`: erro inesperado no serviço de auth.

### Initial Load ➡️
- Após logar com sucesso, e tenha um valor de `USER_ACCESS_TOKEN` na variável, e no state, possua o id do usuário, adapte a chamada abaixo, para fazer a requisição inicial dos dados do usuário e renderizar a estrutura inicial de pastas e prompts do usuário logado
- o nome da function deve ser `api.loadCurrentUserData`
- Remova, a leitura inicial de dados do usuário, do `seed.json` e traga da request abaixo, estamos removendo este mock

#### Request ao supbase
[request][supabase]
```js
 async function loadCurrentUserData() {
    // 1) Usuário autenticado
    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr) throw userErr;
    if (!user) return null;

    const userName =
      user.user_metadata?.full_name ??
      user.user_metadata?.name ??
      user.email ??
      "Sem nome";

    // 2) Profile
    const { data: profile, error: profileErr } = await supabase
      .from("profiles")
      .select("user_id, stripe_customer_id, plan")
      .eq("user_id", user.id)
      .single();

    if (profileErr) throw profileErr;

    // 3) Subscription (ativa ou mais recente)
    const { data: subscription, error: subErr } = await supabase
      .from("subscriptions")
      .select(`
        id,
        status,
        current_period_start,
        current_period_end,
        cancel_at_period_end
      `)
      .eq("user_id", user.id)
      .in("status", ["active", "trialing"])
      .order("current_period_end", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (subErr) throw subErr;

    // 4) Folders + Prompts
    const { data: folders, error: foldersErr } = await supabase
      .from("folders")
      .select(`
        id,
        name,
        created_at,
        updated_at,
        prompts (
          id,
          name,
          content,
          created_at,
          updated_at
        )
      `)
      .eq("user_id", user.id)
      .order("created_at", { ascending: true });

    if (foldersErr) throw foldersErr;

    // 5) Estado final
    return {
      user: {
        id: user.id,
        name: userName
      },
      profile: {
        stripe_customer_id: profile?.stripe_customer_id ?? null,
        plan: profile?.plan ?? "free"
      },
      subscription: subscription
        ? {
            id: subscription.id,
            status: subscription.status,
            period_start: subscription.current_period_start,
            period_end: subscription.current_period_end,
            cancel_at_period_end: subscription.cancel_at_period_end
          }
        : null,
      folders: (folders ?? []).map(f => ({
        ...f,
        prompts: f.prompts ?? []
      }))
    };
  }
```

#### formato da resposta esperada
```js
{
  user: {
    id: string
    name: string
  },
  profile: {
    stripe_customer_id: string | null
    plan: 'free' | 'premium'
  },
  subscription: {
    id: string
    status: string
    period_start: string | null
    period_end: string | null
    cancel_at_period_end: boolean
  } | null,
  folders: Array<{
    id: string
    name: string
    created_at: string
    updated_at: string
    prompts: Array<{
      id: string
      name: string
      content: string
      created_at: string
      updated_at: string
    }>
  }>
}
```

## Critérios de Aceite (QA)
- [ ] Deve criar (se não existir) no Chrome.storage.local uma variável chamada `USER_ACCESS_TOKEN`
- Se o `USER_ACCESS_TOKEN` estiver vazio, deve obrigatoriamente, voltar a tela inicial
- [ ] Ao Realizar Login, deve ter um valor em `USER_ACCESS_TOKEN` e um id de Usuário no State atual
- [ ] Ao fazer um login com sucesso, deve na sequência, fazer uma chamada de estrutura inicial conforme os padrões do `### Initial Load`