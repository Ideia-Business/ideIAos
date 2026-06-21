#!/usr/bin/env bash
# SOURCE: IdeiaOS v2 | tests for capability tool-output-compressor
# Binary exit-code gate (antifragile-gates): 0 = contract satisfied, 1 = fail.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
LIB="$ROOT/source/skills/tool-output-compressor/lib"
PY="$LIB/toc_compress.py"
export TOC_STORE="$(mktemp -d 2>/dev/null || echo /tmp/toc-store-test)"
fails=0
ok(){ echo "  ok: $1"; }
bad(){ echo "  FAIL: $1" >&2; fails=$((fails+1)); }

echo "== tool-output-compressor gate =="

# 1. core self-test (12 internal checks)
if python3 "$PY" self-test >/dev/null 2>&1; then ok "core self-test (12 checks)"; else bad "core self-test"; fi

# 2. CLI: user role passthrough byte-identical
msg="refatore o pagamento por favor"
out="$(printf '%s' "$msg" | bash "$LIB/toc.sh" compress --role user)"
[ "$out" = "$msg" ] && ok "user passthrough byte-identical" || bad "user passthrough"

# 3. CLI: log compresses + reversible marker + retrieve round-trip
logf="$(mktemp)"; for i in $(seq 1 200); do echo "2026-06-21T01:00:00Z INFO worker[$((i%4))] batch=512 ok lat=$((100+i%30))"; done > "$logf"
res="$(bash "$LIB/toc.sh" compress --role tool --json < "$logf")"
h="$(printf '%s' "$res" | python3 -c 'import sys,json; print(json.load(sys.stdin)["sha256"] or "")')"
red="$(printf '%s' "$res" | python3 -c 'import sys,json; print(json.load(sys.stdin)["reduction_pct"])')"
python3 -c "import sys; sys.exit(0 if float('$red')>50 else 1)" && ok "log reduction ${red}% (>50)" || bad "log reduction ${red}%"
rf="$(mktemp)"; bash "$LIB/toc.sh" retrieve --hash "$h" > "$rf"
[ "$(shasum -a 256 < "$rf" | awk '{print $1}')" = "$h" ] && ok "retrieve round-trip sha256" || bad "retrieve round-trip"
rm -f "$rf" 2>/dev/null

# 4. retrieve miss is explicit non-zero (not silent)
if bash "$LIB/toc.sh" retrieve --hash "$(printf '0%.0s' {1..64})" >/dev/null 2>&1; then bad "miss should be non-zero"; else ok "retrieve miss -> non-zero exit"; fi

# 5. fail-open: simulate python3 absent but coreutils present (realistic)
TMPD="$(mktemp -d)"
for b in cat env bash printf dirname; do s=$(command -v "$b"); [ -n "$s" ] && ln -sf "$s" "$TMPD/$b"; done
fo="$(printf 'hello tool output' | PATH="$TMPD" bash "$LIB/toc.sh" compress 2>/dev/null)"
[ "$fo" = "hello tool output" ] && ok "fail-open passthrough (no python3)" || bad "fail-open passthrough (got: $fo)"
rm -rf "$TMPD" 2>/dev/null

rm -rf "$TOC_STORE" "$logf" 2>/dev/null
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$fails FAILED"; exit 1; fi
