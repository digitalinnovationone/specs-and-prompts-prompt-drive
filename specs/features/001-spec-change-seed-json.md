# Contexto
Vamos alterar o formato do arquivo do `data/seed.json` para o formato abaixo de json esperado, além disso, o método responsável por renderizar os itens na tela, deve conhecer o formato abaixo, após isso, precisamos realizar mudanças no arquivo `state.js` para entender o formato abaixo:

novo formato de dados:
```json
{
  "user": {
    "id": "c1f9e6c2-3c1d-4e1a-b0b2-8b7c0f5a9d21",
    "name": "João Silva"
  },
  "profile": {
    "stripe_customer_id": "cus_Q8fKJd9s73Lx2A",
    "plan": "premium"
  },
  "subscription": {
    "id": "ab91f6a2-42e1-4b7f-9b55-9e8c7f0d1123",
    "status": "active",
    "period_start": "2026-01-01T00:00:00.000Z",
    "period_end": "2026-02-01T00:00:00.000Z",
    "cancel_at_period_end": false
  },
  "folders": [
    {
      "id": "8e0b7f92-0c6a-4d8c-b6c1-1b7a0c3d2f10",
      "name": "Trabalho",
      "created_at": "2026-01-10T14:12:43.123Z",
      "updated_at": "2026-01-10T14:12:43.123Z",
      "prompts": [
        {
          "id": "3a4f2d1c-9b2a-4d77-9a91-0f1c5a4e7d11",
          "name": "Resumo de reunião",
          "content": "Crie um resumo objetivo da reunião a partir das anotações abaixo...",
          "created_at": "2026-01-10T14:20:01.000Z",
          "updated_at": "2026-01-10T14:20:01.000Z"
        }
      ]
    }
  ]
}
```