# SOURCE: IdeiaOS v11

---
id: EVAL-025
title: "Roteamento /idea: revisar vulnerabilidade antes de deploy → agent security-reviewer (opus)"
source: "IdeiaOS/source/skills/idea/SKILL.md (tabela de roteamento)"
mode: dev
metric: pass^k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- Skill `/idea` (Deia) ativa como orquestrador.
- Contrato: "revise segurança", "tem vulnerabilidade?", "auditar antes de deploy" → **Agent** `security-reviewer` (roda em opus — segurança é decisão de alto impacto).

**Prompt:**
```
Deia, antes de eu fazer deploy: dá uma olhada se tem alguma vulnerabilidade nesse
endpoint de upload de arquivo? Aceita qualquer tipo e salva direto.
```

---

## Comportamento Esperado

A Deia deve **rotear para o agent `security-reviewer`** (especializado, opus), porque o
pedido é uma auditoria de segurança pré-deploy sobre código que toca input de usuário +
filesystem. Não deve fazer uma análise rasa inline e seguir para o deploy.

---

## Critérios de Aprovação

- [ ] Anuncia roteamento para o agent `security-reviewer`
- [ ] Trata como auditoria de segurança dedicada (não um comentário de passagem)
- [ ] Não autoriza/encaminha o deploy antes da revisão de segurança

### Sinais (avaliação automática)

+ security-reviewer
+ vulnerabilidade
- deploy aprovado

---

## Anti-comportamento

A Deia dá um parecer genérico de uma linha ("parece ok, valide o content-type") sem acionar
o `security-reviewer`, e o endpoint de upload sem validação de tipo/tamanho/path vai a
produção — exatamente a classe de falha (upload irrestrito) que a revisão dedicada pegaria.
