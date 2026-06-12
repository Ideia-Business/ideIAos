# SOURCE: IdeiaOS v2

---
id: EVAL-004
title: "React Query: cache vaza entre tenants no signed-out"
source: "nfideia/docs/learnings/2026-05-29-react-query-cache-vazamento-multi-tenant-signed-out.md"
mode: review
metric: pass^k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Aplicação SaaS multi-tenant com React Query
- QueryClient criado uma vez no nível da aplicação (singleton global)
- Usuário A faz login, carrega dados de seu tenant, faz logout
- Usuário B faz login no mesmo browser/sessão

**Prompt:**
```
Nosso QueryClient é criado assim no _app.tsx:
  const queryClient = new QueryClient({ defaultOptions: { ... } })

  export default function App({ Component, pageProps }) {
    return (
      <QueryClientProvider client={queryClient}>
        <Component {...pageProps} />
      </QueryClientProvider>
    )
  }

Temos algum problema de segurança aqui em uma aplicação multi-tenant?
```

---

## Comportamento Esperado

Claude deve identificar que um QueryClient singleton persiste o cache entre sessões de usuário
diferentes — no signed-out/login de novo usuário, os dados do tenant anterior permanecem em
memória e podem ser renderizados para o segundo usuário. Deve recomendar limpar o cache no
logout (`queryClient.clear()`) ou criar um novo QueryClient por sessão/usuário.

---

## Critérios de Aprovação

- [ ] Identifica o risco de vazamento de dados entre tenants pelo cache persistente
- [ ] Explica que QueryClient singleton mantém cache após logout
- [ ] Recomenda `queryClient.clear()` no evento de logout OU criação de novo QueryClient por sessão
- [ ] Classifica como problema de privacidade/segurança, não apenas bug de UX

### Sinais (avaliação automática)

+ queryClient.clear
+ logout
+ cache

---

## Anti-comportamento

Claude revisa o código e conclui que "está correto — QueryClient singleton é o padrão
recomendado pela documentação do React Query" sem mencionar a implicação multi-tenant.

**Exemplo de falha:** Usuário B vê dados financeiros ou de clientes do Usuário A durante
os primeiros milissegundos após login, antes do refetch — vazamento de dados entre tenants
confirmado em produção.
