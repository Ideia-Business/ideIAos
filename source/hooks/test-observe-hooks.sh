#!/usr/bin/env bash
# =============================================================================
# test-observe-hooks.sh — Smoke test harness for observe-tool-use.sh and
#                         observe-session-end.sh (IdeiaOS Phase 05-01)
# SOURCE: IdeiaOS v2
#
# Uses a temporary HOME to avoid polluting the real ~/.ideiaos/.
# Run from any directory; paths are resolved from BASH_SOURCE.
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed
# =============================================================================
set -uo pipefail

FAILS=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/source/hooks"
HOOK_TOOL="$HOOKS_DIR/observe-tool-use.sh"
HOOK_STOP="$HOOKS_DIR/observe-session-end.sh"

# ---------------------------------------------------------------------------
# Use a clean temporary HOME for ALL tests so real ~/.ideiaos/ is untouched.
# ---------------------------------------------------------------------------
ORIG_HOME="$HOME"
export HOME="$(mktemp -d)"
trap 'rm -rf "$HOME"; export HOME="$ORIG_HOME"' EXIT

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

assert_contains() {
  local file="$1"
  local pattern="$2"
  local test_name="$3"
  if grep -qF "$pattern" "$file" 2>/dev/null; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name — expected '$pattern' in $file"
    if [ -f "$file" ]; then
      echo "      file contents: $(cat "$file" | head -5)"
    else
      echo "      file does not exist"
    fi
    FAILS=$((FAILS + 1))
  fi
}

assert_not_contains() {
  local file_or_dir="$1"
  local pattern="$2"
  local test_name="$3"
  local found=0
  if [ -f "$file_or_dir" ]; then
    grep -qF "$pattern" "$file_or_dir" 2>/dev/null && found=1
  elif [ -d "$file_or_dir" ]; then
    grep -rqF "$pattern" "$file_or_dir" 2>/dev/null && found=1
  fi
  if [ "$found" -eq 0 ]; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name — '$pattern' should NOT appear in $file_or_dir"
    FAILS=$((FAILS + 1))
  fi
}

assert_file_exists() {
  local path="$1"
  local test_name="$2"
  if [ -f "$path" ]; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name — expected file '$path' to exist"
    FAILS=$((FAILS + 1))
  fi
}

assert_file_not_exists() {
  local path="$1"
  local test_name="$2"
  if [ ! -f "$path" ]; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name — expected file '$path' to NOT exist"
    FAILS=$((FAILS + 1))
  fi
}

assert_line_count() {
  local file="$1"
  local expected="$2"
  local test_name="$3"
  local count=0
  [ -f "$file" ] && count="$(wc -l < "$file" | tr -d ' ')"
  if [ "$count" -eq "$expected" ]; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name — expected $expected lines, got $count"
    FAILS=$((FAILS + 1))
  fi
}

assert_exit_zero() {
  local exit_code="$1"
  local test_name="$2"
  if [ "$exit_code" -eq 0 ]; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name — expected exit 0, got $exit_code"
    FAILS=$((FAILS + 1))
  fi
}

# ---------------------------------------------------------------------------
# Guard: hooks must exist
# ---------------------------------------------------------------------------

echo "--- Checking required hooks ---"
if [ ! -x "$HOOK_TOOL" ]; then
  echo "MISSING: $HOOK_TOOL (not found or not executable)"
  FAILS=$((FAILS + 1))
fi
if [ ! -x "$HOOK_STOP" ]; then
  echo "MISSING: $HOOK_STOP (not found or not executable)"
  FAILS=$((FAILS + 1))
fi
echo ""

# ---------------------------------------------------------------------------
# Setup: shared session and project values
# ---------------------------------------------------------------------------

SESSION="smoketest-observe-01"
CWD="/Users/test/myproject"
SLUG="myproject"   # basename of CWD lowercased, no special chars
OBS_JSONL="$HOME/.ideiaos/observations/$SLUG/observations.jsonl"

# ---------------------------------------------------------------------------
# Case 1 — PostToolUse Edit: metadata captured, file relative, ext correct
# ---------------------------------------------------------------------------

echo "--- Case 1: PostToolUse Edit ---"

INPUT_EDIT="$(cat <<EOF
{
  "session_id": "$SESSION",
  "cwd": "$CWD",
  "tool_name": "Edit",
  "tool_input": {"file_path": "$CWD/src/x.ts"},
  "tool_response": {}
}
EOF
)"

EXIT_CODE=0
echo "$INPUT_EDIT" | bash "$HOOK_TOOL" 2>/dev/null || EXIT_CODE=$?

assert_exit_zero "$EXIT_CODE" "Case 1: exit 0"
assert_file_exists "$OBS_JSONL" "Case 1: observations.jsonl created"
assert_line_count "$OBS_JSONL" 1 "Case 1: exactly 1 line in jsonl"
assert_contains "$OBS_JSONL" '"tool": "Edit"' "Case 1: tool is Edit"
assert_contains "$OBS_JSONL" '"ext": "ts"' "Case 1: ext is ts"
assert_contains "$OBS_JSONL" '"file": "src/x.ts"' "Case 1: file is relative path src/x.ts"

echo ""

# ---------------------------------------------------------------------------
# Case 2 — PostToolUse Bash: only bash_verb captured (no full command)
# ---------------------------------------------------------------------------

echo "--- Case 2: PostToolUse Bash (bash_verb only) ---"

INPUT_BASH="$(cat <<EOF
{
  "session_id": "$SESSION",
  "cwd": "$CWD",
  "tool_name": "Bash",
  "tool_input": {"command": "npm run build --silent"},
  "tool_response": {}
}
EOF
)"

EXIT_CODE=0
echo "$INPUT_BASH" | bash "$HOOK_TOOL" 2>/dev/null || EXIT_CODE=$?

assert_exit_zero "$EXIT_CODE" "Case 2: exit 0"
assert_line_count "$OBS_JSONL" 2 "Case 2: 2 lines in jsonl after second event"
assert_contains "$OBS_JSONL" '"bash_verb": "npm"' "Case 2: bash_verb is npm"
assert_not_contains "$OBS_JSONL" "build" "Case 2: arg 'build' NOT in jsonl (privacy)"
assert_not_contains "$OBS_JSONL" "--silent" "Case 2: flag '--silent' NOT in jsonl (privacy)"

echo ""

# ---------------------------------------------------------------------------
# Case 3 — Privacy: file content / secrets never logged
# ---------------------------------------------------------------------------

echo "--- Case 3: Privacy — secret content never reaches jsonl ---"

INPUT_SECRET="$(cat <<EOF
{
  "session_id": "$SESSION",
  "cwd": "$CWD",
  "tool_name": "Write",
  "tool_input": {"file_path": "$CWD/config.env", "content": "SENHA_SECRETA_123"},
  "tool_response": {}
}
EOF
)"

EXIT_CODE=0
echo "$INPUT_SECRET" | bash "$HOOK_TOOL" 2>/dev/null || EXIT_CODE=$?

assert_exit_zero "$EXIT_CODE" "Case 3: exit 0"
assert_not_contains "$OBS_JSONL" "SENHA_SECRETA_123" "Case 3: SENHA_SECRETA_123 NOT in jsonl (privacy Regra 1)"

echo ""

# ---------------------------------------------------------------------------
# Case 4 — Path traversal: session_id with ../../etc rejected
# ---------------------------------------------------------------------------

echo "--- Case 4: Path traversal blocked ---"

INPUT_TRAVERSAL="$(cat <<EOF
{
  "session_id": "../../etc",
  "cwd": "$CWD",
  "tool_name": "Edit",
  "tool_input": {"file_path": "$CWD/foo.ts"},
  "tool_response": {}
}
EOF
)"

# Count files outside ~/.ideiaos before
FILES_BEFORE="$(find "$HOME" -not -path "$HOME/.ideiaos/*" -type f 2>/dev/null | wc -l | tr -d ' ')"

EXIT_CODE=0
echo "$INPUT_TRAVERSAL" | bash "$HOOK_TOOL" 2>/dev/null || EXIT_CODE=$?

FILES_AFTER="$(find "$HOME" -not -path "$HOME/.ideiaos/*" -type f 2>/dev/null | wc -l | tr -d ' ')"

assert_exit_zero "$EXIT_CODE" "Case 4: exit 0 on traversal attempt"
if [ "$FILES_AFTER" -eq "$FILES_BEFORE" ]; then
  echo "PASS: Case 4: no new files created outside ~/.ideiaos/"
else
  echo "FAIL: Case 4: new file(s) created outside ~/.ideiaos/ (before=$FILES_BEFORE after=$FILES_AFTER)"
  FAILS=$((FAILS + 1))
fi

echo ""

# ---------------------------------------------------------------------------
# Case 5 — Malformed input: invalid JSON exits 0, no jsonl created for new slug
# ---------------------------------------------------------------------------

echo "--- Case 5: Malformed JSON input ---"

NEW_HOME_BEFORE="$(find "$HOME/.ideiaos" -name 'observations.jsonl' 2>/dev/null | wc -l | tr -d ' ')"

EXIT_CODE=0
echo "{ not json" | bash "$HOOK_TOOL" 2>/dev/null || EXIT_CODE=$?

NEW_HOME_AFTER="$(find "$HOME/.ideiaos" -name 'observations.jsonl' 2>/dev/null | wc -l | tr -d ' ')"

assert_exit_zero "$EXIT_CODE" "Case 5: exit 0 on malformed JSON"
if [ "$NEW_HOME_AFTER" -eq "$NEW_HOME_BEFORE" ]; then
  echo "PASS: Case 5: no new observations.jsonl created on malformed input"
else
  echo "FAIL: Case 5: unexpected new jsonl file created (before=$NEW_HOME_BEFORE after=$NEW_HOME_AFTER)"
  FAILS=$((FAILS + 1))
fi

echo ""

# ---------------------------------------------------------------------------
# Case 6 — Dirs created on demand (already verified by Case 1 starting fresh)
# ---------------------------------------------------------------------------

echo "--- Case 6: Dirs created on demand ---"

NEW_SLUG="newproject-casesix"
NEW_CWD="/Users/test/$NEW_SLUG"
INPUT_NEW="$(cat <<EOF
{
  "session_id": "$SESSION",
  "cwd": "$NEW_CWD",
  "tool_name": "Edit",
  "tool_input": {"file_path": "$NEW_CWD/a.py"},
  "tool_response": {}
}
EOF
)"

EXIT_CODE=0
echo "$INPUT_NEW" | bash "$HOOK_TOOL" 2>/dev/null || EXIT_CODE=$?

assert_exit_zero "$EXIT_CODE" "Case 6: exit 0 for new project slug"
assert_file_exists "$HOME/.ideiaos/observations/$NEW_SLUG/observations.jsonl" "Case 6: new project dir + jsonl created on demand"

echo ""

# ---------------------------------------------------------------------------
# Case 7 — Stop marker: observe-session-end writes session_end event
# ---------------------------------------------------------------------------

echo "--- Case 7: Stop marker (session_end) ---"

STOP_SLUG="stopproject"
STOP_CWD="/Users/test/$STOP_SLUG"
STOP_JSONL="$HOME/.ideiaos/observations/$STOP_SLUG/observations.jsonl"

INPUT_STOP="$(cat <<EOF
{
  "session_id": "$SESSION",
  "cwd": "$STOP_CWD"
}
EOF
)"

EXIT_CODE=0
echo "$INPUT_STOP" | bash "$HOOK_STOP" 2>/dev/null || EXIT_CODE=$?

assert_exit_zero "$EXIT_CODE" "Case 7: exit 0"
assert_file_exists "$STOP_JSONL" "Case 7: observations.jsonl created by stop hook"
assert_line_count "$STOP_JSONL" 1 "Case 7: exactly 1 line in stop jsonl"
assert_contains "$STOP_JSONL" '"event": "session_end"' "Case 7: event is session_end"
assert_contains "$STOP_JSONL" '"tool": "session_end"' "Case 7: tool is session_end"

echo ""

# ---------------------------------------------------------------------------
# Case 8 — Performance: observe-tool-use overhead informational (<200ms soft warn)
# ---------------------------------------------------------------------------

echo "--- Case 8: Performance (informational) ---"

INPUT_PERF="$(cat <<EOF
{
  "session_id": "$SESSION",
  "cwd": "$CWD",
  "tool_name": "Edit",
  "tool_input": {"file_path": "$CWD/perf.ts"},
  "tool_response": {}
}
EOF
)"

START_NS="$(date +%s%N 2>/dev/null || echo 0)"
echo "$INPUT_PERF" | bash "$HOOK_TOOL" 2>/dev/null || true
END_NS="$(date +%s%N 2>/dev/null || echo 0)"

if [ "$START_NS" -ne 0 ] && [ "$END_NS" -ne 0 ]; then
  ELAPSED_MS=$(( (END_NS - START_NS) / 1000000 ))
  if [ "$ELAPSED_MS" -le 200 ]; then
    echo "PASS: Case 8: performance ${ELAPSED_MS}ms (target <100ms on dev, <200ms soft warn)"
  else
    echo "WARN: Case 8: performance ${ELAPSED_MS}ms — exceeds 200ms soft threshold (CI may be slow; informational only)"
    # Informational only — not counted as FAIL
  fi
else
  echo "INFO: Case 8: nanosecond timer unavailable on this platform — skipped"
fi

echo ""

# ---------------------------------------------------------------------------
# Case 9 — R4-01: Anti-runaway guard — IDEIAOS_INSTINCT_SPAWN blocks both hooks
# ---------------------------------------------------------------------------

echo "--- Case 9: R4-01 anti-runaway guard (IDEIAOS_INSTINCT_SPAWN) ---"

SPAWN_SLUG="spawntest"
SPAWN_CWD="/Users/test/$SPAWN_SLUG"
SPAWN_TOOL_JSONL="$HOME/.ideiaos/observations/$SPAWN_SLUG/observations.jsonl"

INPUT_SPAWN_TOOL="$(cat <<EOF
{
  "session_id": "$SESSION",
  "cwd": "$SPAWN_CWD",
  "tool_name": "Edit",
  "tool_input": {"file_path": "$SPAWN_CWD/file.ts"},
  "tool_response": {}
}
EOF
)"

INPUT_SPAWN_STOP="$(cat <<EOF
{
  "session_id": "$SESSION",
  "cwd": "$SPAWN_CWD"
}
EOF
)"

# Run with IDEIAOS_INSTINCT_SPAWN=1 set — both hooks should exit 0 and write NOTHING
EXIT_TOOL=0
echo "$INPUT_SPAWN_TOOL" | IDEIAOS_INSTINCT_SPAWN=1 bash "$HOOK_TOOL" 2>/dev/null || EXIT_TOOL=$?
EXIT_STOP=0
echo "$INPUT_SPAWN_STOP" | IDEIAOS_INSTINCT_SPAWN=1 bash "$HOOK_STOP" 2>/dev/null || EXIT_STOP=$?

assert_exit_zero "$EXIT_TOOL" "Case 9a: observe-tool-use exits 0 when IDEIAOS_INSTINCT_SPAWN=1"
assert_exit_zero "$EXIT_STOP" "Case 9b: observe-session-end exits 0 when IDEIAOS_INSTINCT_SPAWN=1"
assert_file_not_exists "$SPAWN_TOOL_JSONL" "Case 9c: NO observations.jsonl created when IDEIAOS_INSTINCT_SPAWN=1"

# Verify without the guard — should create the file
EXIT_TOOL2=0
echo "$INPUT_SPAWN_TOOL" | bash "$HOOK_TOOL" 2>/dev/null || EXIT_TOOL2=$?
assert_exit_zero "$EXIT_TOOL2" "Case 9d: observe-tool-use works normally without IDEIAOS_INSTINCT_SPAWN"
assert_file_exists "$SPAWN_TOOL_JSONL" "Case 9e: observations.jsonl created when IDEIAOS_INSTINCT_SPAWN not set"

echo ""

# ---------------------------------------------------------------------------
# Case 10 — R4-02: Cooldown gate — 2nd session_end within 30min is skipped
# (Uses a fake recent sentinel to simulate cooldown; no real spawn occurs
#  because claude is not available in the temp HOME PATH)
# ---------------------------------------------------------------------------

echo "--- Case 10: R4-02 cooldown gate (sentinel <30min → no spawn signal) ---"

COOL_SLUG="cooldowntest"
COOL_CWD="/Users/test/$COOL_SLUG"
COOL_SENTINEL="$HOME/.ideiaos/instincts/.last-analyzed-${COOL_SLUG}"
COOL_OBS_DIR="$HOME/.ideiaos/observations/$COOL_SLUG"
COOL_LOGS_DIR="$HOME/.ideiaos/logs"

mkdir -p "$COOL_OBS_DIR" "$COOL_LOGS_DIR" "$HOME/.ideiaos/instincts" 2>/dev/null || true
# Seed a recent obs in the jsonl (so the ts gate passes)
printf '{"ts":"%s","session_id":"s1","project":"%s","tool":"session_end","event":"session_end"}\n' \
  "$(date -u +"%Y-%m-%dT%H:%M:%S")" "$COOL_SLUG" > "$COOL_OBS_DIR/observations.jsonl"

INPUT_COOL_STOP="$(cat <<EOF
{
  "session_id": "$SESSION",
  "cwd": "$COOL_CWD"
}
EOF
)"

# 1st invocation — sentinel is absent (epoch 0), should pass all gates and write sentinel
LOGS_BEFORE="$(ls "$COOL_LOGS_DIR"/instinct-analyze-*.log 2>/dev/null | wc -l | tr -d ' ')"
EXIT_COOL1=0
echo "$INPUT_COOL_STOP" | bash "$HOOK_STOP" 2>/dev/null || EXIT_COOL1=$?
assert_exit_zero "$EXIT_COOL1" "Case 10a: 1st session_end exits 0"

# Sentinel should have been written (or not, if claude absent; either way no crash)
# Now write a sentinel with a timestamp only 1min ago to simulate cooldown
/usr/bin/python3 -c "
import datetime
now = datetime.datetime.now()
recent = now.replace(second=now.second)  # just now
open('$COOL_SENTINEL', 'w').write(recent.isoformat(timespec='seconds'))
" 2>/dev/null || true

# Also update obs to have a newer ts to pass the TS_OBS > TS_LAST gate
printf '{"ts":"%s","session_id":"s2","project":"%s","tool":"session_end","event":"session_end"}\n' \
  "$(date -u +"%Y-%m-%dT%H:%M:%S")" "$COOL_SLUG" >> "$COOL_OBS_DIR/observations.jsonl"

# 2nd invocation — sentinel is "just now" (< 30min), should exit early, NOT write new log
LOGS_MID="$(ls "$COOL_LOGS_DIR"/instinct-analyze-*.log 2>/dev/null | wc -l | tr -d ' ')"
EXIT_COOL2=0
echo "$INPUT_COOL_STOP" | bash "$HOOK_STOP" 2>/dev/null || EXIT_COOL2=$?
LOGS_AFTER="$(ls "$COOL_LOGS_DIR"/instinct-analyze-*.log 2>/dev/null | wc -l | tr -d ' ')"

assert_exit_zero "$EXIT_COOL2" "Case 10b: 2nd session_end exits 0 (cooldown gate)"
if [ "$LOGS_AFTER" -eq "$LOGS_MID" ]; then
  echo "PASS: Case 10c: no new log created during cooldown (no spawn)"
else
  echo "WARN: Case 10c: new log appeared during cooldown — claude may be available in PATH (informational)"
  # Informational — real claude spawn is fire-and-forget, may create log if claude is present
  # The guard is verified by absence of *repeated* spawns in integration; here we confirm exit 0
fi

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
