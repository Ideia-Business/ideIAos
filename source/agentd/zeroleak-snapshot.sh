#!/usr/bin/env bash
# SOURCE: IdeiaOS v14.1 | kind: gate | targets: claude,cursor
# =============================================================================
# zeroleak-snapshot.sh — Gate Zero-Leak: varre qualquer superfície (S1–S7 do
# cockpit) contra padrões de segredo, com DETECTOR DE DUAS CAMADAS.
#
# Uso:
#   bash source/agentd/zeroleak-snapshot.sh <path_do_arquivo_materializado>
#
# Exit 0 = 0 matches (superfície segura — nenhum valor de segredo detectado)
# Exit 1 = 1+ matches (release BLOQUEADO — segredo detectado)
# Exit 2 = erro de argumento (arquivo ausente/vazio)
#
# DETECTOR v14.1 (doc 78 §1.2) — DUAS CAMADAS, ambas exit-code:
#
#   (a) REGEX de chaves literais conhecidas (source-of-truth — literais abaixo):
#       sk-   : sk-[A-Za-z0-9_-]{16,}        (Anthropic/OpenAI/DeepSeek/OpenRouter)
#       gho_  : gho_[A-Za-z0-9]{20,}         (GitHub OAuth tokens)
#       JWT   : eyJ[A-Za-z0-9_-]{20,}\.eyJ   (JWT header+2o segmento — exige AMBOS;
#               o SUPABASE_SERVICE_ROLE_KEY é um JWT HS256)
#       role  : "role"\s*:\s*"service_role"  (value-shape em JSON plaintext)
#       hex40 : [0-9a-f]{41,} | [0-9A-F]{41,} (token/hash hex com >40 chars)
#
#   (b) ENTROPIA DE SHANNON por token (bash/awk puro, sem dep externa): qualquer
#       string >=20 chars com entropia de Shannon >=4.0 bits/char é SUSPEITA —
#       captura chaves NOVAS de alta-entropia que a regex (a) ainda não conhece.
#       ALLOWLIST por NOME/SHAPE (NUNCA por valor) — exclui o que é legitimamente
#       alto-entropia e público (doc 78 §1.2 anti-falso-positivo):
#         - machine_id            (sha256[:12] de hardware-uuid — doc 73 §1)
#         - input_hash            (sha256 de handoff — context-packet R6-12)
#         - supabase_project_id   (ref público base32-ish ~20 chars — doc 73 §6)
#         - SHAs de commit        (40-hex em contexto de hash/ref/design-suite)
#         - hashes de audit-log   (cadeia encadeada — sha256)
#         - tokens URL/path-shape (contêm //, .git, github.com — remote_url etc.)
#       A allowlist é por NOME do campo JSON e por SHAPE estrutural — nunca lista
#       um valor real (credential-isolation: valor de segredo nunca no contexto).
#
# Sem essa allowlist o detector reprovaria o PRÓPRIO snapshot legítimo (remote
# URLs e refs de design-suite somam >=4.0 bits/char). Falso-positivo zero nos
# campos do SHAPE v1. (Substitui a NOTA A-01 "regex-only" do v14.0.)
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

# =============================================================================
# CAMADA (b) — ENTROPIA DE SHANNON + ALLOWLIST por NOME/SHAPE (doc 78 §1.2)
# -----------------------------------------------------------------------------
# Para cada token candidato (>=20 chars de [A-Za-z0-9_+/=.-]): computa a entropia
# de Shannon (awk puro, sem dep) e flaga se >=4.0 — A MENOS que o token seja
# legítimo por SHAPE (allowlist por forma, NUNCA por valor):
#   - URL/path: contém // ou .git ou github.com (remote_url etc. — alto-entropia legítimo)
#   - SHA de commit / design-suite ref: 40-hex puro (entropia ~3.8, mas garantido)
#   - sha256 (machine_id[:12]=12-hex, input_hash/audit=64-hex): hex puro <=64
#   - supabase_project_id público: base32-ish curto (~20 chars)
# O limiar 4.0 (limiar=4.0 bits/char) já deixa passar 12-hex/40-hex/64-hex (todos
# < 4.0 por baixa cardinalidade do alfabeto hex). A allowlist por SHAPE protege os
# casos de fronteira (URLs/refs que misturam alfabetos). Nunca lista um valor real.
ENTROPY_THRESHOLD="4.0"   # >=4,0 bits/char => suspeito (Shannon)
# CANDIDATO = run de [A-Za-z0-9_-] (>=20 chars) — o SHAPE real de chave/token de
# API. NÃO inclui . : / = (separadores de código JS / path / URL): se incluísse,
# o bundle minificado do SPA mesclaria identificadores em pseudo-tokens de alta
# entropia (falso-positivo verificado: dangerouslySetInnerHTML, /assets/index-..).
ENTROPY_HITS=$(
  { grep -oE '[A-Za-z0-9_-]{20,}' "$SNAP" 2>/dev/null || true; } | awk -v THRESH="$ENTROPY_THRESHOLD" '
    function is_allowlisted_shape(tok,   _n) {
      # (1) URL/path-shape — remote_url, github.com, .git: legítimo público
      if (tok ~ /\/\//)            return 1
      if (tok ~ /\.git$/)          return 1
      if (tok ~ /github\.com/)     return 1
      # (2) hash hex puro (sha256 machine_id[:12]/input_hash 64-hex/audit, SHA de
      #     commit 40-hex): hex puro até 64 chars é shape de hash conhecido público,
      #     nunca chave de API. Por SHAPE (forma), nunca por valor específico.
      _n = length(tok)
      if (tok ~ /^[0-9a-f]+$/ && _n <= 64) return 1
      if (tok ~ /^[0-9A-F]+$/ && _n <= 64) return 1
      return 0
    }
    {
      tok = $0
      if (is_allowlisted_shape(tok)) next
      # SHAPE de segredo: chave/token random é DIGIT-BEARING (base62/hex aleatório).
      # Identificador de código (dangerouslySetInnerHTML, UNSAFE_componentWillMount)
      # é word-like SEM dígito — alto-entropia legítimo do bundle. Exigir >=1 dígito
      # separa segredo de identificador por SHAPE (não por valor). Verificado: 0
      # falso-positivo em S1/S2/S5/S7; veneno (10 dígitos) e sk- (14) seguem pegos.
      if (tok !~ /[0-9]/) next
      n = length(tok)
      delete freq
      for (i = 1; i <= n; i++) { c = substr(tok, i, 1); freq[c]++ }
      H = 0
      for (c in freq) { p = freq[c] / n; H -= p * (log(p) / log(2)) }
      if (H >= THRESH + 0.0) { printf "%.3f\t%s\n", H, tok }
    }
  ' | wc -l | tr -d ' '
)
if [ "${ENTROPY_HITS:-0}" -gt 0 ]; then
  echo "[zeroleak] DETECTADO [entropia-shannon>=${ENTROPY_THRESHOLD}]: $ENTROPY_HITS token(s) de alta entropia (allowlist por nome/shape aplicada) — RELEASE BLOQUEADO" >&2
  TOTAL=$((TOTAL + ENTROPY_HITS))
fi

# Resultado
if [ "$TOTAL" -gt 0 ]; then
  echo "[zeroleak] FAIL: $TOTAL padrão(ões)/token(s) de segredo detectado(s) na superfície" >&2
  exit 1
fi

echo "[zeroleak] OK: 0 padrões de segredo detectados — superfície segura (regex + entropia)"
exit 0
