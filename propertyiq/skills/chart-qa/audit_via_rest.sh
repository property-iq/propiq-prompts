#!/usr/bin/env bash
# audit_via_rest.sh — call POST /charts/audit and emit the result.
#
# Phase E (Multi-layer chart audit, design §4 Phase E item 2). REST-first
# audit path that doesn't require a screenshot. The Playwright + dual-
# viewport flow is preserved for Layer 2b vision audits and full-surface
# (page-level) audits — see SKILL.md.
#
# Inputs:
#   stdin — JSON request body. Either:
#     {"config": {...Chart.js config...}, "intent": "trend", "mode": "web"}
#   or:
#     {"render_request": {...ChartRequest...}}
#
# Flags:
#   --no-vision      Force REST-only synchronous path under 1 second.
#                    Layers: existence, layout, style. Default.
#   --include-image  Include Layer 2b vision audit (renders + uploads PNG;
#                    expect ~3-8 seconds). Layers: existence, layout, style,
#                    visual.
#   --layers CSV     Override the layer list explicitly. Comma-separated,
#                    e.g. --layers existence,style. Wins over --no-vision /
#                    --include-image.
#   --url URL        Override charts-api base URL. Default reads
#                    $CHARTS_API_URL or falls back to the production URL.
#   --output PATH    Write the full JSON response to PATH (in addition to
#                    stdout). Useful when capturing in $WORKSPACE_TMP.
#
# Outputs:
#   stdout — the AuditResult JSON from POST /charts/audit (always emitted,
#            even on non-zero exit, so the caller can introspect violations).
#   stderr — diagnostic messages.
#
# Exit codes:
#   0 — audit completed and passed:true (zero error-severity violations).
#   1 — audit completed but passed:false (violations present).
#   2 — request failed (HTTP error, bad input, network failure).
#
# Auth:
#   Uses $CHARTS_AUDIT_TOKEN as a bearer token if set (matches the
#   MCP_TOKEN_* convention from gap analysis Cat C). When unset, sends
#   no Authorization header — fine if charts-api doesn't enforce auth on
#   /charts/audit yet.

set -euo pipefail

DEFAULT_URL="https://propiq-charts-api-429012647952.me-central1.run.app"
CHARTS_URL="${CHARTS_API_URL:-$DEFAULT_URL}"

LAYERS_DEFAULT="existence,layout,style"
LAYERS_WITH_VISION="existence,layout,style,visual"
LAYERS=""

OUTPUT_PATH=""
LAYER_OVERRIDE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --no-vision)
            LAYERS="$LAYERS_DEFAULT"
            shift
            ;;
        --include-image)
            LAYERS="$LAYERS_WITH_VISION"
            shift
            ;;
        --layers)
            LAYER_OVERRIDE="$2"
            shift 2
            ;;
        --url)
            CHARTS_URL="$2"
            shift 2
            ;;
        --output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -50
            exit 0
            ;;
        *)
            echo "audit_via_rest: unknown flag: $1" >&2
            exit 2
            ;;
    esac
done

# Layer resolution: explicit override wins. Otherwise use --no-vision /
# --include-image. Otherwise default to no-vision (sub-second path).
if [ -n "$LAYER_OVERRIDE" ]; then
    LAYERS="$LAYER_OVERRIDE"
elif [ -z "$LAYERS" ]; then
    LAYERS="$LAYERS_DEFAULT"
fi

# Read stdin into a temp file so we can validate it's JSON before sending.
INPUT_FILE="$(mktemp)"
trap 'rm -f "$INPUT_FILE"' EXIT
cat > "$INPUT_FILE"

if [ ! -s "$INPUT_FILE" ]; then
    echo "audit_via_rest: empty stdin — pass a JSON request body" >&2
    exit 2
fi

# Validate stdin is JSON. jq is the standard tool here; if missing, fail
# loudly rather than sending a malformed body.
if ! command -v jq >/dev/null 2>&1; then
    echo "audit_via_rest: jq is required (used for stdin validation)" >&2
    exit 2
fi

if ! jq empty "$INPUT_FILE" >/dev/null 2>&1; then
    echo "audit_via_rest: stdin is not valid JSON" >&2
    exit 2
fi

# Inject layers into the body. The route accepts layers as a body field;
# preserve every other field the caller passed.
LAYERS_JSON_ARRAY="$(printf '%s' "$LAYERS" \
    | tr ',' '\n' \
    | jq -R . \
    | jq -s .)"

REQUEST_BODY="$(jq --argjson layers "$LAYERS_JSON_ARRAY" '. + {layers: $layers}' "$INPUT_FILE")"

# Build curl invocation. Bearer token only when the env var is set.
CURL_AUTH=()
if [ -n "${CHARTS_AUDIT_TOKEN:-}" ]; then
    CURL_AUTH=(-H "Authorization: Bearer $CHARTS_AUDIT_TOKEN")
fi

RESPONSE_FILE="$(mktemp)"
trap 'rm -f "$INPUT_FILE" "$RESPONSE_FILE"' EXIT

HTTP_STATUS="$(curl -sS \
    -X POST \
    -H "Content-Type: application/json" \
    "${CURL_AUTH[@]}" \
    -o "$RESPONSE_FILE" \
    -w "%{http_code}" \
    --max-time 30 \
    "$CHARTS_URL/charts/audit" \
    --data-binary "$REQUEST_BODY" \
    || echo "0")"

if [ "$HTTP_STATUS" = "0" ]; then
    echo "audit_via_rest: network failure calling $CHARTS_URL/charts/audit" >&2
    cat "$RESPONSE_FILE" >&2 || true
    exit 2
fi

if [ "$HTTP_STATUS" -ge 400 ]; then
    echo "audit_via_rest: HTTP $HTTP_STATUS from $CHARTS_URL/charts/audit" >&2
    cat "$RESPONSE_FILE" >&2 || true
    exit 2
fi

# Always emit the response on stdout.
cat "$RESPONSE_FILE"

# Optionally also write it to a file (callers commonly want this in
# $WORKSPACE_TMP for downstream Issue-filing).
if [ -n "$OUTPUT_PATH" ]; then
    cp "$RESPONSE_FILE" "$OUTPUT_PATH"
fi

# Exit 0 iff passed:true. Anything else (including missing field) → 1.
PASSED="$(jq -r '.passed // false' "$RESPONSE_FILE")"
if [ "$PASSED" = "true" ]; then
    exit 0
fi
exit 1
