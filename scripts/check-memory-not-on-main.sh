#!/usr/bin/env bash
# =============================================================================
# check-memory-not-on-main.sh — guarda ativa que impede memória de chegar ao main.
#
# CONTEXTO (incidente nfideia, commit 604c0a19):
#   O arquivo `.lovable_mem_tmp.md` vazou para `nfideia:main` porque um staging
#   de memória foi escrito na working tree do branch corrente e o autosync o
#   commitou. O `main` é lido continuamente pela Lovable Cloud — qualquer commit
#   de memória ali dispara um Lovable Update indevido. Barreira ativa >
#   documentação passiva (mesmo princípio do check-versions-lock.sh).
#
# INVARIANTE (ARCHITECTURE.md / v5-ROADMAP.md):
#   Memória vive APENAS no branch `planning` (.planning/memory/). O `main` nunca
#   é tocado. `planning` NUNCA faz merge para `main`. Esta guarda barra:
#     1. commit/merge ONDE o branch de destino é `main` (ou MERGE_HEAD = planning)
#     2. E os arquivos staged/incoming incluem qualquer caminho de memória:
#          - .planning/memory/        (store canônico — só pode estar no planning)
#          - .lovable_mem_tmp.md       (o leak histórico — nunca em árvore alguma)
#          - .cursor/rules/memory-bridge.mdc  (ponte Cursor — gitignored, local)
#
# MENSAGEM DIRECIONAL: a guarda diz EXATAMENTE qual lado está errado (não um
#   "conflito" genérico). Lição registrada: aviso ambíguo induz agente a reverter.
#   Bypass consciente: IDEIAOS_MEM_OVERRIDE=1 git commit ...
#   (espelha IDEIAOS_LOCK_OVERRIDE do check-versions-lock.sh)
#
# USO:
#   bash scripts/check-memory-not-on-main.sh            # valida o working tree
#   bash scripts/check-memory-not-on-main.sh --staged   # valida o index (pre-commit)
#   bash scripts/check-memory-not-on-main.sh --merge    # valida merge (pre-merge-commit)
#
# Exit: 0 = ok · 1 = violação
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-}"

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'

# Padrões de memória que NUNCA podem chegar ao main.
is_memory_path() {
  case "$1" in
    .planning/memory/*|.planning/memory) return 0 ;;
    .lovable_mem_tmp.md) return 0 ;;
    .cursor/rules/memory-bridge.mdc) return 0 ;;
  esac
  return 1
}

# ── Branch de destino ────────────────────────────────────────────────────────
# HEAD aponta para o branch onde o commit/merge vai aterrissar.
BRANCH="$(git -C "$REPO_DIR" symbolic-ref --short -q HEAD 2>/dev/null || echo '')"

# ── É um merge entrando do planning? (pre-merge-commit) ──────────────────────
# MERGE_HEAD existe durante um merge em andamento; o pre-merge-commit roda antes
# do commit de merge ser criado, com MERGE_HEAD já apontando para o branch fonte.
MERGE_SRC=""
if [ "$MODE" = "--merge" ] || [ -f "$REPO_DIR/.git/MERGE_HEAD" ]; then
  MERGE_SRC="$(git -C "$REPO_DIR" name-rev --name-only --refs='refs/heads/*' \
                 "$(cat "$REPO_DIR/.git/MERGE_HEAD" 2>/dev/null)" 2>/dev/null || echo '')"
fi

# Caso especial: merge planning→main é proibido EM QUALQUER hipótese, mesmo que
# o diff de memória não apareça staged (o planning carrega a memória por design).
if [ "$BRANCH" = "main" ] && printf '%s\n' "$MERGE_SRC" | grep -q 'planning'; then
  if [ "${IDEIAOS_MEM_OVERRIDE:-0}" != "1" ]; then
    echo -e "${RED}❌ memória: merge 'planning' → 'main' BLOQUEADO.${NC}"
    echo ""
    echo "   Lado errado: você está em 'main' tentando puxar o branch 'planning'."
    echo "   'planning' carrega o store de memória (.planning/memory/) e NUNCA"
    echo "   pode fazer merge para 'main' — a Lovable Cloud lê 'main' e dispararia"
    echo "   um Update indevido (incidente .lovable_mem_tmp.md em nfideia:main)."
    echo ""
    echo "   Topologia correta: 'main' recebe apenas de 'work'/feature via"
    echo "   /lovable-handoff. Memória fica em 'planning'. Ver:"
    echo "   docs/decisions/v5-memory-topology.md"
    echo ""
    echo -e "   Merge intencional (NÃO recomendado)? ${YELLOW}IDEIAOS_MEM_OVERRIDE=1 git merge ...${NC}"
    exit 1
  fi
fi

# Só inspecionamos arquivos quando o destino é o main. Em work/feature/planning,
# memória pode aparecer livremente (planning é o store; work é trânsito interno).
if [ "$BRANCH" != "main" ]; then
  echo -e "${GREEN}✅ memória: branch '$BRANCH' (não-main) — sem restrição de memória${NC}"
  exit 0
fi

# ── Lista de arquivos a inspecionar (destino = main) ─────────────────────────
case "$MODE" in
  --staged|--merge)
    # Index: o que está prestes a ser commitado em main.
    FILES="$(git -C "$REPO_DIR" diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
    ;;
  *)
    # Working tree: tracked + untracked (o leak histórico era untracked).
    FILES="$(git -C "$REPO_DIR" status --porcelain 2>/dev/null | sed 's/^...//' || true)"
    ;;
esac

OFFENDERS=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  # status --porcelain pode trazer "old -> new" em renames; pega o destino.
  case "$f" in *" -> "*) f="${f##* -> }" ;; esac
  if is_memory_path "$f"; then
    OFFENDERS="${OFFENDERS}${f}\n"
  fi
done <<< "$FILES"

if [ -n "$OFFENDERS" ]; then
  if [ "${IDEIAOS_MEM_OVERRIDE:-0}" = "1" ]; then
    echo -e "${YELLOW}⚠ memória em 'main' permitida por IDEIAOS_MEM_OVERRIDE=1${NC}"
    exit 0
  fi
  echo -e "${RED}❌ memória: arquivo(s) de memória staged/presentes no branch 'main'.${NC}"
  echo ""
  echo "   Lado errado: o BRANCH está em 'main' — não os arquivos. Memória é"
  echo "   válida, só não pode viver aqui. Mova-a para o branch 'planning'."
  echo ""
  echo "   Arquivo(s) bloqueado(s):"
  printf "     %b" "$OFFENDERS"
  echo ""
  echo "   Por quê: a Lovable Cloud lê 'main' automaticamente; memória ali"
  echo "   dispara um Lovable Update indevido (incidente .lovable_mem_tmp.md"
  echo "   em nfideia:main). Memória só pode estar em 'planning'."
  echo ""
  echo "   Como corrigir:"
  echo "     git restore --staged <arquivo>     # tira do index do main"
  echo "     # o export de memória (memory-export / /memory-sync) já escreve"
  echo "     # em 'planning' via git plumbing — não escreva na árvore do main."
  echo ""
  echo -e "   Bypass consciente (NÃO recomendado)? ${YELLOW}IDEIAOS_MEM_OVERRIDE=1 git commit ...${NC}"
  exit 1
fi

echo -e "${GREEN}✅ memória: 'main' limpo (nenhum caminho de memória staged)${NC}"
exit 0
