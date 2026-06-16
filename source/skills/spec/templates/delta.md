# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6

# Delta: <capability> — <slug-da-mudanca>

**Capability alvo:** <nome-slug>
**Change slug:** <slug-da-mudanca>
**Data do delta:** <AAAA-MM-DD>

Tokens canônicos (PT-BR de superfície → interno usado pelo merge):
- ADICIONADO  = ADDED   (novo requisito inserido)
- MODIFICADO  = MODIFIED (bloco completo substituído)
- REMOVIDO    = REMOVED  (requisito eliminado — exige Motivo + Migração)
- RENOMEADO   = RENAMED  (header renomeado, corpo preservado)

Regra crítica: todo cenário usa exatamente `####` (4 hashtags).
Cenários com `###` são rejeitados pelo spec-validate.sh antes do merge.

---

## ADICIONADO Requisitos

### Requisito: <Nome do Novo Requisito>

O sistema DEVE <comportamento novo>. <Contexto ou restrição.>

#### Cenário: <nome do cenário>

- **QUANDO** <condição>
- **ENTÃO** <resultado esperado>

---

## MODIFICADO Requisitos

O bloco abaixo DEVE ser o requisito COMPLETO (não uma diff parcial).
O merge substitui o bloco inteiro pelo conteúdo aqui presente.

### Requisito: <Nome Exato do Requisito Existente>

O sistema DEVE <novo comportamento completo>. <Contexto atualizado.>

#### Cenário: <nome do cenário atualizado>

- **QUANDO** <condição atualizada>
- **ENTÃO** <resultado atualizado>

#### Cenário: <cenário adicional se houver>

- **QUANDO** <condição>
- **ENTÃO** <resultado>

---

## REMOVIDO Requisitos

### Requisito: <Nome Exato do Requisito a Remover>

**Motivo:** <Por que este requisito está sendo removido. Ex: comportamento substituído por outro requisito, feature descontinuada, consolidado em outro lugar.>

**Migração:** <O que deve ser feito para consumidores que dependem deste comportamento. Se não houver migração necessária, escrever "Sem migração necessária".>

---

## RENOMEADO Requisitos

### Requisito:
- **DE:** <Nome Antigo Exato>
- **PARA:** <Nome Novo>

<O corpo do requisito (texto + cenários) é preservado integralmente pelo merge. Inclua aqui apenas se quiser modificar também o conteúdo junto com o rename.>
