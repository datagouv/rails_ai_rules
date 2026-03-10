#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_SETTINGS="$SCRIPT_DIR/settings.json"
TARGET_DIR="$PROJECT_DIR/.claude"
TARGET_SETTINGS="$TARGET_DIR/settings.json"

if [ ! -f "$PROJECT_DIR/Gemfile" ] || [ ! -d "$PROJECT_DIR/config" ]; then
  echo "Error: not a Rails project (missing Gemfile or config/)."
  echo "Run this script from within a Rails project where the submodule is installed."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  echo "Install it with: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

mkdir -p "$TARGET_DIR"

if [ ! -f "$TARGET_SETTINGS" ]; then
  cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
  echo "Created .claude/settings.json from rails_ai_rules/settings.json"
else
  MERGED=$(jq -s '
    (.[0].permissions.deny // []) + (.[1].permissions.deny // []) | unique
  ' "$TARGET_SETTINGS" "$SOURCE_SETTINGS") || {
    echo "Error: failed to merge deny rules."
    exit 1
  }

  jq --argjson deny "$MERGED" '.permissions.deny = $deny' "$TARGET_SETTINGS" > "$TARGET_SETTINGS.tmp" \
    && mv "$TARGET_SETTINGS.tmp" "$TARGET_SETTINGS"
  echo "Merged rails_ai_rules into existing .claude/settings.json"
fi

# Codex: install .codexpolicy
SOURCE_POLICY="$SCRIPT_DIR/codex.codexpolicy"
TARGET_POLICY="$PROJECT_DIR/.codexpolicy"

if [ ! -f "$TARGET_POLICY" ]; then
  cp "$SOURCE_POLICY" "$TARGET_POLICY"
  echo "Created .codexpolicy from rails_ai_rules/codex.codexpolicy"
else
  echo "Skipped .codexpolicy (already exists)"
fi

echo ""
echo "Done. Rails AI Rules installed:"
echo "  - Claude Code: deny rules in .claude/settings.json"
echo "  - Codex: exec policy in .codexpolicy"
