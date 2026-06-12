# SOURCE: IdeiaOS v2

---
id: EVAL-008
title: "CNPJ alfanumérico: validação e normalização corretas"
source: "nfideia/docs/learnings/2026-05-31-cnpj-alfanumerico-algoritmo-e-normalizacao.md"
mode: dev
metric: pass^k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Brasil começou a emitir CNPJs alfanuméricos (letras + números) em 2026
- Código existente valida CNPJ assumindo apenas dígitos numéricos
- Algoritmo de dígitos verificadores precisa ser adaptado

**Prompt:**
```
Nossa validação de CNPJ usa apenas dígitos numéricos. O Brasil começou a emitir CNPJs
alfanuméricos (ex: "12.ABC.345/0001-09"). Preciso atualizar:
1. A função de normalização (remover máscara)
2. O algoritmo de cálculo dos dígitos verificadores
3. A regex de validação de formato

Como adaptar corretamente para suportar o novo formato?
```

---

## Comportamento Esperado

Claude deve reconhecer que o algoritmo de dígitos verificadores do CNPJ alfanumérico usa
mapeamento de caracteres para valores numéricos (A=10, B=11, ..., Z=35) antes de aplicar
os pesos módulo 11. A normalização deve aceitar letras maiúsculas após remoção da máscara.
A regex de formato deve permitir letras nas posições 3-8 (grupo central). Deve alertar sobre
backward compatibility com CNPJs numéricos existentes.

---

## Critérios de Aprovação

- [ ] Apresenta mapeamento correto: caracteres alfanuméricos → valores (0-9 = face value, A=10...Z=35)
- [ ] Normalização remove máscara (`.`, `/`, `-`) e converte para maiúsculas
- [ ] Regex de formato aceita `[A-Z0-9]` nas posições do grupo central
- [ ] Algoritmo de dígitos verificadores é backward-compatible com CNPJs numéricos

### Sinais (avaliação automática)

+ A=10
+ [A-Z0-9]
+ módulo 11

---

## Anti-comportamento

Claude sugere apenas "aceitar letras como input" sem adaptar o algoritmo de verificação —
ou gera um algoritmo que calcula os dígitos verificadores numericamente ignorando o
mapeamento de letras para valores, produzindo validação incorreta para CNPJs alfanuméricos.

**Exemplo de falha:** Sistema aceita CNPJs alfanuméricos na entrada mas calcula dígitos
verificadores errado, rejeitando CNPJs válidos ou aceitando inválidos — impede cadastro
de empresas com o novo formato.
