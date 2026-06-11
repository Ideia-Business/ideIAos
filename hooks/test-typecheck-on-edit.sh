#!/usr/bin/env bash
# =============================================================================
# test-typecheck-on-edit.sh — Smoke tests para typecheck-on-edit.sh
#
# TDD RED phase: define the expected behavior before implementation.
# Run: bash hooks/test-typecheck-on-edit.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/typecheck-on-edit.sh"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== typecheck-on-edit.sh smoke tests ==="
echo ""

# --------------------------------------------------------------------------
# Test 1: Non-.ts file generates exit 0 silently
# --------------------------------------------------------------------------
echo "Test 1: Non-.ts file (e.g., .md) exits 0 silently"
OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.md"},"cwd":"/tmp","session_id":"t"}' \
  | bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ] && [ -z "$OUT" ]; then
  pass "non-.md exits 0, no stdout"
else
  fail "expected exit 0 + empty stdout, got exit=$EXIT_CODE output='$OUT'"
fi

# --------------------------------------------------------------------------
# Test 2: .ts file in directory without tsc exits 0 silently (Pitfall 1)
# --------------------------------------------------------------------------
echo "Test 2: .ts file in dir without tsc exits 0 silently"
TMPDIR_NOTSC=$(mktemp -d)
OUT=$(echo "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$TMPDIR_NOTSC/foo.ts\"},\"cwd\":\"$TMPDIR_NOTSC\",\"session_id\":\"t\"}" \
  | bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ] && [ -z "$OUT" ]; then
  pass ".ts without tsc exits 0, no stdout"
else
  fail "expected exit 0 + empty, got exit=$EXIT_CODE output='$OUT'"
fi
rm -rf "$TMPDIR_NOTSC"

# --------------------------------------------------------------------------
# Test 3: Script contains node_modules/.bin/tsc detection (acceptance criteria)
# --------------------------------------------------------------------------
echo "Test 3: Script detects node_modules/.bin/tsc"
if grep -q "node_modules/.bin/tsc" "$HOOK" 2>/dev/null; then
  pass "node_modules/.bin/tsc present in script"
else
  fail "node_modules/.bin/tsc NOT found in script"
fi

# --------------------------------------------------------------------------
# Test 4: Script contains --noEmit flag (acceptance criteria)
# --------------------------------------------------------------------------
echo "Test 4: Script uses --noEmit"
if grep -q "noEmit" "$HOOK" 2>/dev/null; then
  pass "--noEmit present in script"
else
  fail "--noEmit NOT found in script"
fi

# --------------------------------------------------------------------------
# Test 5: Script uses python3 json.dumps for safe JSON serialization (acceptance criteria)
# --------------------------------------------------------------------------
echo "Test 5: Script uses python3 json.dumps for safe serialization"
if grep -q "json.dumps" "$HOOK" 2>/dev/null; then
  pass "json.dumps present in script"
else
  fail "json.dumps NOT found in script"
fi

# --------------------------------------------------------------------------
# Test 6: Script contains case *.ts|*.tsx pattern
# --------------------------------------------------------------------------
echo "Test 6: Script has *.ts|*.tsx case pattern"
if grep -qE "\*\.ts\|\*\.tsx|\*\.tsx\|\*\.ts" "$HOOK" 2>/dev/null; then
  pass "*.ts|*.tsx case present"
else
  fail "*.ts|*.tsx case NOT found in script"
fi

# --------------------------------------------------------------------------
# Test 7: Script uses exit 2 for asyncRewake contract
# --------------------------------------------------------------------------
echo "Test 7: Script uses exit 2 (asyncRewake contract)"
if grep -q "exit 2" "$HOOK" 2>/dev/null; then
  pass "exit 2 present in script"
else
  fail "exit 2 NOT found in script"
fi

# --------------------------------------------------------------------------
# Test 8: .tsx file in directory without tsc also exits 0 silently
# --------------------------------------------------------------------------
echo "Test 8: .tsx file in dir without tsc exits 0 silently"
TMPDIR_NOTSC2=$(mktemp -d)
OUT=$(echo "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$TMPDIR_NOTSC2/comp.tsx\"},\"cwd\":\"$TMPDIR_NOTSC2\",\"session_id\":\"t\"}" \
  | bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ] && [ -z "$OUT" ]; then
  pass ".tsx without tsc exits 0, no stdout"
else
  fail "expected exit 0 + empty, got exit=$EXIT_CODE output='$OUT'"
fi
rm -rf "$TMPDIR_NOTSC2"

# --------------------------------------------------------------------------
# Test 9: .js file exits 0 silently (not a TS file)
# --------------------------------------------------------------------------
echo "Test 9: .js file exits 0 silently"
OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/app.js"},"cwd":"/tmp","session_id":"t"}' \
  | bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ] && [ -z "$OUT" ]; then
  pass ".js exits 0, no stdout"
else
  fail "expected exit 0 + empty stdout, got exit=$EXIT_CODE output='$OUT'"
fi

# --------------------------------------------------------------------------
# Test 10: Empty file_path exits 0 silently
# --------------------------------------------------------------------------
echo "Test 10: Empty file_path exits 0 silently"
OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":""},"cwd":"/tmp","session_id":"t"}' \
  | bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ]; then
  pass "empty file_path exits 0"
else
  fail "expected exit 0, got exit=$EXIT_CODE output='$OUT'"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
