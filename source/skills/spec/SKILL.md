---
name: spec
description: "Skill delta-spec brownfield do IdeiaOS — mantém contratos de comportamento vivos de produto por capability em specs/<capability>/spec.md. Ative quando o usuário disser: 'spec viva', 'delta de spec', 'contrato de comportamento do produto', 'especificar capability', 'documentar comportamento brownfield', 'mudar comportamento registrado', 'adicionar requisito ao contrato', 'proposta de mudança de spec', 'registrar comportamento de long prazo', ou digitar /spec diretamente. DISTINTO do GSD (que planeja fases técnicas): /spec mantém o CONTRATO de comportamento durável do produto; GSD planeja/executa a IMPLEMENTAÇÃO. Os dois se complementam — um delta /spec pode alimentar tarefas que um ciclo GSD vai executar. Cumpre R6-13. PT-BR."
---

# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6

# Skill: /spec — Delta-Spec Brownfield

**Idioma:** Português brasileiro.

## Como invocar

| Gatilho | Exemplo |
|---------|---------|
| Comando slash | `/spec` |
| Pela Deia | `Deia, quero registrar o contrato de comportamento do login` |
| Linguagem natural | `quero documentar como o módulo de pagamento se comporta` |

---

## O que é — e o que NÃO é

### O que é

Um contrato de comportamento **vivo**, organizado por capability, que registra:
- **Requisitos** (declarações SHALL/DEVE que o produto deve satisfazer)
- **Cenários** (QUANDO → ENTÃO, testáveis)
- **Deltas** (mudanças expressas como ADICIONADO/MODIFICADO/REMOVIDO/RENOMEADO, sem reescrever a spec inteira)
- **Archive datado** (histórico imutável de cada mudança aplicada)

Referência do requisito que esta skill cumpre: **R6-13** (capability delta-spec + piloto brownfield).

### O que NÃO é

| Confusão comum | Camada correta |
|---------------|---------------|
| Plano de fase técnica (o que vou construir agora) | GSD → `/gsd-plan-phase` |
| Execução de tasks de implementação | GSD → `/gsd-execute-phase` |
| Design arquitetural linha-a-linha | `/api-design` ou `@architect` |
| Checklist de tasks de desenvolvimento | Consumidor do `tasks.md` gerado pelo `/spec`; executado via GSD |

**Fronteira de complementaridade:** `/spec` e GSD atuam em camadas distintas. Uma mudança de comportamento começa em `/spec` (contrato → delta → tasks.md) e a execução das tasks vai para GSD. Ver detalhe completo em `source/rules/common/delta-spec.md`.

---

## Estrutura de diretórios criada no produto-alvo

```
specs/
  <capability>/
    spec.md           # source-of-truth: requisitos + cenários (SHALL/DEVE)
  _changes/
    <slug>/           # mudança ativa em andamento
      proposta.md     # Por quê / O que muda / Capabilities afetadas
      delta/
        <capability>.md   # ADICIONADO / MODIFICADO / REMOVIDO / RENOMEADO
      tasks.md        # checklist - [ ] N.M consumível pelo GSD
  _archive/
    AAAA-MM-DD-<slug>/    # mudança aplicada, datada, imutável
```

**Onde vivem os arquivos:**
- A skill (`source/skills/spec/`) e suas libs/templates moram no **IdeiaOS** e são instaladas nos produtos via `scripts/build-adapters.sh` (como as demais skills).
- A estrutura `specs/` é criada **dentro de cada produto-alvo** (nfideia, ideiapartner, cfoai etc.) — é o corpus vivo do produto, não do IdeiaOS.

---

## Fluxo orquestrado (5 ações fluidas)

O fluxo não é um pipeline rígido de fases — cada ação pode ser invocada diretamente quando o contexto já existe.

### 1. propose

Gera `specs/_changes/<slug>/proposta.md` (baseado em `templates/proposal.md`):
- Por quê esta mudança
- O que muda em comportamento observável
- Capabilities afetadas (novas e/ou modificadas)
- Impacto esperado

### 2. spec / delta

**Para capability nova:** gera `specs/<capability>/spec.md` (baseado em `templates/spec.md`) com:
- Propósito da capability
- Requisitos com SHALL/DEVE
- Cenários com QUANDO/ENTÃO (4 hashtags `####` — regra crítica do parser de merge)

**Para mudança em capability existente:** gera `specs/_changes/<slug>/delta/<capability>.md` (baseado em `templates/delta.md`) com as seções:
- `## ADICIONADO Requisitos` — requisitos novos com cenários
- `## MODIFICADO Requisitos` — bloco **completo** do requisito substituído
- `## REMOVIDO Requisitos` — header + Motivo + Migração
- `## RENOMEADO Requisitos` — DE/PARA + corpo preservado

**Regra crítica dos cenários:** todo cenário usa exatamente `####` (4 hashtags). Cenários com `###` (3 hashtags) são rejeitados pelo gate `spec-validate.sh` antes do merge.

### 3. design (opcional)

Documentar decisão de design apenas quando:
- Mudança é cross-cutting (afeta 2+ capabilities)
- Envolve migração de dados ou quebra de contrato existente
- Risco alto (mudança irreversível ou impacto em segurança)

Para os demais casos, pular direto para tasks.

### 4. tasks

Gera `specs/_changes/<slug>/tasks.md` (baseado em `templates/tasks.md`):
- Checklist `- [ ] N.M <descrição>` sob headings `## N. <grupo>`
- Consumível diretamente pelo GSD ou pelo `@dev` do AIOX

### 5. merge + archive

**Gate antes de aplicar:** invoca `source/skills/spec/lib/spec-validate.sh <dir-da-change>`.
Se o gate falhar (exit 1), o merge é abortado com mensagem de erro específica.

**Aplicação determinística:** invoca `source/skills/spec/lib/spec-merge.sh <produto-root> <slug> [--yes]`.
O motor aplica o delta na source-of-truth e move a change para `specs/_archive/AAAA-MM-DD-<slug>/`.
Imprime resumo `+ N adicionados / ~ N modificados / - N removidos / → N renomeados`.

**Não aplicar manualmente** — sempre usar as libs para garantir idempotência e rastreabilidade.

---

## Subcomandos de auditoria (W4)

Além das 5 ações de MUTAÇÃO acima, o `/spec` tem 2 subcomandos de AUDITORIA — libs
invocáveis que analisam a spec VIVA (source-of-truth pós-merge), sem fazer parte do
fluxo de mutação:

### `--analyze` — gate determinístico da spec viva

```
bash source/skills/spec/lib/spec-analyze.sh <produto-root> [<capability>] [--advisory-only]
```

Complementa — NÃO duplica — o `spec-validate.sh`:
- `spec-validate.sh` gateia o **DELTA** (pré-merge, no `_changes/<slug>/delta/`)
- `spec-analyze.sh` gateia a **FONTE** (pós-merge, `specs/<cap>/spec.md`) — pega defeitos que entraram antes do gate existir, ou por edição manual da fonte.

**Zona de contrato:** os checks HARD valem só para `### Requisito:` SOB `## Requisitos`.
Tudo é **fence-aware** (exemplos em ``` ``` não disparam) e as detecções vêm do motor
único `spec-grammar.sh` (sem regex duplicada).

| Check | Severidade | Detecta |
|-------|-----------|---------|
| **A1** | DETERMINÍSTICO / **HARD** | requisito (em `## Requisitos`) sem nenhum `#### Cenário` (não-testável) |
| **A2** | DETERMINÍSTICO / **HARD** | cenário em nível de heading errado (`###`/`#####`/`######`) dentro de um requisito de contrato |
| **A3** | DETERMINÍSTICO / **HARD** | header de requisito duplicado dentro de `## Requisitos` (quebra a chave única do merge) |
| **A4** | DETERMINÍSTICO / **HARD** | token de seção de delta vazado na fonte (`## ADICIONADO…`, qualquer caixa, fora de fence) |
| spec ilegível | DETERMINÍSTICO / **HARD** | `spec.md` sem permissão de leitura (gate não falha em silêncio) |
| **A5** | heurística / **ADVISORY** | cross-ref spec→código: path citado entre backticks que não existe no produto |
| **A6** | heurística / **ADVISORY** | `### Requisito:` FORA de `## Requisitos` (misplaced — contrato vive em `## Requisitos`) |
| passes LLM | LLM / **ADVISORY** | clareza de cenário, cobertura cenário↔código, caminho-de-erro, vocabulário ubíquo |

**Exit:** `0` = limpo · `1` = ≥1 defeito HARD · `2` = erro de invocação. `--advisory-only` NUNCA retorna 1 (rebaixa HARD a aviso).

> **Regra-âncora:** *determinístico pode bloquear; LLM e cross-ref de path só aconselham* (guard-rail: passes LLM = ADVISORY, nunca gated).

### `--converge` — ponte append-only spec↔código

```
bash source/skills/spec/lib/spec-converge.sh <produto-root> [<capability>]
```

Reconcilia a spec viva com a implementação **SEM JAMAIS mutar a source-of-truth**.
Produz uma QUARENTENA `specs/_changes/_converge-<TIMESTAMP>/` com:
- `RELATORIO.md` (banner NÃO-AUTORITATIVO + achados do `--analyze`)
- `delta/<capability>.md` — delta-candidato (só `## MODIFICADO` com `#### Cenário: <PREENCHER>` para requisitos sem cenário; **nunca** infere REMOVIDO/RENOMEADO)
- `proposta.md` stub

O candidato **reentra no fluxo normal** `/spec` (humano revisa → propose → validate → merge — o gate real continua sendo o `spec-validate.sh`). Nada é aplicado.

**Garantia append-only (4 camadas):** (1) único destino é a quarentena `_converge-<TIMESTAMP>/`; (2) guard runtime mata o processo se o destino sair da quarentena; (3) a fonte é aberta só para leitura; (4) sha256 de toda `specs/<cap>/spec.md` antes/depois — divergência → rollback + exit 2.

---

## Exemplos de invocação

```
/spec
→ Perguntar: proposta nova ou aplicar delta existente?
→ Se nova: qual capability? (nova ou existente?)
→ Seguir fluxo propose → spec/delta → tasks → merge+archive
```

```
Deia, quero registrar que o login deve suportar 2FA com TOTP
→ Roteado para /spec
→ Identifica capability "auth"
→ Gera proposta + delta ADICIONADO para specs/_changes/add-2fa/
```

---

## Vocabulário canônico

| PT-BR (superfície) | Token interno (merge) | Significado |
|--------------------|-----------------------|-------------|
| ADICIONADO | ADDED | Novo requisito inserido na spec |
| MODIFICADO | MODIFIED | Requisito existente substituído (bloco completo) |
| REMOVIDO | REMOVED | Requisito removido (exige Motivo + Migração) |
| RENOMEADO | RENAMED | Header renomeado, corpo preservado |

---

## Onde encontrar as libs

- `source/skills/spec/lib/spec-grammar.sh` — **gramática compartilhada** (ponto único de verdade: header de requisito, cenário 4-hashtags, tokens de delta, fronteira de bloco). Os clientes abaixo a consomem.
- `source/skills/spec/lib/spec-validate.sh` — gate binário do DELTA pré-merge (exit 0 = válido, exit 1 = inválido)
- `source/skills/spec/lib/spec-merge.sh` — merge determinístico + archive datado
- `source/skills/spec/lib/spec-analyze.sh` — gate determinístico da SPEC VIVA pós-merge (A1-A4 HARD, A5 ADVISORY)
- `source/skills/spec/lib/spec-converge.sh` — ponte append-only spec↔código (quarentena + sha256 guard)
- `source/skills/spec/templates/` — proposal.md, spec.md, delta.md, tasks.md
- `tests/spec-merge.bats` · `tests/spec-analyze.bats` — fixture-regression (dual-mode bats/bash; rodam no CI e no SOAK)
