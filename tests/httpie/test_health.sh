#!/bin/bash
set -euo pipefail

# Health Check Tests using HTTPie
# These tests verify the health endpoints are working correctly
# Usage: ./test_health.sh [--env ENV_FILE]

# Load environment if --env is provided
if [[ $# -gt 0 && "$1" == "--env" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
    source "${SCRIPT_DIR}/load_env.sh" "$2"
fi

# Use environment variables or defaults
API_HOST="${API_HOST:-http://localhost:8000}"
API_TIMEOUT="${API_TIMEOUT:-30}"
API_VERSION="${API_VERSION:-v1}"
VERBOSE_OUTPUT="${VERBOSE_OUTPUT:-false}"

# Set HTTPie options based on configuration
HTTP_OPTS=()
if [[ "$VERBOSE_OUTPUT" == "true" ]]; then
    HTTP_OPTS+=(--verbose)
fi
HTTP_OPTS+=(--timeout="$API_TIMEOUT")

echo "=== Health Check Tests ==="
echo "API: $API_HOST"
echo

echo "1. Basic Health Check"
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/health" Accept:application/json
echo

echo "2. Detailed Health Check (if available)"
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/health/detailed" Accept:application/json || echo "Detailed endpoint not available"
echo

echo "3. Health Check with Custom Headers"
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/health" Accept:application/json User-Agent:"TRM-Test-Client/1.0"
echo

echo "=== All health checks completed ==="
