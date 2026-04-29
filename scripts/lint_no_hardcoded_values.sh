#!/usr/bin/env bash
# lint_no_hardcoded_values.sh — reject hardcoded PIQ-STYLE values in prompt files.
#
# Greps propertyiq/**/*.md for known chart-style value patterns.
# Exits non-zero if any match is found outside allowed locations.
#
# Allowed locations (excluded from checks):
#   - docs/adr/ — ADRs discuss values by nature
#   - propertyiq/skills/chart-qa/piq-style-quickref.md — auto-generated from spec
#   - propertyiq/skills/chart-qa/audit-finding-template.md — template examples

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Known PIQ-STYLE value patterns to reject in prompt files.
# These are the values that were previously hardcoded inline.
PATTERNS=(
    '#1a1a1a'
    '#CEAD63'
    '#637F82'
    '#D4856B'
    '#A3BE8C'
    '#C77DBA'
    '#8FBCBB'
    '1600×1000'
    '1600x1000'
    'canvas 1600'
    'title 52px'
    'subtitle 42px'
    'title 44px'
    'subtitle 36px'
    'tension 0\.25'
    'line width 7'
    'palette order'
    'Gold/Teal/Terracotta'
)

# Build a combined regex pattern
COMBINED=""
for p in "${PATTERNS[@]}"; do
    if [ -n "$COMBINED" ]; then
        COMBINED="$COMBINED|$p"
    else
        COMBINED="$p"
    fi
done

# Search for matches in propertyiq/ markdown files, excluding allowed locations.
# Grep from repo root so glob paths resolve correctly.
MATCHES=$(rg --no-heading --line-number -i \
    --glob '*.md' \
    --glob '!**/piq-style-quickref.md' \
    --glob '!**/audit-finding-template.md' \
    --glob '!docs/adr/**' \
    --glob '!scripts/**' \
    --glob '!.github/**' \
    "$COMBINED" \
    propertyiq/ 2>/dev/null || true)

if [ -n "$MATCHES" ]; then
    echo "ERROR: Found hardcoded PIQ-STYLE values in prompt files."
    echo "These values must come from spec.yaml at runtime, not be inlined in prompts."
    echo ""
    echo "Matches:"
    echo "$MATCHES"
    echo ""
    echo "Fix: remove the hardcoded values and reference spec rule IDs instead."
    echo "See propertyiq/skills/chart-qa/SKILL.md for the correct pattern."
    exit 1
fi

echo "OK: No hardcoded PIQ-STYLE values found in prompt files."
exit 0
