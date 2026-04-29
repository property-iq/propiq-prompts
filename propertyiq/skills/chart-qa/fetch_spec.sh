#!/usr/bin/env bash
# fetch_spec.sh — vendor charts spec at audit time.
# Called from chart-qa skill before any chart evaluation.
#
# Output: writes resolved spec to $WORKSPACE_TMP/charts-spec/spec-resolved.yaml
# Exit non-zero if any fetch fails — caller must abort the audit and
# report fetch failure to Martin verbatim. Never proceed with stale or
# missing spec.

set -euo pipefail

WORKSPACE_TMP="${WORKSPACE_TMP:-/Users/agent/.openclaw/workspace/agents/propertyiq/tmp}"
DOCS_BASE="https://raw.githubusercontent.com/property-iq/propiq-docs/main"

mkdir -p "$WORKSPACE_TMP/charts-spec"
cd "$WORKSPACE_TMP/charts-spec"

# Fetch spec, tokens, and resolver. --fail aborts on 4xx/5xx.
curl --fail --silent --show-error -o spec.yaml         "$DOCS_BASE/charts/spec.yaml"
curl --fail --silent --show-error -o tokens.yaml       "$DOCS_BASE/tokens.yaml"
curl --fail --silent --show-error -o resolve_token_refs.py "$DOCS_BASE/scripts/resolve_token_refs.py"

# Resolve $tokens references and write the merged spec + manifest.
python3 - <<'PY'
import sys, os
sys.path.insert(0, os.getcwd())
from resolve_token_refs import load_spec_resolved
import yaml
from datetime import datetime, timezone

spec = load_spec_resolved("spec.yaml", "tokens.yaml")
with open("spec-resolved.yaml", "w") as f:
    yaml.safe_dump(spec, f, sort_keys=False)

with open("spec-manifest.txt", "w") as f:
    f.write(f"spec_version: {spec.get('spec_version', 'unknown')}\n")
    f.write(f"fetched_at: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}\n")
PY

echo "$WORKSPACE_TMP/charts-spec/spec-resolved.yaml"
