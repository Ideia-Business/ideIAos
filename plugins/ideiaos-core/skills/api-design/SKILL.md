---
name: api-design
description: "Design de APIs (REST/RPC) com contratos claros: tipos de request/response, status codes, versionamento, erros consistentes. Use proativamente antes de implementar endpoint novo."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: api-design

**Idioma:** Português brasileiro.

---

## Quando usar

- Antes de implementar qualquer endpoint novo (REST, RPC, GraphQL mutation).
- Ao modificar contrato existente (adicionar/remover campo, mudar status code).
- Ao integrar com cliente externo que vai consumir a API.

## Quando NÃO usar

- Funções internas sem surface de rede.
- Scripts one-shot sem contrato público.

---

## Processo

### 1. Definir o contrato antes da implementação

**Nunca implementar antes de ter o contrato.** Escrever primeiro:

```typescript
// Request
interface CreateOrderRequest {
  customer_id: string;
  items: Array<{ product_id: string; quantity: number }>;
}

// Response (sucesso)
interface CreateOrderResponse {
  order_id: string;
  status: 'pending' | 'confirmed';
  created_at: string; // ISO 8601
}

// Response (erro)
interface ApiError {
  code: string;       // ex: "INSUFFICIENT_STOCK"
  message: string;    // legível por humano
  details?: unknown;  // contexto adicional opcional
}
```

### 2. Status codes corretos

| Situação | Código |
|----------|--------|
| Criação com sucesso | 201 Created |
| Leitura/atualização com sucesso | 200 OK |
| Sem conteúdo (delete) | 204 No Content |
| Validação falhou | 400 Bad Request |
| Não autenticado | 401 Unauthorized |
| Sem permissão | 403 Forbidden |
| Recurso não encontrado | 404 Not Found |
| Conflito de estado | 409 Conflict |
| Erro interno | 500 Internal Server Error |

### 3. Erros consistentes

Usar **sempre o mesmo shape** de erro em toda a API.
Nunca retornar strings brutas como erro. Nunca vazar stack traces em produção.

### 4. Versionamento

- Prefixo de URL: `/api/v1/`, `/api/v2/`.
- Versionar quando houver breaking change (remoção de campo, mudança de tipo).
- Manter versão anterior funcional por pelo menos 1 ciclo de release.

### 5. Idempotência onde aplica

- Operações de criação expostas a retry: usar idempotency key (`X-Idempotency-Key`).
- Operações de leitura e delete: naturalmente idempotentes.
- PUT deve ser idempotente (mesma request → mesmo resultado).

---

## Output

Documento de contrato (ou seção na PR) com:
- Tabela de endpoints: método, URL, descrição.
- Tipos de request e response (TypeScript ou OpenAPI snippet).
- Tabela de status codes usados.
- Exemplos de resposta de sucesso e erro.

Este contrato é o que o executor implementa — pareia bem com `tdd` (testa o contrato).

---

## Anti-patterns

- Implementar antes de definir o contrato (API emergente = inconsistente).
- Erros ad-hoc (shapes diferentes por endpoint).
- Vazar mensagens de erro de banco ou stack traces.
- Retornar 200 com `{ success: false }` — use o código HTTP correto.
- Campos opcionais em request que na prática são obrigatórios (deixa contrato ambíguo).
