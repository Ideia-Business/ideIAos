<!--SOURCE: IdeiaOS v2 | kind: rule | targets: claude,cursor-->
# Antifragile Gates — Bash I/O Validation

## Principle

Never trust the Read tool to verify that a file was written. The Read tool is an LLM
operation and can hallucinate content or silently succeed on a missing file. Use only
binary bash exit codes: `test -s PATH` returns 0 if the file exists and is non-empty,
non-zero otherwise. That exit code cannot be hallucinated.

Source: OpenSquad runner.pipeline.md — "Do NOT rely on reading the file with the Read
tool to verify output. Use ONLY the bash test -s command — its output is binary and
cannot be hallucinated."

## The Helper: source/lib/gates.sh

All IdeiaOS hooks and build scripts that produce file artifacts must gate their outputs
using source/lib/gates.sh. Source it once per script:

    . "$IDEIAOS_DIR/source/lib/gates.sh"

Three functions (all bash 3.2 compat, no-jq, no python3):

- `assert_nonempty PATH [LABEL]` — fails if PATH is missing or zero bytes
- `gate_output PATH [LABEL]` — synonym for assert_nonempty (output-validation semantics)
- `require_file PATH [LABEL]` — synonym for assert_nonempty (dependency-check semantics)

Double-source guard: `__IDEIAOS_GATES_LOADED` prevents repeated function redefinition.

## Hook Contract vs Build Contract

Hooks (Stop / UserPromptSubmit triggers) MUST exit 0 on any failure — a crashing hook
blocks the IDE session. When a gate fails inside a hook, log a warning to stderr and
exit 0. Never exit non-zero from a hook.

Build scripts (scripts/*.sh) MUST exit 1 on gate failure. A silent bad build is worse
than a loud failure.

## When to Use

Apply a gate after every step that is expected to write a file artifact and whose output
will be consumed by a subsequent step. Minimum 3 gate points per script that handles
file I/O pipelines.

## Dois regimes de verificação — artefato-de-arquivo vs estado-de-runtime

<!-- # SOURCE: testzeus-hercules (AGPL-3.0) — conceito-only, zero código/prosa. -->

A regra acima (`test -s` é lei) cobre o **artefato-de-arquivo**: algo que um passo
gravou no disco e um passo seguinte vai consumir. Aí o exit-code binário é
inegociável — nunca o Read tool.

Mas há um **segundo regime** onde não existe exit-code: o **estado de runtime/UI**.
Verificar que "o botão ficou azul" ou "o modal abriu" não é um `test -s` — é
interpretação de screenshot + accessibility-tree, que a skill já-shippada
`frontend-visual-loop` faz legitimamente. Isso **não viola** o gate: são dois
regimes distintos, não uma exceção a ele.

| Regime | O que se verifica | Instrumento (lei) |
|--------|-------------------|-------------------|
| **Artefato-de-arquivo** | arquivo gravado, build, teste | `test -s` / exit-code binário — NUNCA Read tool |
| **Estado-de-runtime/UI** | comportamento visual/interativo sem exit-code | render + screenshot + a11y-tree (`frontend-visual-loop`), com critério explícito |

A fronteira: **se existe exit-code, ele é lei** (não troque por interpretação em NL).
Só quando não existe exit-code (runtime/UI) a verificação por interpretação é
legítima — e ainda assim exige critério explícito declarado, nunca "parece certo".

## Inline Fallback

When a hook is installed to ~/.claude/hooks/ and IDEIAOS_DIR is not available at
runtime, define the minimal inline fallback before using any gate:

    type gate_output >/dev/null 2>&1 \
      || gate_output() { test -s "${1:-}" 2>/dev/null; }
