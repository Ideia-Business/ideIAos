# SOAK Gate — disciplina de fechamento de milestone (v11 W3)

> **Princípio (NASA #4 da revisão de sistemas 2026-06-19):** nenhum milestone é
> declarado DONE/tagueado até **soakar** — passar `idea-doctor` (0 FAIL) + a suíte
> de regressão estrutural em **≥2 máquinas distintas** por **≥1 dia**.
> Barreira ativa contra "velocidade > durabilidade": um milestone que parece pronto
> numa máquina pode quebrar noutra (drift de install global, diferença de SO,
> corrida do autosync). O soak dá **tempo + diversidade de ambiente** antes da tag.

## Por que existe

Histórico IdeiaOS: contenção Lovable MCP "íntegra nos 5 alvos" era *point-in-time*
e regrediu no mesmo dia (v10); pin GSD revertido 3×; deny rules uncommitted que
sumiram. O padrão comum: **verificação num único instante, numa única máquina**,
tratada como permanente. O SOAK gate força que a evidência seja **plural** (mais de
uma máquina) e **durável** (sobrevive ≥1 dia) antes de cravar um milestone.

## Mecanismo — `scripts/check-soak.sh`

Ledger append-only por milestone: `.planning/soak/<milestone>.log`
Formato: `<epoch>|<iso>|<hostname>|idea_doctor=PASS|regression=PASS|<commit>`

```bash
# Em CADA máquina, quando o milestone parece pronto:
bash scripts/check-soak.sh v11-arsenal --record   # roda idea-doctor + regressão; se PASS, grava heartbeat
git add .planning/soak/ && git commit -m "soak: v11 heartbeat $(hostname -s)"   # compartilha (autosync empurra)

# Antes de taguear (W6 / fechamento):
bash scripts/check-soak.sh v11-arsenal            # exit 0 = pode tagear; exit 1 = ainda não
bash scripts/check-soak.sh v11-arsenal --status   # resumo do ledger
```

**Política (override por env):** `SOAK_MIN_MACHINES=2` · `SOAK_MIN_DAYS=1`.
Span medido entre o heartbeat mais antigo e o mais novo (em epoch). Máquinas
contadas por hostname distinto com **ambos** os gates PASS.

**Bypass consciente** (só com justificativa registrada no SUMMARY/handoff):
`SOAK_MIN_MACHINES=1 SOAK_MIN_DAYS=0 bash scripts/check-soak.sh <milestone>`.

## Integração com o fechamento (W6)

O passo de tag de qualquer milestone DEVE rodar `check-soak.sh <milestone>` e só
prosseguir com exit 0. Milestone que não soakou → **fecha PARCIAL, sem tag**
(precedente v10). Isso se **auto-aplica ao v11**: como o soak exige 2 máquinas e
≥1 dia, o v11 não pode ser tagueado na mesma sessão em que foi construído — o que
é exatamente a disciplina pretendida (dogfooding do próprio gate).

## O que conta como "regressão"

A suíte **estrutural** (sem API key) — a mesma do job `structural` do CI:
- `tests/*/test-*.sh`
- `evals/run-evals.sh --dry-run`

A suíte LLM (`run-evals.sh --ci`, requer `ANTHROPIC_API_KEY`) **não** é exigida no
soak local — ela roda no CI sob demanda. O soak prova estabilidade de ambiente +
regressão estrutural em máquinas reais, não a qualidade semântica (essa é dos evals).

## Relação com "profiles" de skills (mesma onda W3)

Superfície de skills numa máquina fresca **não** é ~103 — o `manifests/modules.json`
já a cura via `installStrategy`: **`always`** (perfil default, ~25 skills),
**`stack:<x>`** (só quando o projeto usa aquele stack), **`manual`** (opt-in).
Esse é o "profile" default, contratado pelo manifesto. `idea-doctor` vigia o
**orçamento de superfície** (WARN se `always` crescer além do teto) para não
voltar a inchar. Ver README → seção de skills/manifesto.
