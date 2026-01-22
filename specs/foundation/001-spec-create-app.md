# AGENTS.MD - Prompt Drive

## 1) Contexto do App e Objetivo

- Produto: **extensão do Chrome (Side Panel)** como **gerenciador de prompts**.
- Organização: prompts em **pastas** (estilo Google Drive).
- Seed inicial: `data/seed.json` com pastas de prompts de exemplo
- Planos:
  - **Free**: no máximo **5 prompts** no total do app.
  - **Premium**: remove limite e adiciona no header um botão para **importar JSON de uma pasta** (além de liberar recursos premium descritos).

### Requisitos mínimos 

ids sempre serão no formato UUID

Cada prompt deve possuir obrigatoriamente:
- `id` (único)
- `nome`
- `conteudo` (texto do prompt)

---

## 2) Tech Stack & Coding Guideline

### 2.1 Tecnologias

- **HTML5**: estrutura
- **CSS3**: estilos e responsividade
- **JavaScript (Vanilla)**: lógica
- **Chrome Extension API**: Manifest V3

### 2.2 Padrões de Código

#### Regras gerais (aplicam para tudo)
- Código limpo, organizado e modular (separação por responsabilidade)
- Nomenclatura descritiva e consistente
- Comentários somente quando agregarem contexto (explicar “por quê”, não o óbvio)
- Evitar duplicação (DRY) e manter funções/arquivos coesos

#### HTML
- Estrutura semântica quando aplicável (main, section, header, etc.)
- Comentários quando necessário
- Evite inline scripts no HTML 
  - nada de <script> com lógica “solta” no arquivo HTML; referencie arquivos externos
- Comentários quando necessário, usando estilos padronizados:
  - Usado para “títulos” e início de grandes sessões delimitação visual.
    <!-- =========================
        Exemplo
    ========================= -->
  - Use Comentário de agrupamento / etiqueta rápida Mais curto, só para separar partes.
    <!-- Dialogs -->
    <!-- Create Folder Dialog -->
- Regra de data-attributes para hooks de JS (ex.: data-testid, data-action) para não acoplar JS a classes de estilo.

#### CSS
- Código limpo, organizado e modular
- Utilize o padrão de nomenclatura BEM (Block, Element, Modifier)
- Nomenclatura descritiva e consistente
- Comentários quando necessário

#### JavaScript (JS)
- Código limpo, organizado e modular
- Evitar funções anônimas (preferir funções nomeadas)
- Funções com responsabilidade única (SRP)
- Comentários quando necessário
- Evite o uso de classes: usar paradigma funcional sempre que possível
- Evite “spaghetti async”: preferir async/await com fluxo claro (encadeamento e tratamento de erros bem definidos)
- Use data-* para “marcar” elementos (melhor do que depender de texto/classe para lógica)
- Padrão de Nomenclaturas
  - Verbos para ações: getUser, createFolder, validateForm.
  - Handlers com prefixo handle: handleClick, handleSubmit
  - Booleanos com prefixo: isOpen, hasPermission, canEdit.
  - Evite abreviações obscuras: prefira claro > curto.
  - Nomenclatura descritiva e consistente

  ### 2.3 Responsividade

- Adaptável para diferentes tamanhos do Side Panel
- preferir layout fluido e min-width/max-width com flex/grid antes de criar muitos breakpoints.
- Breakpoints mínimos: 320px, 768px, 1024px

---

## 3) Arquitetura e Organização de Diretórios

### 3.1 Estrutura de Diretórios (Obrigatória)

```txt
project/
├── index.html
├── manifest.json
├── app/
│   ├── styles/
│   │   ├── main.css
│   │   ├── components.css
│   │   └── responsive.css
│   └── scripts/
│       ├── constants.js
│       ├── states.js
│       ├── engine.js
│       ├── render.js
│       └── service.js
│       └── app.js
│       └── api.js
├── data/
│   └── seed.json
└── ext/
    └── worker.js
```

### 3.2 Responsabilidades dos Módulos

#### `constants.js`

- Limites de planos (ex: `FREE_MAX_PROMPTS = 5`)
- URLs (ex: landing page)
- IDs/seletores DOM
- Mensagens de toast
- Constantes de estado de UI

#### `states.js` (State Container — Fonte da Verdade)

- **Única fonte da verdade** em runtime (memória).
- Estado do usuário:
  - `plan: 'free' | 'premium'`
  - `licenseKey?: string`
  - `licenseExpiry?: number`
- Estado da UI:
  - modais abertos/fechados
  - pastas expandidas
  - loading / error
- Estado dos dados:
  - folders
  - prompts
  - relacionamento folder -> prompts
- API do state (mínimo esperado):
  - `getState()`
  - `setState(partial|recipe)`
  - `subscribe(listener)` / `unsubscribe`
  - selectors/derived state (ex: `getPromptCountTotal()`)

> Sem qualquer persistência. Ao recarregar/reabrir, o estado volta ao seed.

#### `engine.js`

- Regras de negócio + orquestração:
  - limite Free (5)
  - gating premium (share/import/export)
  - validações de formulários
  - validação de schema no import
  - conflitos: IDs e nomes duplicados
  - **inicialização robusta**: carregamento do seed.json com tratamento de encoding, múltiplos caminhos e fallback inline
- Fluxo:
  - recebe eventos da UI
  - aplica regras
  - atualiza `states.js`
  - chama `render.js`

#### `render.js`

- Renderização/DOM:
  - pastas e prompts
  - contador e badge
  - modais e dialogs
  - empty/loading/error states
- Deve reagir ao state:
  - ideal: render por subscribe no `states.js`

#### `service.js`

- **Sem persistência por enquanto.**
- Responsável apenas por:
  - operações auxiliares (ex: gerar IDs, parse/validate JSON)
  - integração com browser APIs não persistentes (ex: clipboard, file input parsing)
  - validação de license key (stub/serviço)

#### `app.js`
- Arquivo principal com a chamada de Initialize application 

#### `api.js`
- `api.js` (Contrato de integração com backend — stub por enquanto)
- Centraliza todas as chamadas ao backend do app (uma “camada API”).
- Por enquanto não faz rede: apenas emite console.log() com o nome da ação e os parâmetros recebidos.
- No futuro, somente api.js deve conhecer detalhes de endpoint/headers/auth/retries.
- engine.js deve chamar api.js ao executar as ações (CRUD e ativação premium), mantendo as regras de negócio no engine.js.

- Arquivo principal com a chamada de Initialize application
- Criar pastas `createFolder(userId, FolderId, FolderName)` 
- Por hora não implemente essas funções, o backend será feito no futuro, por hora apenas capture os eventos e exiba o evento que ocorreu e a captura dos inputs em `console.log()`

---

## 4) UI/UX — Especificação

### 4.1 Header

#### 4.1.1 Lado Esquerdo

- Logo 32x32px
- Nome: "Prompt DRIVE" (18px, 600)

#### 4.1.2 Lado Direito

- `#btnCreateFolder` — "+ pasta" (tooltip "Criar nova pasta")
- `#btnCreatePrompt` — "+ prompt" (tooltip "Criar novo prompt")
- `#btnLicenseKey` — "Serial Key" (tooltip "")
- `#promptCounter` — contador:
  - Free: `X / 5`
  - Premium: `X / ∞`

Layout: flex `justify-content: space-between`.

> Premium: adicionar no header um botão para importar JSON de uma pasta (além dos ícones por pasta), conforme objetivo.

### 4.2 Corpo (Main Content)

#### 4.2.1 Listagem de Pastas

- Lista/grid vertical
- Item pasta:
  - ícone
  - nome
  - contador de prompts na pasta
  - exportar (Premium) - no lado direito
  - editar (Free e Premium) - no lado direito, antes do botão deletar
  - deletar (Free e Premium) - no lado direito, extremo direito
- **Clique em qualquer lugar da div da pasta**: expandir/colapsar prompts
- Botões de ação (exportar, deletar) não acionam o toggle ao serem clicados

#### 4.2.2 Listagem de Prompts

- Item prompt:
  - nome
  - preview do conteúdo (primeiros 100 caracteres, truncado com "..."), exibir em uma quebra para ficar no máximo 2 linhas
  - copiar para clipboard (Free e Premium)
  - editar
  - excluir
- Ordenação: alfabética por `nome`

#### 4.2.3 Estados

- Empty: sem pastas / sem prompts
- Loading: spinner + "Carregando..."
- Erro: mensagem + "Tentar novamente"

### 4.3 Footer

- `#userPlanBadge`: "Free" (cinza) ou "Premium" (dourado)

### 4.4 Modais e Dialogs

- `#folderDialog` criar pasta
- `#editFolderDialog` editar nome da pasta
- `#promptDialog` criar prompt
- `#promptEditDialog` editar prompt
- `#confirmDeletePromptDialog` confirmar exclusão de prompt
- `#deleteFolderDialog` confirmar exclusão de pasta
- `#licenseDialog` ativar premium
- `#importDialog` importar pasta

**Regras de exibição:**
- Todos os diálogos devem estar **centralizados** na tela (vertical e horizontalmente)
- Todos os diálogos devem fechar ao pressionar a tecla **ESC**
- Todos os diálogos devem fechar automaticamente após a confirmação de uma ação (criar, editar, excluir, etc.)

**Textos de ajuda nos dialogs de Prompt:**
- Os dialogs `#promptDialog` (criar) e `#promptEditDialog` (editar) devem exibir um texto de rodapé abaixo do campo de conteúdo incentivando o uso de variáveis no formato `[nome]`
- Exemplo: "💡 **Dica:** Use variáveis no formato [nome] para tornar seus prompts mais flexíveis e reutilizáveis. Exemplo: 'Crie um post sobre [tema] para [plataforma]'"
- O texto deve ter destaque visual (fundo azul claro, borda esquerda azul) para chamar atenção

**Dialog de Deletar Pasta (`#deleteFolderDialog`):**
- Deve exibir no topo: ícone de pasta (📁) e nome da pasta que será deletada
- Deve exibir mensagem de aviso sobre exclusão permanente de todos os prompts
- Deve exigir que o usuário digite o nome da pasta exatamente igual (case-sensitive) para confirmar
- Campo de input para digitar o nome da pasta
- Botões: "Cancelar" e "Excluir Pasta" (vermelho/danger)
- Se o nome não conferir: mantém modal aberto e exibe toast de erro
- Se o nome conferir: deleta pasta e todos os prompts, fecha modal, exibe toast de sucesso

### 4.5 Acessibilidade

- `aria-label`, tooltip, foco visível, área 44x44
- Modais: `role="dialog"`, focus trap, fecha com ESC

---

## 5) Funcionamento das Features (Passo a Passo)

### 5.0 Inicialização (Boot)

AO INICIAR:

1. Ler `data/seed.json`.
2. Popular `states.js` com seed.
3. Renderizar UI baseada no state.

Regras:

- `states.js` é a fonte da verdade.
- Não existe persistência: reload/reabertura retorna ao seed.
- Tudo que o usuário fizer por hora será persistido no state

**Implementação do Carregamento do Seed:**

- **Múltiplos caminhos**: O `engine.js` deve tentar carregar o seed.json de múltiplos caminhos possíveis:
  - `./data/seed.json`
  - `/data/seed.json`
  - `data/seed.json`
- **Tratamento de encoding**: 
  - Ler a resposta como texto primeiro (não usar `.json()` diretamente)
  - Remover BOM (Byte Order Mark - `\uFEFF`) e outros caracteres invisíveis no início do arquivo
  - Aplicar `.trim()` e remover caracteres zero-width (`\u200B-\u200D\u2060`)
- **Fallback inline**: Se todos os caminhos falharem ou o parse do JSON falhar, usar dados inline hardcoded como fallback para garantir que a aplicação sempre inicialize
- **Tratamento robusto de erros**:
  - Verificar se a resposta HTTP é OK antes de processar
  - Capturar erros de parse separadamente e logar detalhes (primeiros 200 caracteres, código do primeiro caractere)
  - Exibir mensagem de erro amigável no estado da UI se falhar completamente

---

### Feature A: Criar Pasta (Free/Premium)

1. Clique `#btnCreateFolder`
2. Abre `#folderDialog`
3. Usuário informa nome
4. Confirma
5. `engine.js` valida nome
6. `engine.js` chama `FolderService.createFolder(name)` (no `service.js` apenas helpers/ID)
7. Sucesso:
   - atualiza `states.js`
   - fecha modal
   - toast "Pasta criada com sucesso"
   - re-render lista
8. Erro:
   - mantém modal
   - mostra erro no input
   - toast "Erro ao criar pasta"

> Integração backend (stub): `engine.js` também chama `api.createFolder(...)` para logar a ação.

Acceptance:

- A1: pasta aparece na lista e toast sucesso.
- A2: nome vazio não cria, mostra erro.
- A3: falha lógica (ex: exceção) não cria, feedback de erro.

---

### Feature A1: Editar Pasta (Free/Premium)

1. Clique no ícone de editar (✏️) no lado direito do header da pasta (antes do botão deletar)
2. Abre `#editFolderDialog`
3. Dialog exibe campo de input com o nome atual da pasta preenchido
4. Usuário edita o nome
5. Confirma (submit do formulário)
6. `engine.js` valida nome (mesmas regras de criação)
7. Se válido:
   - **Atualiza o state** via `stateManager.setState()` com o novo nome da pasta
   - Atualiza `updatedAt` da pasta
   - **Refresh automático da UI** via subscribe do renderer (disparado automaticamente pelo `setState`)
   - Fecha modal
   - Toast "Pasta atualizada com sucesso"
8. Erro:
   - mantém modal
   - mostra erro no input
   - toast "Erro ao atualizar pasta"

**Fluxo de atualização:**
- `engine.js` → `stateManager.setState()` → `notifyListeners()` → `renderer.render()` → UI atualizada

> Integração backend (stub): `engine.js` também chama `api.updateFolder(...)` para logar a ação.

Acceptance:

- A1-1: ícone de editar visível no lado direito de cada pasta (antes do deletar)
- A1-2: dialog exibe nome atual da pasta preenchido
- A1-3: nome vazio não atualiza, mostra erro
- A1-4: nome válido atualiza pasta e exibe toast de sucesso
- A1-5: nome atualizado aparece na lista após salvar

---

### Feature A2: Deletar Pasta (Free/Premium)

1. Clique no ícone de deletar (🗑️) no lado direito do header da pasta
2. Abre `#deleteFolderDialog`
3. Dialog exibe no topo:
   - Ícone de pasta (📁)
   - Nome da pasta que será deletada
   - Mensagem de aviso sobre exclusão permanente de todos os prompts
4. Usuário deve digitar o nome da pasta exatamente igual para confirmar
5. Confirma (submit do formulário)
6. `engine.js` valida:
   - Nome digitado confere exatamente com o nome da pasta (case-sensitive)
   - Se não conferir: mantém modal, toast "O nome digitado não confere com o nome da pasta"
7. Se válido:
   - **Atualiza o state** via `stateManager.setState()` removendo:
     - A pasta de `folders`
     - Todos os prompts da pasta de `prompts`
     - Referências de prompts em `folderPrompts`
   - **Refresh automático da UI** via subscribe do renderer (disparado automaticamente pelo `setState`)
   - Fecha modal
   - Atualiza pastas listadas na corpo aplicação com as pastas restantes
   - Toast "Pasta removida com sucesso"

**Fluxo de atualização:**
- `engine.js` → `stateManager.setState()` → `notifyListeners()` → `renderer.render()` → UI atualizada

> Integração backend (stub): `engine.js` também chama `api.deleteFolder(...)` para logar a ação.

Acceptance:

- A2-1: ícone de deletar visível no lado direito de cada pasta (extremo direito)
- A2-2: dialog exibe ícone e nome da pasta no topo
- A2-3: nome incorreto não deleta, mostra toast de erro
- A2-4: nome correto deleta pasta e todos os prompts dentro dela
- A2-5: toast de sucesso após exclusão
- A2-6: UI atualizada automaticamente após exclusão (pasta removida da lista)

---

### Feature B: Ativar Premium

1. Clique `#btnLicenseKey`
2. Abre `#licenseDialog`
3. Usuário insere key
4. Confirma
5. `engine.js` chama `LicenseService.validateKey(key)` via `service.js`
6. Se válida:
   - atualiza `states.js`: `plan='premium'`
   - define `licenseExpiry = now + 30 dias` (em memória)
   - fecha modal
   - toast "Premium ativado até [data]"
   - atualiza UI: badge, contador, recursos premium
7. Se inválida:
   - mantém modal
   - erro abaixo do input
   - toast "Chave inválida"

> Integração backend (stub): `engine.js` também chama `api.activateLicenseKey(...)` para logar a ação.

Acceptance:

- B1: premium ativado e UI atualiza.
- B2: inválida não altera plano.
- B3: falha técnica não altera plano e mostra erro.

---

### Feature C: Criar Prompt (Free/Premium + Limite)

1. Clique `#btnCreatePrompt`
2. `engine.js` verifica `states.js`:
   - se Free e total >= 5:
     - bloqueia modal
     - toast limite
     - abre `SALES_LANDING_PAGE_URL` via `chrome.tabs.create`
     - encerra
3. Se permitido:
   - abre `#promptDialog`
4. Usuário preenche pasta, nome, conteúdo
   - O dialog exibe texto de ajuda abaixo do campo de conteúdo incentivando o uso de variáveis no formato `[nome]`
5. Confirma
6. Valida obrigatórios
7. `PromptService.createPrompt(payload)` (helpers)
8. Sucesso:
   - atualiza `states.js`
   - fecha modal
   - toast sucesso
   - atualiza contador e lista
9. Erro:
   - mantém modal
   - mensagem + toast erro

> Integração backend (stub): `engine.js` também chama `api.createPrompt(...)` para logar a ação.

Acceptance:

- C1: cria dentro do limite.
- C2: bloqueia no 6º (Free).
- C3: Premium ilimitado.
- C4: validação de campos.
- C5: texto de ajuda sobre variáveis exibido no dialog.

---

### Feature D: Editar Prompt

- Abre modal `#promptEditDialog` com dados preenchidos
- O dialog exibe texto de ajuda abaixo do campo de conteúdo incentivando o uso de variáveis no formato `[nome]`
- Salva atualizando `states.js`
- Toast sucesso/erro
- Atualiza item na lista sem recarregar tudo

> Integração backend (stub): `engine.js` também chama `api.updatePrompt(...)` para logar a ação.

---

### Feature E: Excluir Prompt

- Confirmação
- Remove do `states.js` (prompt e referência em folder->prompts)
- Toast sucesso/erro
- Atualiza contador e lista

> Integração backend (stub): `engine.js` também chama `api.deletePrompt(...)` para logar a ação.


---

### Feature F: Copiar Prompt para Clipboard

- **Disponível para Free e Premium**
- Copia conteúdo do prompt para clipboard (`navigator.clipboard.writeText`)
- Toast sucesso/erro

---

### Feature G: Exportar Pasta (Premium)

- Free: bloqueia + toast premium + abre landing page
- Premium:
  - gera JSON da pasta + prompts
  - copia para clipboard **ou** baixa arquivo JSON

---

### Feature H: Importar Pasta (Premium)

- Free: bloqueia + toast premium + abre landing page
- Premium:
  - abre `#importDialog`
  - aceita textarea JSON ou file input
  - valida schema e campos
  - conflitos:
    - IDs duplicados: gerar novos IDs
    - nomes duplicados: sufixo `(1)`, `(2)`...
  - atualiza `states.js`
  - fecha modal + toast sucesso / mantém modal + toast erro

---

## 6) Modelo de Dados (Em Memória — via `states.js`)

### 6.1 Estrutura do State (Sugestão)

```javascript
{
  user: {
    id: string,
    plan: 'free' | 'premium',
    licenseKey?: string,
    licenseExpiry?: number,
    createdAt: number,
    updatedAt: number
  },
  ui: {
    loading: boolean,
    error: null | { message: string },
    dialogs: {
      folderDialogOpen: boolean,
      promptDialogOpen: boolean,
      promptEditDialogOpen: boolean,
      confirmDeletePromptDialogOpen: boolean,
      licenseDialogOpen: boolean,
      importDialogOpen: boolean
    },
    expandedFolders: { [folderId]: boolean }
  },
  data: {
    folders: { [folderId]: Folder },
    prompts: { [promptId]: Prompt },
    folderPrompts: { [folderId]: string[] }
  }
}
```

### 6.2 Tipos

#### Folder

```javascript
{
  id: string,
  name: string,
  createdAt: number,
  updatedAt: number
}
```

#### Prompt

```javascript
{
  id: string,
  folderId: string,
  nome: string,
  conteudo: string,
  createdAt: number,
  updatedAt: number
}
```

> Nota: IDs como `string` (ex: `folder-1`, `prompt-1`) para consistência com o seed.

### 6.3 Seed Inicial (`data/seed.json`)

**Requisitos de Encoding**:
- O arquivo deve estar em **UTF-8 sem BOM** (Byte Order Mark)
- Limpeza de caracteres invisíveis**: 
   - Remover BOM (`\uFEFF`)
   - Remover zero-width characters (`\u200B-\u200D\u2060`)
   - Aplicar `.trim()`
- Sem caracteres invisíveis no início do arquivo
- Formato JSON válido (pode ser validado com `JSON.parse()`)

**Nota**: O código de inicialização trata automaticamente problemas de encoding, mas é recomendado manter o arquivo limpo para evitar problemas.

```json
{
  "folders": [
    { "id": "folder-1", "name": "Marketing", "createdAt": 1704067200000, "updatedAt": 1704067200000 },
    { "id": "folder-2", "name": "Desenvolvimento", "createdAt": 1704153600000, "updatedAt": 1704153600000 },
    { "id": "folder-3", "name": "Suporte", "createdAt": 1704240000000, "updatedAt": 1704240000000 }
  ],
  "prompts": [
    {
      "id": "prompt-1",
      "folderId": "folder-1",
      "nome": "Post para Redes Sociais",
      "conteudo": "Crie um post engajador para [plataforma] sobre [tema]. Inclua uma chamada para ação clara e use uma linguagem [tom].",
      "createdAt": 1704067200000,
      "updatedAt": 1704067200000
    },
    {
      "id": "prompt-2",
      "folderId": "folder-1",
      "nome": "Email Marketing",
      "conteudo": "Escreva um email de marketing para promover [produto/serviço]. O email deve ser persuasivo, mas não agressivo, e destacar os principais benefícios.",
      "createdAt": 1704070800000,
      "updatedAt": 1704070800000
    },
    {
      "id": "prompt-3",
      "folderId": "folder-2",
      "nome": "Revisão de Código",
      "conteudo": "Revise o seguinte código [código] e forneça feedback sobre: performance, segurança, legibilidade e boas práticas.",
      "createdAt": 1704153600000,
      "updatedAt": 1704153600000
    },
    {
      "id": "prompt-4",
      "folderId": "folder-2",
      "nome": "Documentação de API",
      "conteudo": "Crie documentação completa para a API [nome]. Inclua exemplos de requisições, respostas e casos de uso.",
      "createdAt": 1704157200000,
      "updatedAt": 1704157200000
    },
    {
      "id": "prompt-5",
      "folderId": "folder-3",
      "nome": "Resposta de Suporte",
      "conteudo": "Crie uma resposta profissional e empática para o seguinte problema do cliente: [descrição do problema]. A resposta deve ser clara e oferecer uma solução.",
      "createdAt": 1704240000000,
      "updatedAt": 1704240000000
    }
  ]
}
```

### 6.4 Regras de Consistência

- `folderPrompts[folderId]` deve conter apenas IDs existentes em `prompts`.
- Ao remover prompt:
  - remover `prompts[promptId]`
  - remover `promptId` de `folderPrompts[folderId]`
- Render ordena prompts por `nome`.
- Geração de IDs (import/crud) deve garantir unicidade no state.

---

## 7) Critérios de Aceite

### 7.1 UI/UX

- CA-001: Header exibe logo e nome "Prompt DRIVE" no lado esquerdo
- CA-002: Header exibe botões "+ pasta", "+ prompt", ícone de chave e contador no lado direito
- CA-003: Footer exibe badge de plano (Free/Premium)
- CA-004: Tela inicial lista todas as pastas
- CA-005: Ao clicar em uma pasta, lista de prompts expande/colapsa
- CA-006: Cada prompt exibe 3 ícones: copiar para o clipboard, editar e excluir (todos disponíveis para Free e Premium)
- CA-007: Empty state exibido quando não há pastas
- CA-008: Empty state exibido quando pasta não tem prompts
- CA-009: Loading exibido durante operações assíncronas
- CA-010: Erro exibido com opção de tentar novamente
- CA-011: Dialog de criar prompt exibe texto de ajuda sobre uso de variáveis
- CA-012: Dialog de editar prompt exibe texto de ajuda sobre uso de variáveis

### 7.2 Funcionalidades Free

- CA-018: Usuário pode criar pastas ilimitadas (Free)
- CA-019: Usuário pode criar até 5 prompts no total (Free)
- CA-020: Ao tentar criar o 6º prompt (Free), ação é bloqueada
- CA-021: Toast exibido ao atingir limite: "Limite do plano Free atingido (5 prompts)"
- CA-022: Link `SALES_LANDING_PAGE_URL` aberto ao atingir limite
- CA-023: Usuário pode copiar prompts para o clipboard (Free e Premium)
- CA-024: Usuário pode editar prompts (Free)
- CA-025: Usuário pode excluir prompts (Free)
- CA-026: Usuário pode excluir pastas (Free e Premium)

### 7.3 Funcionalidades Premium

- CA-027: Usuário Premium pode criar prompts ilimitados
- CA-028: Contador exibe "X / ∞" para Premium
- CA-029: Botão/ícone exportar pasta visível apenas Premium
- CA-030: Exportar pasta gera JSON válido
- CA-031: Botão/ícone importar pasta visível apenas Premium
- CA-032: Importar pasta aceita JSON válido
- CA-033: Importar pasta trata IDs duplicados (gera novos IDs)
- CA-034: Importar pasta trata nomes duplicados (adiciona sufixo)

### 7.5 Ativação Premium

- CA-036: Modal de license key abre ao clicar no ícone de chave
- CA-037: Chave válida ativa Premium por 30 dias (em memória)
- CA-038: Toast exibe data de expiração ao ativar Premium
- CA-039: Badge de plano atualizado para "Premium"
- CA-040: Chave inválida exibe toast de erro

### 7.6 Persistência

- [REMOVIDO] Critérios de persistência após reload.
  - [ASSUMPTION] A aplicação reinicia do seed a cada reload/reabertura.

---

## 8) Definições Técnicas Adicionais

### 8.1 `manifest.json` (Chrome Extension)

```json
{
  "manifest_version": 3,
  "name": "Prompt DRIVE",
  "version": "1.0.0",
  "description": "Gerenciador de prompts para Chrome",
  "permissions": ["sidePanel","activeTab","scripting", "tabs"],
  "host_permissions": ["https://www.sample.com/*"],
  "side_panel": { "default_path": "index.html" },
  "action": { "default_title": "Abrir Prompt DRIVE" }
}
```

### 8.2 Constantes Principais (`constants.js`)

```javascript
const GOD_KEY_TO_PREMIUM_ACTIVATE = 'Kjajhist#@123'
const FREE_MAX_PROMPTS = 5;
const PREMIUM_LICENSE_DURATION_DAYS = 30;

const SALES_LANDING_PAGE_URL = 'https://www.sample.com';

const DOM_IDS = {
  btnCreateFolder: '#btnCreateFolder',
  btnCreatePrompt: '#btnCreatePrompt',
  btnLicenseKey: '#btnLicenseKey',
  btnImportFolder: '#btnImportFolder',
  promptCounter: '#promptCounter',
  userPlanBadge: '#userPlanBadge',
  folderDialog: '#folderDialog',
  promptDialog: '#promptDialog',
  promptEditDialog: '#promptEditDialog',
  confirmDeletePromptDialog: '#confirmDeletePromptDialog',
  deleteFolderDialog: '#deleteFolderDialog',
  editFolderDialog: '#editFolderDialog',
  licenseDialog: '#licenseDialog',
  importDialog: '#importDialog',
  foldersContainer: '#foldersContainer',
  mainContent: '#mainContent'
};

const TOAST_MESSAGES = {
  folderCreated: 'Pasta criada com sucesso',
  folderUpdated: 'Pasta atualizada com sucesso',
  folderError: 'Erro ao criar pasta',
  promptCreated: 'Prompt criado com sucesso',
  promptUpdated: 'Prompt atualizado com sucesso',
  promptDeleted: 'Prompt removido com sucesso',
  promptError: 'Erro ao processar prompt',
  folderDeleted: 'Pasta removida com sucesso',
  folderDeleteError: 'Erro ao remover pasta',
  folderNameMismatch: 'O nome digitado não confere com o nome da pasta',
  limitReached: 'Limite do plano Free atingido (5 prompts)',
  premiumActivated: 'Premium ativado até',
  invalidKey: 'Chave inválida',
  premiumFeature: 'Recurso Premium - Ative o Premium para usar esta funcionalidade',
  shareSuccess: 'Prompt copiado para a área de transferência!',
  shareError: 'Falha ao compartilhar prompt',
  exportSuccess: 'Pasta exportada com sucesso!',
  exportError: 'Erro ao exportar pasta',
  importSuccess: 'Importação concluída com sucesso',
  importError: 'Erro ao importar pasta - verifique o formato do JSON'
};
```

### 8.3 Tratamento de Encoding no Carregamento do Seed

**Problema**: Arquivos JSON podem conter BOM (Byte Order Mark) ou caracteres invisíveis que causam erro `SyntaxError: Unexpected token` ao fazer parse.

**Solução implementada no `engine.js`**:

1. **Múltiplos caminhos**: Tentar diferentes variações de caminho relativo/absoluto
2. **Leitura como texto**: Usar `response.text()` ao invés de `response.json()` diretamente
3. **Limpeza de caracteres invisíveis**: 
   - Remover BOM (`\uFEFF`)
   - Remover zero-width characters (`\u200B-\u200D\u2060`)
   - Aplicar `.trim()`
4. **Fallback inline**: Se todos os caminhos falharem, usar dados hardcoded
5. **Logs detalhados**: Em caso de erro, logar primeiros 200 caracteres e código do primeiro caractere para debug

**Código de exemplo**:
```javascript
const text = await response.text();
const cleanText = text.trim().replace(/^[\uFEFF\u200B-\u200D\u2060]/g, '');
const seedData = JSON.parse(cleanText);
```

**Recomendação**: Manter `data/seed.json` em UTF-8 sem BOM para evitar problemas.

### 8.4 Contrato do api.js (assinaturas para todas as ações do projeto)

> Objetivo: padronizar desde já as chamadas que futuramente virarão requests HTTP/GraphQL/etc.
> Por enquanto: cada método apenas faz console.log() (sem persistência, sem fetch).

### 8.4.1 Convenções de payload

- Sempre incluir userId (vem de state.user.id).
- IDs e nomes devem ser enviados como string.
- Quando existir “before/after”, enviar ambos para auditoria futura.

### 8.4.2 Assinaturas obrigatórias
Pasta
- `createFolder(payload)`
  - payload:
    - userId: string
    - folderId: string
    - folderName: string

- `updateFolder(payload)`
  - payload:
    - userId: string
    - folderId: string
    - folderName: string

- `deleteFolder(payload)`
  - payload:
    - userId: string
    - folderId: string

Prompt
- `createPrompt(payload)`
  - payload:
    - userId: string
    - prompt: { id: string, folderId: string, nome: string, conteudo: string }

- `updatePrompt(payload)`
  - payload:
    - userId: string
    - promptId: string
    - patch: { folderId?: string, nome?: string, conteudo?: string }

- `deletePrompt(payload)`
  - payload:
    - userId: string
    - promptId: string

Licença / Premium
- `activateLicenseKey(payload)`
  - payload:
    - userId: string
    - licenseKey: string

---

## 9) Fluxos de Usuário Principais

### 9.1 Criação de Prompt (Free — dentro do limite)

1. "+ prompt"
2. Modal abre
3. Preenche e confirma
4. Atualiza state
5. Contador "X / 5"
6. Lista atualiza

### 9.2 Upgrade para Premium

1. Ícone de chave
2. Modal abre
3. Chave válida
4. Atualiza state para Premium + expiry em memória
5. Contador "X / ∞"
6. Recursos premium habilitados

---

## 10) Throws (Notas de Implementação)

- A UI deve renderizar a partir do `states.js` (subscribe + render).
- Toda operação de CRUD/import/export deve:
  1. validar no `engine.js`
  2. atualizar o `states.js` via `setState()`
  3. **refresh automático da UI** via subscribe do renderer (disparado automaticamente pelo `setState`)
- Sem persistência: todo dado é volátil (memória) e reinicia do seed.
Integração backend (stub):
- engine.js chama api.js em cada ação relevante para logar payloads.
- Quando formos implementar backend, somente api.js muda (endpoints/auth), sem “vazar” fetch para outros módulos.

### 10.1 Sistema de Refresh Automático da UI

**Mecanismo:**
- O `renderer.js` se inscreve no `stateManager` via `subscribe()` na inicialização
- Toda chamada a `stateManager.setState()` dispara automaticamente `notifyListeners()`
- O listener do renderer chama `render(state)`, atualizando toda a UI

**Fluxo padrão:**
```
engine.js → stateManager.setState() → notifyListeners() → renderer.render() → UI atualizada
```

**Garantias:**
- Editar pasta: atualiza state → refresh automático da UI
- Deletar pasta: atualiza state → refresh automático da UI
- Qualquer operação CRUD: atualiza state → refresh automático da UI

Não é necessário chamar manualmente métodos de renderização após atualizar o state.
