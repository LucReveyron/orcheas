#!/usr/bin/env bash
# test_install.sh
# Tests install.sh (dry-run), orcheas init, and orcheas clean.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

assert_exit() {
  local label="$1" expected="$2"
  shift 2
  local code=0; "$@" >/dev/null 2>&1 || code=$?
  if [[ "$code" -eq "$expected" ]]; then
    echo "  PASS: $label"; (( PASS++ )) || true
  else
    echo "  FAIL: $label (expected exit $expected, got $code)"; (( FAIL++ )) || true
  fi
}

assert_contains() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == *"$expected"* ]]; then
    echo "  PASS: $label"; (( PASS++ )) || true
  else
    echo "  FAIL: $label — expected to contain: $expected"; (( FAIL++ )) || true
  fi
}

assert_file() {
  local label="$1" path="$2"
  if [[ -f "$path" ]]; then
    echo "  PASS: $label"; (( PASS++ )) || true
  else
    echo "  FAIL: $label — missing file: $path"; (( FAIL++ )) || true
  fi
}

echo "── install.sh (dry-run) ─────────────────"

assert_exit "dry-run exits 0" 0 "$SCRIPT_DIR/install.sh" --dry-run

dry_output=$("$SCRIPT_DIR/install.sh" --dry-run 2>&1)
assert_contains "targets ~/.local/share/orcheas" ".local/share/orcheas" "$dry_output"
assert_contains "copies orcheas CLI"             "orcheas"               "$dry_output"
assert_contains "copies templates"               "templates"             "$dry_output"
assert_contains "references shell function"      "shell function"        "$dry_output"

if [[ "$dry_output" == *"/.claude"* ]]; then
  echo "  FAIL: output references ~/.claude — should not touch it"
  (( FAIL++ )) || true
else
  echo "  PASS: does not reference ~/.claude"
  (( PASS++ )) || true
fi

echo ""
echo "── orcheas init ─────────────────────────"

TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

"$SCRIPT_DIR/orcheas" init "$TMP_PROJECT" >/dev/null 2>&1

assert_file "creates CLAUDE.md"               "$TMP_PROJECT/CLAUDE.md"
assert_file "creates vault/core/goal.md"      "$TMP_PROJECT/vault/core/goal.md"
assert_file "creates vault/core/rules.md"     "$TMP_PROJECT/vault/core/rules.md"
assert_file "creates vault/core/routine.md"   "$TMP_PROJECT/vault/core/routine.md"
assert_file "creates vault/active/todo.md"    "$TMP_PROJECT/vault/active/todo.md"
assert_file "creates vault/active/summary.md" "$TMP_PROJECT/vault/active/summary.md"
assert_file "creates vault/memories/log.md"   "$TMP_PROJECT/vault/memories/log.md"

assert_exit "init is idempotent" 0 "$SCRIPT_DIR/orcheas" init "$TMP_PROJECT"

echo ""
echo "── orcheas clean ────────────────────────"

echo "dirty" >> "$TMP_PROJECT/vault/active/todo.md"
echo "# extra" > "$TMP_PROJECT/vault/memories/extra.md"

"$SCRIPT_DIR/orcheas" clean "$TMP_PROJECT/vault" >/dev/null 2>&1

grep -q "dirty" "$TMP_PROJECT/vault/active/todo.md" 2>/dev/null \
  && { echo "  FAIL: todo.md was not reset"; (( FAIL++ )) || true; } \
  || { echo "  PASS: todo.md reset"; (( PASS++ )) || true; }

[[ -f "$TMP_PROJECT/vault/memories/extra.md" ]] \
  && { echo "  FAIL: extra memory not removed"; (( FAIL++ )) || true; } \
  || { echo "  PASS: memories/ cleaned"; (( PASS++ )) || true; }

assert_file "log.md re-created after clean"      "$TMP_PROJECT/vault/memories/log.md"
assert_file "core/goal.md untouched after clean" "$TMP_PROJECT/vault/core/goal.md"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
