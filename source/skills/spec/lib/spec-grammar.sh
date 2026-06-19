#!/usr/bin/env bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v11
# =============================================================================
# spec-grammar.sh — gramática COMPARTILHADA da delta-spec (ponto ÚNICO de verdade)
#
# A convenção de marcação das specs (header de requisito, cenário 4-hashtags,
# tokens de seção de delta, fronteira de bloco, normalização de nome) estava
# REPETIDA literalmente em spec-validate.sh e spec-merge.sh. Esta lib a codifica
# UMA vez para os clientes novos (spec-analyze.sh, spec-converge.sh) — se a
# convenção evoluir, muda-se 1 arquivo (cf. learning declarative-vs-imperative-drift).
#
# As funções abaixo são CÓPIA LITERAL das condições já provadas em
# spec-validate.sh / spec-merge.sh (mesmas regex, mesma tolerância de encoding),
# para que unificar validate/merge a esta lib depois seja um delta trivial. O W11
# só ADICIONA clientes — não refatora os gates existentes (que já estão verdes).
#
# Sem efeitos colaterais. Bash 3.2 (sem nameref/assoc-array). Sourcear, não exec.
# =============================================================================
[ -n "${__IDEIAOS_SPEC_GRAMMAR_LOADED:-}" ] && return 0
__IDEIAOS_SPEC_GRAMMAR_LOADED=1

# gram_is_req_header LINE → exit 0 se a linha é um header de requisito
# (espelha spec-validate.sh L120: grep '^### Requisito:')
gram_is_req_header() { printf '%s' "${1:-}" | grep -q '^### Requisito:'; }

# gram_req_name LINE → echoa o nome canônico do requisito
# (normalização IDÊNTICA a validate L141 e merge L155/278/386)
gram_req_name() { printf '%s' "${1:-}" | sed 's/^### Requisito: *//'; }

# gram_is_scenario LINE → exit 0 se a linha é um cenário (4 hashtags)
# (espelha spec-validate.sh L167: grep '^#### ' → HAS_SCENARIO)
gram_is_scenario() { printf '%s' "${1:-}" | grep -q '^#### '; }

# gram_is_delta_section LINE → exit 0 se a linha é um header de seção de delta
# (espelha o alternation de spec-validate.sh L77/105-112)
gram_is_delta_section() {
  printf '%s' "${1:-}" | grep -qE '^## (ADICIONADO|ADDED|MODIFICADO|MODIFIED|REMOVIDO|REMOVED|RENOMEADO|RENAMED)\b'
}

# gram_is_block_break LINE → exit 0 se a linha encerra o bloco de um requisito
# (a MESMA fronteira de bloco usada 6x no merge: L230/265/303/342/374/406)
gram_is_block_break() { printf '%s' "${1:-}" | grep -qE '^(## |### Requisito:)'; }

# gram_scan_reqs FILE → emite, por requisito, uma linha TSV:
#   REQNAME<TAB>LINE<TAB>HAS_SCENARIO(0|1)<TAB>SECTION
# Máquina-de-estado equivalente a spec-validate.sh L73-204, mas sobre a spec
# VIVA (source-of-truth) em vez do delta. SECTION = heading ## ativo quando o
# requisito apareceu (REQUISITOS, PROSE p/ Notas/Histórico, ou o próprio nome).
gram_scan_reqs() {
  local FILE="${1:-}"
  [ -f "$FILE" ] || return 0
  awk '
    function flush(   ) { if (in_req) printf "%s\t%d\t%d\t%s\n", name, rl, hs, sec }
    BEGIN { in_req=0; sec="NONE" }
    /^## Requisitos[[:space:]]*$/ { flush(); in_req=0; sec="REQUISITOS"; next }
    /^## / {
      flush(); in_req=0
      if ($0 ~ /^## (Notas|Notes|Historial|Histórico)/) sec="PROSE"
      else { sec=$0; sub(/^## */,"",sec) }
      next
    }
    /^### Requisito:/ {
      flush()
      name=$0; sub(/^### Requisito: */,"",name)
      rl=NR; hs=0; in_req=1
      next
    }
    in_req && /^#### / { hs=1 }
    END { flush() }
  ' "$FILE"
}

# End of spec-grammar.sh — sourced once per shell via __IDEIAOS_SPEC_GRAMMAR_LOADED
