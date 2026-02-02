# TO-DO LIST
- [X] Definir a visão da nossa aplicação
- [X] Arquitetura de solução da aplicação (high level design)

# FIXES
- [ ] Check de Segurança de Aplicação [001-spec-fix]
- [ ] Não ativar a chave duas vezes [002-spec-fix]
- [ ] Extensão chrome, não suporta importação direta do supabase

# COPILOTOS
- [X] Copiloto de Product Owner
- [X] Criou primeira spec

# SEED SPEC
- [x] Executou no copiloto de programação
- [x] Check de Fake Functional
- [x] Check de Qualidade de Código


# Perssistência de dados
- [X] Salvar Pastas e Prompts em algum lugar
- [X] Controle de usuários
- [X] Garantiu Campos referente aos campos do Stripe

# Construir e Documentar o Back End
- [X] Ter um registro inicial de amostragem
- [X] Construir e Documentar o back End
  - [X] Testar Auth
      - [X] Criar usuário 
      - [X] Logar Usuário
  - [X] Testar e Listar endpoints de `Folders`
      - [X] Criar uma pasta
      - [X] Deletar uma pasta
      - [X] Editar uma pasta
      - [X] Listar Pastas
  - [X] Testar e Listar endpoints de `Prompts`
      - [X] Criar Prompts
      - [X] Deletar Prompts
      - [X] Editar Prompts
      - [X] Listar Prompts


# Como Conectar seu front-end com seu back-end
## Setup 
    - [X] constante: SUPABASE_URL
    - [X] constante: SUPABASE_ANON_KEY
    - [ ] armazenar o `USER_ACCESS_TOKEN`
    - [ ] Query De listagem Geral (dados do usuário, relação pastas e prompts para serem renderizados)
## Features

### Feature De Login
    - [ ] Sistema de Login
      - [ ] Query De listagem Geral (dados do usuário, relação pastas e prompts para serem renderizados)
        - [ ] Tela de Login 
        - [ ] Regra quando não tiver logado
        - [ ] Hooks: O que disparar ao logar
        - [ ] Cadastrar Novo usuário
      
### Feature de persistência
    - [ ] Persistência de dados
        - [ ] Pastas
        - [ ] Prompts
