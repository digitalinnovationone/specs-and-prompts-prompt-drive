# Contexto
Adicionar a comunicação com o , estamos preparando o prompt para interagir com o supabase 

- Inserir no HTML:
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

- No Initialize da aplicação, criar uma instância do banco:
```js
 const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

- Adicione as contantes no arquivo `constants.js` caso não exista
```js
// Constants Supabase
// ====================================================
const SUPABASE_URL = 'https://etzlgzpyshwdijyucsog.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_j4obQ3BcN9ZF9DvwmBMCtg_UT4i6ZLu';
```
