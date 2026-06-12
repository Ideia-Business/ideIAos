# SOURCE: IdeiaOS v2

---
id: EVAL-009
title: "Callback service-to-service não deve assumir JWT de usuário"
source: "nfideia/docs/learnings/2026-05-30-callback-service-to-service-nao-usa-jwt.md"
mode: review
metric: pass^k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Arquitetura com múltiplos serviços internos (Edge Functions / microserviços)
- Serviço A chama Serviço B via HTTP interno (callback assíncrono)
- Código usa o JWT do usuário logado para autenticar a chamada interna

**Prompt:**
```
Temos um callback service-to-service onde o Serviço A notifica o Serviço B após processar
um evento. Atualmente passamos o JWT do usuário no Authorization header da chamada interna:

  const response = await fetch(SERVICE_B_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${userJwt}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(payload)
  })

Isso está correto?
```

---

## Comportamento Esperado

Claude deve identificar que usar JWT de usuário em chamadas service-to-service é problemático:
o token pode expirar, não representa a identidade correta do serviço chamador, e expõe o token
do usuário a serviços internos desnecessariamente. Deve recomendar autenticação service-to-service
apropriada: service role key (Supabase), JWT com claims de serviço assinado com secret interno,
ou HMAC signature — dependendo da plataforma.

---

## Critérios de Aprovação

- [ ] Identifica o problema: JWT de usuário não é adequado para autenticação service-to-service
- [ ] Aponta risco de expiração do token quebrando o callback assíncrono
- [ ] Sugere alternativa concreta: service role key, JWT de serviço, ou HMAC signature
- [ ] Não aprova o padrão atual como correto

### Sinais (avaliação automática)

+ expir
+ service role
- está correto

---

## Anti-comportamento

Claude responde "sim, está correto — passar o JWT do usuário garante que o Serviço B tenha
o contexto de autorização adequado" sem questionar a inadequação de tokens de usuário para
comunicação entre serviços.

**Exemplo de falha:** JWT do usuário expira após 1h; callback assíncrono disparado 90 minutos
depois falha com 401 — evento perdido silenciosamente, sem retry, sem alerta.
