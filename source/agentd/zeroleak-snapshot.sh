#!/usr/bin/env bash
# SOURCE: IdeiaOS v14 | kind: gate | targets: claude,cursor
# =============================================================================
# zeroleak-snapshot.sh — Gate Zero-Leak: varre snapshot contra padrões de segredo
#
# Uso:
#   bash source/agentd/zeroleak-snapshot.sh <path_do_snapshot.json>
#
# Exit 0 = 0 matches (snapshot seguro — nenhum valor de segredo detectado)
# Exit 1 = 1+ matches (release BLOQUEADO — segredo detectado no snapshot)
#
# Padrões (source-of-truth deste arquivo — literais embutidos abaixo):
#   sk-   : sk-[A-Za-z0-9_-]{16,}  (Anthropic/OpenAI keys)
#   gho_  : gho_[A-Za-z0-9]{20,}   (GitHub OAuth tokens)
#   JWT   : eyJ[A-Za-z0-9_-]{20,}\.eyJ  (JWT header+2o segmento — exige AMBOS)
#           (o SUPABASE_SERVICE_ROLE_KEY é um JWT, então o padrão DEVE exigir os
#            DOIS segmentos eyJ...\.eyJ para não falso-positivo no 1o segmento)
#   role  : "role"\s*:\s*"service_role"  (value-shape em JSON plaintext)
#           (NUNCA casa o NOME de var SUPABASE_SERVICE_ROLE_KEY — é o valor JSON)
#   hex40 : [0-9a-f]{41,} | [0-9A-F]{41,}  (token/hash hex com >40 chars)
#           (machine_id=12 hex, supabase_project_id~20 chars — sem falso-positivo)
#
# NOTA (A-01, escopo v14.0): detector é REGEX-only (sem camada de entropia/allowlist).
# Nenhum campo legítimo do SHAPE v1 casa esses padrões:
#   - machine_id=12 hex (abaixo de 41)
#   - supabase_project_id é base32-ish ~20 chars (abaixo de 41, não hex puro)
#   - var_name "SUPABASE_SERVICE_ROLE_KEY" não casa "role":"service_role" (é nome, não valor)
# =============================================================================
set -euo pipefail

SNAP="${1:-}"
if [ -z "$SNAP" ]; then
  echo '[zeroleak] uso: zeroleak-snapshot.sh <path_do_snapshot.json>' >&2
  exit 2
fi

if ! test -s "$SNAP" 2>/dev/null; then
  echo "[zeroleak] arquivo não encontrado ou vazio: $SNAP" >&2
  exit 2
fi

TOTAL=0

# Função auxiliar: varrer arquivo contra regex ERE, imprimir matches
# Retorna o número de matches encontrados
scan_pattern() {
  local label="$1"
  local pattern="$2"
  local count
  count=$(grep -cEo "$pattern" "$SNAP" 2>/dev/null || true)
  if [ "$count" -gt 0 ]; then
    echo "[zeroleak] DETECTADO [$label]: $count match(es) — RELEASE BLOQUEADO" >&2
  fi
  echo "$count"
}

# Padrão 1: sk- keys (Anthropic/OpenAI API keys)
CNT=$(scan_pattern "sk-key" 'sk-[A-Za-z0-9_-]{16,}')
TOTAL=$((TOTAL + CNT))

# Padrão 2: GitHub OAuth tokens
CNT=$(scan_pattern "gho_token" 'gho_[A-Za-z0-9]{20,}')
TOTAL=$((TOTAL + CNT))

# Padrão 3: JWT completo (header + ponto + 2o segmento)
# DEVE exigir os DOIS segmentos: eyJ...\.eyJ
# Cobre SUPABASE_SERVICE_ROLE_KEY que é um JWT HS256
CNT=$(scan_pattern "jwt-two-seg" 'eyJ[A-Za-z0-9_-]{20,}\.eyJ')
TOTAL=$((TOTAL + CNT))

# Padrão 4: service_role como VALUE em JSON plaintext
# Casa: "role":"service_role", "role" : "service_role", "role":  "service_role"
# NÃO casa: SUPABASE_SERVICE_ROLE_KEY (é nome de variável, não value-shape)
CNT=$(scan_pattern "service_role-value" '"role"[[:space:]]*:[[:space:]]*"service_role"')
TOTAL=$((TOTAL + CNT))

# Padrão 5: hex com >40 chars (token/hash de 41+ chars em hex puro)
# machine_id=12 hex (abaixo do limiar); supabase_project_id é base32-ish (não hex puro)
CNT=$(scan_pattern "hex40plus" '[0-9a-f]{41,}|[0-9A-F]{41,}')
TOTAL=$((TOTAL + CNT))

# Resultado
if [ "$TOTAL" -gt 0 ]; then
  echo "[zeroleak] FAIL: $TOTAL padrão(ões) de segredo detectado(s) no snapshot" >&2
  exit 1
fi

echo "[zeroleak] OK: 0 padrões de segredo detectados — snapshot seguro"
exit 0
