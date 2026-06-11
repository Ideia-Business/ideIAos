#!/usr/bin/env bash
# Smoke test harness for IdeiaOS quality-memory hooks (phase 01).
# Run from the root of the IdeiaOS repository.
#
# Usage:
#   bash hooks/test-hooks.sh
#
# Exit codes:
#   0 — all required tests passed
#   1 — one or more required tests failed (or required hook missing)

set -uo pipefail

FAILS=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/hooks"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

assert_contains() {
  local output="$1"
  local expected="$2"
  local test_name="$3"
  if echo "$output" | grep -qF "$expected"; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name — expected to contain: '$expected'"
    echo "      got: $(echo "$output" | head -3)"
    FAILS=$((FAILS + 1))
  fi
}

assert_empty() {
  local output="$1"
  local test_name="$2"
  if [ -z "$output" ]; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name — expected empty output"
    echo "      got: $(echo "$output" | head -3)"
    FAILS=$((FAILS + 1))
  fi
}

require_hook() {
  local hook="$1"
  local hook_path="$HOOKS_DIR/$hook"
  if [ ! -f "$hook_path" ]; then
    echo "MISSING HOOK: $hook — this hook is required by plan 01-01 but was not found"
    FAILS=$((FAILS + 1))
    return 1
  fi
  return 0
}

skip_hook() {
  local hook="$1"
  echo "SKIP: $hook (hook not yet created — will be tested in a later plan)"
}

# ---------------------------------------------------------------------------
# Guard: required hooks for this plan must exist
# ---------------------------------------------------------------------------

echo "--- Checking required hooks ---"
require_hook "console-log-guard.sh" || true
require_hook "strategic-compact.sh" || true
echo ""

# ---------------------------------------------------------------------------
# Section 1: console-log-guard.sh
# ---------------------------------------------------------------------------

echo "--- console-log-guard.sh ---"

HOOK_CLG="$HOOKS_DIR/console-log-guard.sh"
if [ -f "$HOOK_CLG" ]; then
  # Test 1a: file with console.log produces warning
  printf 'const x = 1;\nconsole.log("debug", x);\nconst y = 2;\n' > /tmp/clg-test.ts
  OUT_CLG_WARN="$(echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/clg-test.ts"},"cwd":"/tmp","session_id":"smoketest-clg"}' \
    | bash "$HOOK_CLG" 2>/dev/null)"
  assert_contains "$OUT_CLG_WARN" "console.log" "console-log-guard: dirty .ts file emits warning containing 'console.log'"

  # Test 1b: clean file produces no output
  printf 'const x = 1;\nconst y = 2;\n' > /tmp/clg-clean.ts
  OUT_CLG_CLEAN="$(echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/clg-clean.ts"},"cwd":"/tmp","session_id":"smoketest-clg"}' \
    | bash "$HOOK_CLG" 2>/dev/null)"
  assert_empty "$OUT_CLG_CLEAN" "console-log-guard: clean .ts file produces no output"

  # Test 1c: non-TS extension is silently ignored
  printf 'console.log("y")\n' > /tmp/clg-test.py
  OUT_CLG_PY="$(echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/clg-test.py"},"cwd":"/tmp","session_id":"smoketest-clg"}' \
    | bash "$HOOK_CLG" 2>/dev/null)"
  assert_empty "$OUT_CLG_PY" "console-log-guard: .py file is ignored (not a JS/TS file)"

  # Test 1d: empty file_path exits silently
  OUT_CLG_EMPTY="$(echo '{"tool_name":"Edit","tool_input":{"file_path":""},"cwd":"/tmp","session_id":"smoketest-clg"}' \
    | bash "$HOOK_CLG" 2>/dev/null)"
  assert_empty "$OUT_CLG_EMPTY" "console-log-guard: empty file_path produces no output"

  # Cleanup
  rm -f /tmp/clg-test.ts /tmp/clg-clean.ts /tmp/clg-test.py
else
  echo "FAIL: console-log-guard.sh missing — skipping section tests (counted as FAIL above)"
fi

echo ""

# ---------------------------------------------------------------------------
# Section 2: strategic-compact.sh
# ---------------------------------------------------------------------------

echo "--- strategic-compact.sh ---"

HOOK_SC="$HOOKS_DIR/strategic-compact.sh"
# Session ID for smoke testing — used in counter file /tmp/claude-compact-counter-smoketest-sc.json
SESSION_SC="smoketest-sc"
COUNTER_FILE_SC="/tmp/claude-compact-counter-smoketest-sc.json"

if [ -f "$HOOK_SC" ]; then
  # Reset state
  rm -f "$COUNTER_FILE_SC"

  # Test 2a: first call produces no output
  OUT_SC_FIRST="$(echo "{\"session_id\":\"${SESSION_SC}\",\"tool_name\":\"Read\"}" \
    | bash "$HOOK_SC" 2>/dev/null)"
  assert_empty "$OUT_SC_FIRST" "strategic-compact: 1st call produces no output"

  # Test 2b: calls 2-49 are silent — just run them without capturing each output
  for i in $(seq 2 49); do
    echo "{\"session_id\":\"${SESSION_SC}\",\"tool_name\":\"Read\"}" \
      | bash "$HOOK_SC" > /dev/null 2>&1
  done

  # Test 2c: 50th call emits /compact suggestion
  OUT_SC_50="$(echo "{\"session_id\":\"${SESSION_SC}\",\"tool_name\":\"Read\"}" \
    | bash "$HOOK_SC" 2>/dev/null)"
  assert_contains "$OUT_SC_50" "/compact" "strategic-compact: 50th call emits /compact suggestion"

  # Test 2d: path traversal in session_id is rejected silently
  OUT_SC_TRAV="$(echo '{"session_id":"../evil","tool_name":"Read"}' \
    | bash "$HOOK_SC" 2>/dev/null)"
  assert_empty "$OUT_SC_TRAV" "strategic-compact: path traversal session_id rejected silently"

  # Test 2e: empty session_id exits silently
  OUT_SC_EMPTY_SID="$(echo '{"session_id":"","tool_name":"Read"}' \
    | bash "$HOOK_SC" 2>/dev/null)"
  assert_empty "$OUT_SC_EMPTY_SID" "strategic-compact: empty session_id exits silently"

  # Cleanup
  rm -f "$COUNTER_FILE_SC"
else
  echo "FAIL: strategic-compact.sh missing — skipping section tests (counted as FAIL above)"
fi

echo ""

# ---------------------------------------------------------------------------
# Section 3: hooks from later plans (SKIP if absent)
# ---------------------------------------------------------------------------

echo "--- Hooks from later plans (SKIP if absent) ---"
for later_hook in "precompact-state-save.sh" "session-summary.sh" "typecheck-on-edit.sh"; do
  if [ -f "$HOOKS_DIR/$later_hook" ]; then
    echo "PRESENT: $later_hook — skipping smoke test (tested in its own plan)"
  else
    skip_hook "$later_hook"
  fi
done

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo "--- Results ---"
if [ "$FAILS" -gt 0 ]; then
  echo "FAILED: $FAILS test(s) failed"
  exit 1
else
  echo "ALL TESTS PASSED"
  exit 0
fi
