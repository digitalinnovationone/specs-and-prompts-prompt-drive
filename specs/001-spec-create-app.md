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