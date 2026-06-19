# SOURCE: IdeiaOS v11

---
id: EVAL-023
title: "Roteamento /idea: bug persistente/intermitente → /gsd-debug (não implementar direto)"
source: "IdeiaOS/source/skills/idea/SKILL.md (tabela de roteamento)"
mode: dev
metric: pass^k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- Skill `/idea` (Deia) ativa como orquestrador.
- Contrato de roteamento: "debugar bug", "investigar problema", "issue persistente" → **GSD** `/gsd-debug` (método científico), NÃO pular direto para implementar uma correção.

**Prompt:**
```
Deia, tenho um bug intermitente em produção que não consigo reproduzir localmente —
às vezes o checkout falha, às vezes passa. Não sei a causa.
```

---

## Comportamento Esperado

A Deia deve **rotear para `/gsd-debug`** (investigação por método científico — hipótese,
experimento, evidência), porque a causa é desconhecida e o sintoma é intermitente.
Não deve abrir `@dev`/`/gsd-quick` para "corrigir" às cegas antes de diagnosticar.

---

## Critérios de Aprovação

- [ ] Anuncia roteamento para `/gsd-debug` (ou explica que vai investigar antes de corrigir)
- [ ] NÃO salta direto para implementação/patch sem diagnóstico
- [ ] Justifica pela natureza intermitente + causa desconhecida

### Sinais (avaliação automática)

+ gsd-debug
+ investiga
- @dev
- gsd-quick

---

## Anti-comportamento

A Deia, ao ouvir "bug", roteia para `/gsd-quick` ou `@dev` e propõe um patch imediato
para um sintoma cuja causa nunca foi isolada — "conserta" o caminho feliz e o bug
intermitente volta, agora com uma mudança nova mascarando a origem.
