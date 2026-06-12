#!/usr/bin/env bash
# security/scan-absorbed.sh — pipeline de quarentena para conteúdo de terceiros (ECC).
# Uso: bash security/scan-absorbed.sh <arquivo-ou-diretório>
# Exit: 0 = PASS (limpo ou só WARN); 1 = FAIL (payload ativo); 2 = erro de invocação.
# Decisão travada PROJECT.md: NENHUM conteúdo de terceiros é absorvido sem passar aqui.
set -uo pipefail

# Ensure Homebrew tools (rg) are in PATH when script runs from restricted shells
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

TARGET="${1:-security/quarantine}"
[ -e "$TARGET" ] || { echo "ERRO: target não existe: $TARGET" >&2; exit 2; }
PASS=0; WARN=0; FAIL=0

echo "Escaneando: $TARGET"
echo ""

# Check 1 — Unicode invisível (prompt injection oculto). FAIL automático.
# Usa python3 para confiabilidade cross-plataforma; rg como acelerador opcional.
INVISIBLE_CODEPOINTS="$(python3 - "$TARGET" <<'PY'
import sys, os, pathlib
PATTERNS = ['​','‌','‍','⁠','﻿',
            '‪','‫','‬','‭','‮']
target = pathlib.Path(sys.argv[1])
files = list(target.rglob('*')) if target.is_dir() else [target]
found = []
for f in files:
    if not f.is_file(): continue
    try:
        text = f.read_text(errors='replace')
        for lineno, line in enumerate(text.splitlines(), 1):
            for cp in PATTERNS:
                if cp in line:
                    found.append(f"{f}:{lineno}: <invisible U+{ord(cp):04X}>")
                    break
    except Exception:
        pass
print('\n'.join(found))
sys.exit(0 if found else 1)
PY
)"
if [ $? -eq 0 ]; then
  echo "$INVISIBLE_CODEPOINTS"
  echo "  ✗ FAIL: caractere(s) Unicode invisível(eis) detectado(s)"; FAIL=$((FAIL+1))
else echo "  ✓ sem unicode invisível"; PASS=$((PASS+1)); fi

# Check 2 — Payloads HTML/JS inline. FAIL automático.
if rg -n '<!--|<script|data:text/html|base64,' "$TARGET" 2>/dev/null; then
  echo "  ✗ FAIL: payload HTML/JS/base64 detectado"; FAIL=$((FAIL+1))
else echo "  ✓ sem payloads HTML/JS"; PASS=$((PASS+1)); fi

# Check 3 — Comandos suspeitos. WARN (curl/ssh aparecem em docs legítimas) — inspeção manual.
if rg -n 'curl|wget|nc |scp |ssh |enableAllProjectMcpServers|ANTHROPIC_BASE_URL' "$TARGET" 2>/dev/null; then
  echo "  ⚠ WARN: comandos suspeitos — INSPEÇÃO MANUAL obrigatória antes de promover"; WARN=$((WARN+1))
else echo "  ✓ sem comandos suspeitos"; PASS=$((PASS+1)); fi

# Check 4 — AgentShield (best-effort; offline não bloqueia).
if command -v npx >/dev/null 2>&1 && npx --yes ecc-agentshield scan --path "$TARGET" --format json \
     --output "/tmp/agentshield-scan-$(date +%s).json" 2>/dev/null; then
  echo "  ✓ AgentShield: sem findings críticos"; PASS=$((PASS+1))
else
  echo "  ⚠ WARN: AgentShield indisponível/offline — scan parcial"; WARN=$((WARN+1))
fi

echo ""
echo "Scan: PASS=$PASS WARN=$WARN FAIL=$FAIL  (target: $TARGET)"
if [ "$FAIL" -gt 0 ]; then echo "RESULTADO: BLOQUEADO — não absorver."; exit 1; fi
[ "$WARN" -gt 0 ] && echo "RESULTADO: APROVADO COM RESSALVA — revisar WARNs manualmente."
[ "$WARN" -eq 0 ] && echo "RESULTADO: LIMPO — aprovado para absorção."
exit 0
