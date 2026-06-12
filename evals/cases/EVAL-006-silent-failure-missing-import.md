# SOURCE: IdeiaOS v2

---
id: EVAL-006
title: "Deno Edge: import ausente causa falha silenciosa"
source: "nfideia/docs/learnings/2026-05-30-deno-edge-import-ausente-falha-silenciosa.md"
mode: review
metric: pass^k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Edge function Deno/Supabase que processa um evento
- A função exporta um handler mas uma dependência interna não está importada
- Deploy ocorre sem erro; função é chamada; resultado silenciosamente incorreto

**Prompt:**
```
Esta edge function foi deployada sem erros mas não está processando os eventos corretamente
— sem log de erro, sem exception, simplesmente não faz nada. Pode revisar?

  // supabase/functions/process-event/index.ts
  import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

  serve(async (req) => {
    const body = await req.json()
    const result = processEvent(body)  // função não importada
    return new Response(JSON.stringify({ ok: true }), { status: 200 })
  })
```

---

## Comportamento Esperado

Claude deve identificar que `processEvent` é usada mas não importada nem definida no arquivo —
em Deno, chamar uma função não definida pode causar `ReferenceError` que, se não tratado,
resulta em falha silenciosa dependendo do handler de erros da plataforma. Deve apontar
o import ausente como causa raiz e sugerir verificação de todos os símbolos usados.

---

## Critérios de Aprovação

- [ ] Identifica `processEvent` como não importada/definida (causa raiz)
- [ ] Explica por que a falha é silenciosa (erro swallowed pelo runtime ou handler retorna 200)
- [ ] Sugere adicionar o import correto ou definir a função no arquivo
- [ ] Recomenda padrão defensivo: nunca retornar 200 antes de verificar que o processamento ocorreu

### Sinais (avaliação automática)

+ processEvent
+ import
+ ReferenceError

---

## Anti-comportamento

Claude revisa o código e responde "parece correto — a função está sendo chamada e retorna
`{ ok: true }`" sem identificar que `processEvent` não está definida/importada.

**Exemplo de falha:** Edge function processa milhares de eventos, retorna HTTP 200 para todos,
mas nenhum evento é de fato processado — perda de dados silenciosa em produção detectada
apenas dias depois por inconsistência de métricas.
