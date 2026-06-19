#!/usr/bin/env bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v11
# =============================================================================
# spec-grammar.sh — MOTOR de gramática COMPARTILHADO da delta-spec (ponto único)
#
# A convenção de marcação das specs (header de requisito, cenário 4-hashtags,
# tokens de seção de delta, zona de contrato `## Requisitos`, fences ```)
# vive AQUI, uma vez. Os clientes (spec-analyze.sh, spec-converge.sh) consomem
# as DUAS funções-motor abaixo — nenhum reimplementa a gramática inline
# (cf. learning declarative-vs-imperative-drift; a 1ª versão derivou e a
# verificação adversarial wf_99173505 pegou — esta versão é a correção).
#
# NÃO refatora spec-validate.sh/spec-merge.sh (gates existentes, verdes); o motor
# é desenhado para essa unificação ser trivial depois.
#
# Sem efeitos colaterais. Bash 3.2 (sem nameref/assoc-array). Sourcear, não exec.
# =============================================================================
[ -n "${__IDEIAOS_SPEC_GRAMMAR_LOADED:-}" ] && return 0
__IDEIAOS_SPEC_GRAMMAR_LOADED=1

# Tokens de seção de delta (constante única; o merge CONSOME estes, nunca os emite
# na fonte — vê-los na spec viva = delta colado à mão). Usada por gram_grep_delta_tokens.
GRAM_DELTA_SECTION_ALT='adicionado|added|modificado|modified|removido|removed|renomeado|renamed'

# ── gram_scan_reqs FILE → motor por-requisito (TSV, 5 campos) ─────────────────
# Emite uma linha por '### Requisito:' encontrado FORA de fences:
#   NAME <TAB> LINE <TAB> HAS_SCENARIO(0|1) <TAB> HAS_MISLEVEL(0|1) <TAB> SECTION
# • SECTION   = heading '## ' ativo: REQUISITOS (zona de contrato), PROSE
#               (Notas/Notes/Historial/Histórico), o próprio nome, ou NONE.
# • HAS_SCENARIO = 1 se há '#### ' (cenário no nível CERTO) dentro do bloco.
# • HAS_MISLEVEL = 1 se há cenário em nível ERRADO (###, #####, ######) no bloco.
# • Fence-aware: nada dentro de ``` … ``` é interpretado (exemplos em prosa não
#   disparam falso-positivo — bug pego pela verificação adversarial).
# Fronteira de bloco = '^## ' ou '^### Requisito:' (a mesma provada no merge).
gram_scan_reqs() {
  local FILE="${1:-}"
  [ -f "$FILE" ] || return 0
  awk '
    function flush(   ) { if (in_req) printf "%s\t%d\t%d\t%d\t%s\n", name, rl, hs, mis, sec }
    BEGIN { in_req=0; sec="NONE"; fence=0 }
    /^```/ { fence = !fence; next }
    fence { next }
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
      rl=NR; hs=0; mis=0; in_req=1
      next
    }
    in_req && /^#### / { hs=1 }
    in_req && /^(###|#####|######) ([Cc]en|[Ss]cen)/ { mis=1 }
    END { flush() }
  ' "$FILE"
}

# ── gram_grep_delta_tokens FILE → "LINE:TEXT" de tokens de delta vazados ───────
# Headings '## <token-de-delta>' FORA de fences, case-INSENSITIVE (o merge emite
# em maiúsculas, mas um humano cola em qualquer caixa). Vazio = nenhum.
gram_grep_delta_tokens() {
  local FILE="${1:-}"
  [ -f "$FILE" ] || return 0
  awk -v alt="$GRAM_DELTA_SECTION_ALT" '
    BEGIN { fence=0 }
    /^```/ { fence = !fence; next }
    fence { next }
    /^## / { l=tolower($0); if (l ~ ("^## (" alt ")")) printf "%d:%s\n", NR, $0 }
  ' "$FILE"
}

# End of spec-grammar.sh — sourced once via __IDEIAOS_SPEC_GRAMMAR_LOADED
