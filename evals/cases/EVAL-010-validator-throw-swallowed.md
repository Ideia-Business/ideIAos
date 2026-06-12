# SOURCE: IdeiaOS v2

---
id: EVAL-010
title: "Validator throw engolido por handler de infra + jsonb stale em retry"
source: "nfideia/docs/learnings/2026-05-29-validator-throw-capturado-por-handler-infra-e-jsonb-stale-em-retry.md"
mode: review
metric: pass^k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Função de processamento com validação de payload e handler de infraestrutura global
- Handler de infra captura todos os erros e retorna 200 para o caller (evitar retry storm)
- Em retry: payload jsonb pode estar em estado stale (cacheado da tentativa anterior)

**Prompt:**
```
Temos este padrão em nossa edge function:

  // handler de infra (não modificar)
  serve(async (req) => {
    try {
      await processPayload(req)
      return new Response("ok", { status: 200 })
    } catch (e) {
      console.error(e)
      return new Response("ok", { status: 200 })  // sempre 200 para evitar retry
    }
  })

  async function processPayload(req) {
    const body = await req.json()
    validatePayload(body)  // throws se inválido
    await saveToDb(body)
  }

O validator lança exceção quando o payload é inválido, mas o handler de infra captura e
retorna 200 de qualquer forma. Tem algum problema?
```

---

## Comportamento Esperado

Claude deve identificar dois problemas: (1) o throw do validator é engolido pelo handler de
infra — erros de validação passam sem log adequado e sem distinguir "erro de negócio" vs
"erro de infra"; (2) em retry com jsonb cacheado, `req.json()` pode retornar o mesmo payload
stale, tornando o retry ineficaz. Deve sugerir classificação de erros (negócio vs infra) e
invalidação de cache entre tentativas.

---

## Critérios de Aprovação

- [ ] Identifica que erros de validação são silenciados pelo catch genérico
- [ ] Distingue erro de negócio (deve retornar 4xx, não 200) de erro de infra (200 pode ser ok)
- [ ] Menciona o risco de jsonb stale em retry (payload da 1ª tentativa reusado na 2ª)
- [ ] Propõe separação de responsabilidades: validação lança erro tipado, infra trata por tipo

---

## Anti-comportamento

Claude responde "o padrão está correto — retornar 200 em todos os casos evita retry storm
do caller" sem identificar que erros de validação legítimos ficam invisíveis e que o estado
stale no retry pode perpetuar o problema.

**Exemplo de falha:** Payload inválido chega, validator lança, handler engole e retorna 200;
nenhum alerta disparado; dado nunca é salvo; operador não sabe que o evento foi perdido.
