#!/usr/bin/env bash
# SOURCE: IdeiaOS v14 | kind: lib | targets: claude,cursor
# =============================================================================
# cockpit.sh — Federação por ref: grava/lê snapshots em refs/heads/cockpit
#              via git-plumbing puro (hash-object → mktree → commit-tree → update-ref).
#              INVARIANTE A4: working tree NUNCA tocado (git status --porcelain vazio).
#              Sourced once per shell session via __IDEIAOS_COCKPIT_LOADED guard.
#
# Usage:
#   . "$IDEIAOS_DIR/source/lib/cockpit.sh"
#   cockpit_write_snapshot  <machine_id> <json_string>
#   cockpit_read_snapshot   <machine_id>
#   cockpit_list_machines
#
# Invariantes garantidas:
#   A4  — git status --porcelain vazio após gravar (plumbing puro; índice nunca tocado)
#   PRESERVA — gravar máquina B não apaga máquina A
#   IDEMPOTÊNCIA — re-gravar mesmo MID substitui (nunca duplica)
#   ÓRFÃO — 1ª gravação cria o ref sem pai (-p omitido)
# =============================================================================
[ -n "${__IDEIAOS_COCKPIT_LOADED:-}" ] && return 0
__IDEIAOS_COCKPIT_LOADED=1

# Sourcar gates.sh se disponível; fallback inline (antifragile-gates.md)
[ -n "${IDEIAOS_DIR:-}" ] && [ -f "$IDEIAOS_DIR/source/lib/gates.sh" ] \
  && . "$IDEIAOS_DIR/source/lib/gates.sh" 2>/dev/null || true
type assert_nonempty >/dev/null 2>&1 \
  || assert_nonempty() { test -s "${1:-}"; }
type gate_output >/dev/null 2>&1 \
  || gate_output() { assert_nonempty "$@"; }

# ---------------------------------------------------------------------------
# cockpit_write_snapshot MID JSON_STRING
#
# Grava snapshots/<MID>.json dentro de refs/heads/cockpit por git-plumbing puro.
# Constrói a árvore em DOIS níveis (git mktree é um-nível-só; pipar uma entrada
# com "/" no nome, ex "snapshots/<mid>.json", falha com "fatal: contains slash",
# exit 128 — por isso subárvore FLAT primeiro, topo depois).
#
# Ramo APPEND  (ref já existe): lê subárvore cockpit:snapshots, descarta
#              a entrada desta máquina, adiciona a nova e mktree do conjunto.
# Ramo ÓRFÃO  (1ª vez, ref ausente): subárvore só com a entrada nova.
# ---------------------------------------------------------------------------
cockpit_write_snapshot() {
  local MID="${1:?cockpit_write_snapshot: machine_id obrigatório}"
  local JSON="${2:?cockpit_write_snapshot: json_string obrigatório}"

  # 1) Blob do JSON do snapshot
  local BLOB
  BLOB=$(printf '%s' "$JSON" | git hash-object -w --stdin)

  # 2) Subárvore FLAT snapshots/ — entrada é APENAS "<mid>.json", SEM prefixo "snapshots/"
  #    APPEND: lê entradas da subárvore snapshots/ atual, descarta a desta máquina, soma a nova
  #    ÓRFÃO : existing vazio → subárvore só com a entrada nova
  local EXISTING
  EXISTING=$(git ls-tree refs/heads/cockpit:snapshots 2>/dev/null \
    | grep -v $'\t'"$MID.json"'$' || true)

  local SUB
  SUB=$(printf '%s\n100644 blob %s\t%s.json\n' "$EXISTING" "$BLOB" "$MID" \
    | grep -v '^$' \
    | git mktree)

  # 3) Árvore TOPO referenciando a subárvore sob o nome "snapshots"
  local TOP
  TOP=$(printf '040000 tree %s\tsnapshots\n' "$SUB" | git mktree)

  # 4) Commit (parent = tip atual do cockpit se existir, senão órfão) e mover o ref
  #    INVARIANTE A4: nunca git add / índice temporário (plumbing puro)
  local PARENT
  PARENT=$(git rev-parse -q --verify refs/heads/cockpit || true)

  local COMMIT
  COMMIT=$(git commit-tree "$TOP" ${PARENT:+-p "$PARENT"} -m "cockpit: snapshot $MID")

  git update-ref refs/heads/cockpit "$COMMIT"
}

# ---------------------------------------------------------------------------
# cockpit_read_snapshot MID
# Lê o snapshot de uma máquina diretamente do object store (sem tocar working tree).
# ---------------------------------------------------------------------------
cockpit_read_snapshot() {
  local MID="${1:?cockpit_read_snapshot: machine_id obrigatório}"
  git show "cockpit:snapshots/$MID.json"
}

# ---------------------------------------------------------------------------
# cockpit_list_machines
# Lista todos os machine_ids presentes no ref cockpit.
# ---------------------------------------------------------------------------
cockpit_list_machines() {
  git ls-tree --name-only cockpit snapshots/
}

# End of cockpit.sh — sourced once per shell session via __IDEIAOS_COCKPIT_LOADED guard
