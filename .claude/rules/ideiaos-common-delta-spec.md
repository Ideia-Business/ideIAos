# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6

# Rule: delta-spec — Fronteira /spec x GSD

Esta rule define QUANDO usar a skill `/spec` (delta-spec brownfield), QUANDO usar o GSD, e QUANDO usar os dois juntos. Ela complementa a skill `source/skills/spec/SKILL.md` com a fronteira de complementaridade formal.

Requisito fechado: **R6-13** (capability delta-spec + piloto brownfield).

---

## Fronteira /spec x GSD

| Eixo | /spec (delta-spec) | GSD (.planning/) |
|------|--------------------|-----------------|
| **Pergunta central** | Qual o comportamento CONTRATADO do produto, e como ele muda? | Como executo ESTA FASE TECNICA agora? |
| **Horizonte** | Contrato vivo de longo prazo (`specs/`) | Fase pontual (`.planning/PLAN.md` — arquivada no milestone) |
| **Unidade** | capability + requirement (SHALL/DEVE) + scenario (QUANDO/ENTÃO) | phase + plan + task |
| **Operacao** | propose → spec/delta → tasks → merge+archive | plan-phase → execute-phase → SUMMARY |
| **Output** | `specs/<capability>/spec.md` (source-of-truth) + `specs/_archive/` (historico datado) | `.planning/phases/*/SUMMARY.md` (registro de execucao) |
| **Quando usar** | Para registrar/mudar COMPORTAMENTO DURAVEL do produto que precisa de contrato auditavel | Para planejar e executar TRABALHO TECNICO (build, fix, refactor, infra) |

---

## Regra de decisao: /spec OU GSD OU os dois?

### Use SOMENTE /spec quando
- Voce quer DOCUMENTAR um comportamento que o produto ja tem (spec inicial)
- Voce quer PROPOR uma mudanca de comportamento (novo requisito, modificacao, remocao)
- Voce quer AUDITAR o historico de mudancas de comportamento de uma capability
- Nenhum codigo precisa mudar — apenas o contrato precisa ser registrado

### Use SOMENTE GSD quando
- A fase tecnica esta clara e o contrato de comportamento nao precisa de update
- E um fix, refactor, infra change, ou otimizacao sem impacto no contrato observavel
- A granularidade e de task/subtask (nao de requirement/scenario)

### Use OS DOIS (padrao para features novas em produto brownfield)
```
/spec → propose + spec/delta + tasks.md
  ↓
GSD /gsd-plan-phase → consome tasks.md como input do plano
  ↓
GSD /gsd-execute-phase → implementa
  ↓
/spec merge+archive → consolida o contrato com o que foi implementado
```
O `tasks.md` gerado pelo `/spec` e o elo entre as duas camadas: o contrato diz O QUE; o GSD decide COMO e QUANDO.

---

## Estrutura de diretórios specs/ no produto-alvo

```
specs/
  <capability>/
    spec.md           # source-of-truth: requisitos (SHALL/DEVE) + cenarios (QUANDO/ENTÃO)
  _changes/
    <slug>/           # mudanca ativa em andamento
      proposta.md     # Por que / O que muda / Capabilities afetadas / Impacto
      delta/
        <capability>.md   # ADICIONADO / MODIFICADO / REMOVIDO / RENOMEADO
      tasks.md        # checklist consumivel pelo GSD
  _archive/
    AAAA-MM-DD-<slug>/    # mudanca aplicada, datada, imutavel
```

**Onde vive:** A skill e suas libs moram no IdeiaOS (`source/skills/spec/`). A estrutura `specs/` e criada DENTRO de cada produto-alvo (nfideia, ideiapartner, cfoai etc.).

---

## Regra dos 4 hashtags em cenarios

Todo cenario usa exatamente `####` (4 hashtags). Esta e uma regra CRITICA do parser de merge.

```markdown
### Requisito: Nome do Requisito    <- 3 hashtags: header de requisito
O sistema DEVE ...

#### Cenário: Nome do cenario       <- 4 hashtags: CORRETO
- **QUANDO** condicao
- **ENTÃO** resultado
```

Cenarios com `###` (3 hashtags) sao rejeitados pelo `spec-validate.sh` antes do merge.

---

## SHALL vs DEVE

- `SHALL` e `DEVE` sao equivalentes — ambos expressam obrigatoriedade no contrato.
- Preferir `DEVE` em documentacao PT-BR; `SHALL` e aceito em contextos tecnicos/RFC.
- Evitar `PODE` / `DEVERIA` / `PODE` para nao criar ambiguidade no contrato.

---

## Fronteira /spec --analyze x gsd-code-review x GSD (v11 W4)

Três gates, três alvos distintos — NÃO se sobrepõem:

| Eixo | `spec-validate.sh` | `spec-analyze.sh` (`/spec --analyze`) | `gsd-code-review` |
|------|--------------------|---------------------------------------|-------------------|
| **Alvo** | o DELTA pré-merge (`_changes/<slug>/delta/`) | a SPEC VIVA pós-merge (`specs/<cap>/spec.md`) | o DIFF de código de uma fase |
| **Pergunta** | o delta está bem-formado p/ aplicar? | o CONTRATO está internamente consistente e rastreável? (sem req sem cenário, sem cenário em nível errado, sem header duplicado, sem token de delta vazado, sem path-morto citado) | o CÓDIGO mudado tem bug/vuln/cheiro? |
| **Gate** | HARD (exit 1) pré-merge | HARD no núcleo determinístico (A1-A4); A5 + LLM = ADVISORY | review com achados classificados por severidade |

**Regra de não-sobreposição (3 níveis):**
`spec-validate` gateia DELTAS pré-merge · `spec-analyze` gateia a SOURCE-OF-TRUTH pós-merge · `gsd-code-review` gateia o DIFF de implementação.

**Frase-âncora:** `--analyze` NUNCA lê código para julgar QUALIDADE de código — só confirma que os paths que o CONTRATO cita existem (A5, e mesmo isso é ADVISORY). Avaliar o que há DENTRO do código é trabalho do `gsd-code-review`, que por sua vez NUNCA edita nem audita `specs/`.

**`--converge` como ponte append-only:** quando o `--analyze` acha drift, `/spec --converge` produz um delta-candidato em `specs/_changes/_converge-<timestamp>/` que reentra no fluxo normal `/spec` (propose → validate → merge), fechando o loop spec↔código **sem mutar a fonte** (garantia sha256 before/after; cf. guard-rails `antifragile-gates` = exit binário, e "LLM/heurística = ADVISORY").

---

## Complementaridade com o GSD — nao substituicao

O `/spec` NAO e um substituto do GSD. Sao camadas distintas com preocupacoes distintas:

- **GSD** planeja e executa fases tecnicas. Seu output e codigo, commits, SUMMARY.md.
- **/spec** mantém o contrato de comportamento. Seu output e specs vivas e archive datado.

Analogia: `/spec` e o "contrato" (o que o produto DEVE fazer); GSD e o "cronograma" (como e quando fazemos).

Um produto brownfield bem gerenciado usa os dois: o contrato de comportamento (/spec) alimenta o planejamento tecnico (GSD), e o resultado da execucao (GSD) pode ser consolidado de volta no contrato (/spec).
