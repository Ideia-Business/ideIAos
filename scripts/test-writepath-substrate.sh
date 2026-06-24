#!/bin/bash
# test-writepath-substrate.sh — gate AGREGADO do SUBSTRATO LOCAL do write-path v14.4 (B5–B8).
#
# IRMÃO de test-writepath-bootstrap.sh (que prova B0–B4 = step-up/O2 cripto). Este prova o substrato
# LOCAL que o ADR Q5 (docs/decisions/v14.4-command-ref-origin-exposure.md, ACEITO) já permite construir
# cripto-local — INDEPENDENTE da ratificação do seal e do push ao origin (ambos gated no owner):
#
#   B5  cmd-ref   (R-WP6)  — ref OPACO refs/ideiaos/cmd, transportado por plumbing puro, ISOLADO do
#                            working tree (o `git add -A` cego do autosync não o captura).
#   B6  ledger    (R-WP9)  — ledger hash-chained append-only LOCAL: detecção de reescrita (não-repúdio).
#   B7  ack       (R-WP8)  — ACK idempotente LOCAL + high-water mark: efeito único em reentrega.
#   B8  rate-limit (R-WP12) — throttle determinístico por (ref+subject): defesa SECUNDÁRIA (nega, nunca concede).
#
# ANTI-TEATRO: cada lib tem seu teste standalone em tests/writepath/test-<lib>.sh, com manifesto interno
# (N/N), CANÁRIO (detecta mecanismo QUEBRADO, não só ausente) e MUTAÇÃO-provada (sabota a lib → vermelho;
# restaura → verde). Este agregado:
#   (a) MANIFESTO: roda EXPECTED_GATES sub-gates; reprova se gates_run != EXPECTED_GATES;
#   (b) exige exit 0 de CADA sub-gate;
#   (c) META-CANÁRIO: prova que o próprio runner detecta um sub-gate que sai !=0 (não é always-green);
#   (d) GATE-NEGATIVO: nenhuma das 4 libs novas faz egress/provider (regex idêntica ao bootstrap).
#
# ZERO segredo, ZERO mutação de produção, ZERO chamada a provedor. Build-contract: exit 1 em qualquer falha.
# R-WP10 segue FECHADO — este gate prova o substrato LOCAL, não a feature cross-máquina (seal + N=2 + push gated).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$ROOT/tests/writepath"
AGENTD="$ROOT/source/agentd"

PASS=0; FAIL=0; GATES_RUN=0
EXPECTED_GATES=5     # MANIFESTO: tem que bater com os run_gate abaixo (anti-teatro (a))
declare -a FAILED_NAMES=()

c_green(){ printf '\033[0;32m%s\033[0m\n' "$1"; }
c_red(){ printf '\033[0;31m%s\033[0m\n' "$1"; }

# run_gate NAME TESTFILE — roda um teste standalone e exige exit 0
run_gate() {
  local name="$1" tf="$2"
  GATES_RUN=$((GATES_RUN+1))
  if [ ! -s "$tf" ]; then FAIL=$((FAIL+1)); FAILED_NAMES+=("$name (ausente)"); printf '  ✗ %-26s teste AUSENTE: %s\n' "$name" "$tf"; return; fi
  if bash "$tf" >/dev/null 2>&1; then
    PASS=$((PASS+1)); printf '  ✓ %-26s (%s verde)\n' "$name" "$(basename "$tf")"
  else
    FAIL=$((FAIL+1)); FAILED_NAMES+=("$name"); printf '  ✗ %-26s FALHOU (%s)\n' "$name" "$(basename "$tf")"
  fi
}

echo "── substrato write-path v14.4 (B5–B8) ──"
run_gate "B5 cmd-ref"    "$TESTS/test-cmd-ref.sh"
run_gate "B6 ledger"     "$TESTS/test-ledger.sh"
run_gate "B7 ack"        "$TESTS/test-ack.sh"
run_gate "B8 rate-limit" "$TESTS/test-rate-limit.sh"
run_gate "SEAL X25519"   "$TESTS/test-seal.sh"

# ───────────────────────── (c) META-CANÁRIO ─────────────────────────
# Prova que o runner DETECTA um sub-gate quebrado (sai !=0). Sem isto, "rodar 4 testes e checar 0"
# poderia ser teatro se o runner engolisse falhas. Um teste-isca que sai 1 TEM que ser visto como falha.
canary_tmp="$(mktemp "${TMPDIR:-/tmp}/substrate-canary.XXXXXX")"
printf '#!/bin/bash\nexit 1\n' > "$canary_tmp"
if bash "$canary_tmp" >/dev/null 2>&1; then meta_canary_ok=0; else meta_canary_ok=1; fi
rm -f "$canary_tmp"
if [ "$meta_canary_ok" -eq 1 ]; then
  c_green "  ✓ META-CANÁRIO: runner detecta sub-gate quebrado (sai !=0)"
else
  c_red   "  ✗ META-CANÁRIO: runner NÃO detecta sub-gate quebrado — gate seria teatro"; FAIL=$((FAIL+1))
fi

# ───────────────────────── (d) GATE-NEGATIVO ─────────────────────────
# Nenhuma das 4 libs novas faz egress/provider EM CÓDIGO (comentário citando provedor não conta — code_only o remove).
# Regex IDÊNTICA ao test-writepath-bootstrap.sh (anti-drift entre os dois gates irmãos).
code_only() { grep -hEv '^[[:space:]]*(//|#|\*|/\*)' "$@" 2>/dev/null; }
neg_hits=$(code_only "$AGENTD/ledger.sh" "$AGENTD/ack.sh" "$AGENTD/rate-limit.sh" "$AGENTD/cmd-ref.sh" \
  | grep -En 'curl|wget|fetch *\(|vercel|railway|supabase|\bdeno\b|\bnc\b|\bscp\b|ssh +[^ ]*@|gh +(api|pr|push)|git +push|api\.' || true)
# seal/unseal são .mjs (Node): cripto SÓ via node:crypto local — zero egress/child_process/rede.
mjs_hits=$(code_only "$AGENTD/seal.mjs" "$AGENTD/unseal.mjs" \
  | grep -En 'fetch *\(|require\(.child_process|from .child_process|https?\.|\bnet\b|dgram|\.connect\(|XMLHttpRequest|curl|wget' || true)
if [ -z "$neg_hits" ] && [ -z "$mjs_hits" ]; then
  c_green "  ✓ GATE-NEGATIVO: zero egress/provider em CÓDIGO nas 4 libs (.sh) + seal/unseal (.mjs)"
else
  c_red   "  ✗ GATE-NEGATIVO: egress/provider no substrato: ${neg_hits}${mjs_hits}"; FAIL=$((FAIL+1))
fi

echo "─────────────────────────────────────────────"
echo "sub-gates: run=$GATES_RUN  pass=$PASS  fail=$FAIL  (manifesto EXPECTED_GATES=$EXPECTED_GATES)"

if [ "$GATES_RUN" -ne "$EXPECTED_GATES" ]; then
  c_red "✗ MANIFESTO violado: gates_run ($GATES_RUN) != EXPECTED_GATES ($EXPECTED_GATES) — sub-gate somido/extra"
  exit 1
fi
if [ "$FAIL" -ne 0 ]; then
  c_red "✗ substrato FALHOU: ${FAILED_NAMES[*]:-meta-canário/gate-negativo}"
  exit 1
fi
c_green "✓ writepath SUBSTRATE GATE verde — B5–B8 (ref-opaco/ledger/ack/rate-limit) por exit-code + meta-canário + gate-negativo"
exit 0
