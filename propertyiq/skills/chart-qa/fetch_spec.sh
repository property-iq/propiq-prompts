#!/usr/bin/env bash
# fetch_spec.sh — vendor charts spec at audit time, via authenticated gh api.
#
# Called from the chart-qa skill before any chart evaluation.
# Authenticates as the `propiq-pm` user via GH_CONFIG_DIR, which is the
# same auth path PM uses for every other gh invocation.
#
# Inputs:  none.
# Outputs: $WORKSPACE_TMP/charts-spec/{spec.yaml, tokens.yaml,
#          resolve_token_refs.py, spec-resolved.yaml, spec-manifest.txt}.
# Exit:    non-zero on any fetch or resolve failure.
#
# CRITICAL: callers MUST treat non-zero exit as an abort signal. Never
# fall back to memorized values. Report the failure to Martin verbatim.
# Falling back is exactly the drift mode this whole architecture exists
# to prevent.
#
# Why gh api and not anonymous curl: propiq-docs is a private repo on a
# personal GitHub account, so raw.githubusercontent.com returns 404 for
# anonymous requests. gh api goes through the authenticated REST endpoint
# (GET /repos/{owner}/{repo}/contents/{path}), which returns base64-
# encoded content for files. We pipe through `--jq .content | base64 -d`
# to materialize the file.

set -euo pipefail

WORKSPACE_TMP="${WORKSPACE_TMP:-/Users/agent/.openclaw/workspace/agents/propertyiq/tmp}"
GH_CONFIG_DIR="${GH_CONFIG_DIR:-/Users/agent/.config/gh-propiq-pm}"
export GH_CONFIG_DIR

REPO="property-iq/propiq-docs"
REF="main"

# Paths within propiq-docs to fetch. Adjust here only — never inline in
# the loop body. If propiq-docs reorganizes these, only this block needs
# to change.
SPEC_PATH="charts/spec.yaml"
TOKENS_PATH="tokens.yaml"
RESOLVER_PATH="scripts/resolve_token_refs.py"

OUT_DIR="$WORKSPACE_TMP/charts-spec"
mkdir -p "$OUT_DIR"

# Helper: fetch one file from the repo and write it to disk.
fetch_one() {
    local repo_path="$1" local_name="$2"
    gh api "repos/${REPO}/contents/${repo_path}?ref=${REF}" \
        --jq '.content' \
      | base64 -d \
      > "${OUT_DIR}/${local_name}"

    # Sanity: a successful gh api call followed by base64 decode of an
    # empty .content yields an empty file. Treat that as failure.
    if [ ! -s "${OUT_DIR}/${local_name}" ]; then
        echo "fetch_spec: empty content for ${repo_path}" >&2
        return 1
    fi
}

fetch_one "$SPEC_PATH"     "spec.yaml"
fetch_one "$TOKENS_PATH"   "tokens.yaml"
fetch_one "$RESOLVER_PATH" "resolve_token_refs.py"

# Capture the timestamp BEFORE the Python heredoc — inside <<'PY' shell
# does not expand $(...) and Python doesn't interpret it either, so env
# is the only path that works.
FETCHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
export FETCHED_AT
export OUT_DIR

# Resolve $tokens references and write the merged spec.
# Assumes propiq-docs/scripts/resolve_token_refs.py exposes
# load_spec_resolved(spec_path, tokens_path) -> dict.
# If that contract changes upstream, this script must change in lockstep
# — there is no defensive shim, on purpose. Failures here mean the
# architecture has shifted and a human needs to look.
python3 - <<'PY'
import os
import sys

out_dir = os.environ["OUT_DIR"]
sys.path.insert(0, out_dir)

try:
    from resolve_token_refs import load_spec_resolved
except ImportError as e:
    sys.stderr.write(f"fetch_spec: failed to import resolver: {e}\n")
    sys.exit(2)

import yaml

spec = load_spec_resolved(
    os.path.join(out_dir, "spec.yaml"),
    os.path.join(out_dir, "tokens.yaml"),
)

with open(os.path.join(out_dir, "spec-resolved.yaml"), "w") as f:
    yaml.safe_dump(spec, f, sort_keys=False)

# Manifest so the agent can cite the spec_version it audited against.
fetched_at = os.environ.get("FETCHED_AT", "unknown")
with open(os.path.join(out_dir, "spec-manifest.txt"), "w") as f:
    f.write(f"spec_version: {spec.get('spec_version', 'unknown')}\n")
    f.write(f"fetched_at: {fetched_at}\n")
PY

# Final stdout: the absolute path to the resolved spec. Skill consumers
# capture this for the rest of the audit.
echo "${OUT_DIR}/spec-resolved.yaml"
