#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 | kind: gate | targets: claude,cursor
# =============================================================================
# idea-smoke.sh — Smoke-test do BOOTSTRAP MÍNIMO do IdeiaOS (R15-03)
#
# Prova por EXIT-CODE binário que o setup mínimo está vivo — inclusive no
# Windows nativo meio-instalado onde o idea-doctor degrada CEGO. O doctor depende
# de interpretadores externos (um runtime de script, um cliente de DB embutida, um
# grep recursivo de terceiro) em ~11 pontos — ver os marcadores de dependência em
# scripts/idea-doctor.sh — e sem esses binários ele pula checagens em silêncio ou
# falha. Este script é PURO-BASH 3.2 (zero dependência externa): roda ONDE o
# doctor NÃO roda.
#
# Responde UMA pergunta estreita — "o bootstrap MÍNIMO está vivo?" — checando
# três famílias de fato, todas verificáveis SEM dependência externa:
#   (1) skills/plugins instaladas no DISCO  (~/.claude/skills/<n>/SKILL.md, test -s)
#   (2) hooks REGISTRADOS em settings.json  (substring grep -q, sem parser JSON)
#   (3) comandos básicos resolvem           (command -v node/git/bash; claude opcional)
#
# ── FRONTEIRA CONTRATUAL (R15-03) — smoke ↔ doctor, NÃO se sobrepõem ──────────
#   idea-smoke (este)            : "o bootstrap MÍNIMO está vivo?"
#                                   puro-bash 3.2 (zero dependência externa)
#                                   alvo: estação fresca / Windows nativo meio-instalado
#                                   escopo: skills no disco · hooks registrados · comandos resolvem
#   idea-doctor (existente)      : "qual a SAÚDE PROFUNDA + drift do ambiente?"
#                                   exige interpretadores externos (runtime de script,
#                                   cliente de DB embutida, grep recursivo), launchctl, git refs
#                                   alvo: macOS dev-machine totalmente provisionada
#                                   escopo: versões vs lock · secrets em memória ·
#                                           contenção Lovable MCP · frescor de segurança ·
#                                           drift global×fonte · cockpit
#   Invariante de não-duplicação : o smoke NUNCA reimplementa um check profundo
#                                  do doctor. Se um fato exige interpretador externo,
#                                  ele é do DOCTOR, não do smoke.
#
# USO:
#   bash scripts/idea-smoke.sh          # build-contract: exit 0=ok, 1=bootstrap quebrado
#   bash scripts/idea-smoke.sh --hook   # hook-contract:  exit 0 SEMPRE (warn em stderr)
#   bash scripts/idea-smoke.sh --help   # imprime uso e sai 0
#
# Exit: 0 = bootstrap mínimo OK   (ou --hook, sempre)
#       1 = bootstrap quebrado    (apenas no modo build)
#       2 = erro de invocação
#
# Build script (não hook): exit 1 em falha. Com --hook vira hook (exit 0 sempre,
# nunca trava sessão da IDE — antifragile-gates: Hook Contract).
# =============================================================================
set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }

FAIL=0
WARN=0
HOOK_MODE=0

usage() {
  cat <<'USAGE'
idea-smoke.sh — smoke-test do bootstrap mínimo do IdeiaOS (puro-bash)

USO:
  bash scripts/idea-smoke.sh          build-contract: exit 0=ok, 1=bootstrap quebrado
  bash scripts/idea-smoke.sh --hook   hook-contract:  exit 0 SEMPRE (warn em stderr)
  bash scripts/idea-smoke.sh --help   imprime esta ajuda e sai 0

Checa o bootstrap MÍNIMO (skills no disco, hooks registrados em settings.json,
comandos básicos resolvem). Para saúde PROFUNDA + drift use: bash scripts/idea-doctor.sh
USAGE
}

# ── Parse de flags ────────────────────────────────────────────────────────────
MODE="${1:-}"
case "$MODE" in
  ''        ) ;;                              # default = build-contract
  --hook    ) HOOK_MODE=1 ;;
  --help|-h ) usage; exit 0 ;;
  *         ) echo "idea-smoke: flag desconhecida: $MODE" >&2; usage >&2; exit 2 ;;
esac

# ── Antifragile gate: reusa source/lib/gates.sh; fallback inline se lib ausente ─
IDEIAOS_DIR="${IDEIAOS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
[ -f "$IDEIAOS_DIR/source/lib/gates.sh" ] && . "$IDEIAOS_DIR/source/lib/gates.sh"
type assert_nonempty >/dev/null 2>&1 \
  || assert_nonempty() { test -s "${1:-}" 2>/dev/null; }

GSKILLS="$HOME/.claude/skills"
SETTINGS="$HOME/.claude/settings.json"

# ── (1) Comandos básicos resolvem ─────────────────────────────────────────────
# node/git/bash são ESSENCIAIS (FAIL se ausentes). claude é OPCIONAL — o smoke
# DEVE passar onde o CLI claude não está no PATH (cf. idea-doctor.sh:179, só avisa).
check_commands() {
  echo -e "\n${CYAN}${BOLD}── 1) Comandos básicos resolvem ──${NC}"
  for c in node git bash; do
    if command -v "$c" >/dev/null 2>&1; then
      ok "comando '$c' resolve"
    else
      err "comando '$c' AUSENTE — pré-requisito do IdeiaOS (instale node 18+, git, bash)"
      FAIL=$((FAIL + 1))
    fi
  done
  if command -v claude >/dev/null 2>&1; then
    ok "comando 'claude' resolve (opcional)"
  else
    warn "comando 'claude' ausente (opcional — não bloqueia o smoke)"
    WARN=$((WARN + 1))
  fi
}

# ── (2) Skills no DISCO (fonte-de-verdade do bootstrap) ────────────────────────
# Conjunto-mínimo = subconjunto do ORCH de idea-doctor.sh:154 que o setup.sh
# instala. Gate por test -s (assert_nonempty), não por [ -f ].
check_skills() {
  echo -e "\n${CYAN}${BOLD}── 2) Skills instaladas no disco ──${NC}"
  for s in idea ideiaos-setup cursor-continuation lovable-handoff; do
    if assert_nonempty "$GSKILLS/$s/SKILL.md" "skill /$s"; then
      ok "skill /$s instalada"
    else
      err "skill /$s AUSENTE ou vazia — rode: bash setup.sh --global-only"
      FAIL=$((FAIL + 1))
    fi
  done

  # GSD vem de plugin de marketplace — pode faltar numa estação crua (warn, não FAIL).
  GSD_COUNT=$(ls -d "$GSKILLS"/gsd-* 2>/dev/null | wc -l | tr -d ' ')
  if [ "$GSD_COUNT" -gt 0 ]; then
    ok "GSD: $GSD_COUNT skills /gsd-* no disco"
  else
    warn "GSD ausente — adicione o plugin GSD no menu do Claude Code (não bloqueia o smoke)"
    WARN=$((WARN + 1))
  fi

  # Fallback gracioso de `claude plugin list`: CONTEXTO, nunca critério de PASS/FAIL.
  # A decisão vem SEMPRE do test -s no disco — `claude plugin list` retorna
  # "No plugins installed" mesmo com skills instaladas (confirmado em runtime), então
  # usá-lo como critério daria falso-FAIL. Guardado por command -v claude; o exit do
  # claude NUNCA propaga para o exit do smoke.
  if command -v claude >/dev/null 2>&1 && claude plugin list >/dev/null 2>&1; then
    PLUGIN_LINE=$(claude plugin list 2>/dev/null | head -1)
    info "claude plugin list (contexto, não critério): ${PLUGIN_LINE:-<vazio>}"
  fi
}

# ── (3) Hooks REGISTRADOS em settings.json (substring, sem parser JSON) ─────────
# grep -q por nome exato — puro-bash, igual setup.sh:742. NÃO parsear o JSON com
# um interpretador externo (isso recairia no modo-falha do doctor).
check_hooks() {
  echo -e "\n${CYAN}${BOLD}── 3) Hooks registrados em settings.json ──${NC}"
  if [ ! -f "$SETTINGS" ]; then
    err "settings.json não encontrado em $SETTINGS — rode: bash setup-dev-machine.sh"
    FAIL=$((FAIL + 1))
    return
  fi
  ok "settings.json presente"
  for h in extract-learnings-reminder.sh ideiaos-detector.sh deia-trigger.sh; do
    if grep -q "$h" "$SETTINGS" 2>/dev/null; then
      ok "hook '$h' registrado"
    else
      err "hook '$h' NÃO registrado — rode: bash scripts/ideiaos-update.sh (ou bash setup-dev-machine.sh)"
      FAIL=$((FAIL + 1))
    fi
  done
}

# ── Roteador ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}━━━ idea-smoke: bootstrap mínimo do IdeiaOS ━━━${NC}"
check_commands
check_skills
check_hooks

# ── Sumário ────────────────────────────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}━━━ resumo ━━━${NC}"
echo -e "  FAIL=${FAIL}  WARN=${WARN}"

# ── Dual-contract de exit ──────────────────────────────────────────────────────
if [ "${HOOK_MODE:-0}" -eq 1 ]; then
  # HOOK CONTRACT — nunca trava a sessão da IDE: exit 0 SEMPRE (warn em stderr).
  if [ "$FAIL" -gt 0 ]; then
    echo "idea-smoke: bootstrap incompleto ($FAIL check(s) falharam) — rode: bash scripts/idea-smoke.sh" >&2
  fi
  exit 0
fi

# BUILD CONTRACT — falha alto (espelha check-cockpit.sh:145-150).
if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}${BOLD}  ✗ idea-smoke FALHOU ($FAIL check(s)) — bootstrap mínimo quebrado${NC}"
  exit 1
fi
echo -e "\n${GREEN}${BOLD}  ✓ idea-smoke OK — bootstrap mínimo vivo${NC}"
exit 0
