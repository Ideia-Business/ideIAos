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

## Inline Fallback

When a hook is installed to ~/.claude/hooks/ and IDEIAOS_DIR is not available at
runtime, define the minimal inline fallback before using any gate:

    type gate_output >/dev/null 2>&1 \
      || gate_output() { test -s "${1:-}" 2>/dev/null; }
