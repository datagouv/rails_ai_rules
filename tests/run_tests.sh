#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DUMMY_APP="$REPO_ROOT/tests/dummy_app"
DUMMY_SETTINGS="$DUMMY_APP/.claude/settings.json"
DUMMY_SETTINGS_ORIG="$DUMMY_SETTINGS.orig"

passed=0
failed=0

pass() {
  echo "  PASS: $1"
  passed=$((passed + 1))
}

fail() {
  echo "  FAIL: $1"
  failed=$((failed + 1))
}

setup() {
  rm -rf "$DUMMY_APP/rails_ai_rules"
  rm -f "$DUMMY_APP/.codexpolicy"
  cp "$DUMMY_SETTINGS_ORIG" "$DUMMY_SETTINGS"
  ln -s "$REPO_ROOT" "$DUMMY_APP/rails_ai_rules"
}

EXPECTED_DENY_COUNT=$(jq '.permissions.deny | length' "$REPO_ROOT/settings.json")
EXISTING_DENY_COUNT=$(jq '.permissions.deny | length' "$DUMMY_SETTINGS")
MERGED_DENY_COUNT=$((EXPECTED_DENY_COUNT + EXISTING_DENY_COUNT))

# Save original settings
cp "$DUMMY_SETTINGS" "$DUMMY_SETTINGS_ORIG"

setup

echo "=== Test 1: Merge into existing settings ==="

"$DUMMY_APP/rails_ai_rules/install.sh" > /dev/null

deny_count=$(jq '.permissions.deny | length' "$DUMMY_SETTINGS")
if [ "$deny_count" -eq "$MERGED_DENY_COUNT" ]; then
  pass "$MERGED_DENY_COUNT deny rules ($EXPECTED_DENY_COUNT ours + $EXISTING_DENY_COUNT existing)"
else
  fail "expected $MERGED_DENY_COUNT deny rules, got $deny_count"
fi

has_custom=$(jq '.permissions.deny | index("Bash(rm -rf /*)")' "$DUMMY_SETTINGS")
if [ "$has_custom" != "null" ]; then
  pass "existing deny rule preserved"
else
  fail "existing deny rule lost"
fi

has_allow=$(jq -r '.permissions.allow[0]' "$DUMMY_SETTINGS")
if [ "$has_allow" = "Bash(bundle exec rspec:*)" ]; then
  pass "existing allow rules preserved"
else
  fail "existing allow rules lost: $has_allow"
fi

echo ""
echo "=== Test 2: Idempotence (run install twice) ==="

"$DUMMY_APP/rails_ai_rules/install.sh" > /dev/null

deny_count=$(jq '.permissions.deny | length' "$DUMMY_SETTINGS")
if [ "$deny_count" -eq "$MERGED_DENY_COUNT" ]; then
  pass "still $MERGED_DENY_COUNT deny rules (no duplicates)"
else
  fail "expected $MERGED_DENY_COUNT deny rules after 2nd install, got $deny_count"
fi

echo ""
echo "=== Test 3: Fresh install (no existing settings) ==="

setup
rm -f "$DUMMY_SETTINGS"

"$DUMMY_APP/rails_ai_rules/install.sh" > /dev/null

if [ -f "$DUMMY_SETTINGS" ]; then
  pass "settings.json created"
else
  fail "settings.json not created"
fi

deny_count=$(jq '.permissions.deny | length' "$DUMMY_SETTINGS")
if [ "$deny_count" -eq "$EXPECTED_DENY_COUNT" ]; then
  pass "$EXPECTED_DENY_COUNT deny rules present"
else
  fail "expected $EXPECTED_DENY_COUNT deny rules, got $deny_count"
fi

echo ""
echo "=== Test 4: Codex .codexpolicy installed ==="

setup

"$DUMMY_APP/rails_ai_rules/install.sh" > /dev/null

if [ -f "$DUMMY_APP/.codexpolicy" ]; then
  pass ".codexpolicy created"
else
  fail ".codexpolicy not created"
fi

if grep -q 'decision = "forbidden"' "$DUMMY_APP/.codexpolicy"; then
  pass ".codexpolicy contains forbidden rules"
else
  fail ".codexpolicy missing forbidden rules"
fi

echo ""
echo "=== Test 5: Codex .codexpolicy not overwritten ==="

echo "# custom policy" > "$DUMMY_APP/.codexpolicy"

"$DUMMY_APP/rails_ai_rules/install.sh" > /dev/null

if grep -q "# custom policy" "$DUMMY_APP/.codexpolicy"; then
  pass "existing .codexpolicy preserved"
else
  fail "existing .codexpolicy overwritten"
fi

echo ""

# Restore original settings
cp "$DUMMY_SETTINGS_ORIG" "$DUMMY_SETTINGS"
rm -f "$DUMMY_SETTINGS_ORIG"
rm -f "$DUMMY_APP/.codexpolicy"
rm -rf "$DUMMY_APP/rails_ai_rules"

echo "=== Results: $passed passed, $failed failed ==="

if [ "$failed" -gt 0 ]; then
  exit 1
fi
