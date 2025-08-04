#!/bin/bash
set -euo pipefail

# Edge Case Tests using HTTPie
# Tests for error handling and edge cases
# Usage: ./test_edge_cases.sh [--env ENV_FILE]

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
VITALIK="${VITALIK_ADDRESS:-0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045}"

# Set HTTPie options based on configuration
HTTP_OPTS=()
if [[ "$VERBOSE_OUTPUT" == "true" ]]; then
    HTTP_OPTS+=(--verbose)
fi
HTTP_OPTS+=(--timeout="$API_TIMEOUT")

echo "=== Edge Case Tests ==="
echo "API: $API_HOST"
echo

echo "1. Invalid Address - Wrong Format (should return 400)"
http "${HTTP_OPTS[@]}" --check-status GET "$API_HOST/api/$API_VERSION/address/0xinvalid/balance" Accept:application/json || echo "Expected failure: $?"
echo

echo "2. Invalid Address - Not Hex (should return 400)"
http "${HTTP_OPTS[@]}" --check-status GET "$API_HOST/api/$API_VERSION/address/not-an-address/balance" Accept:application/json || echo "Expected failure: $?"
echo

echo "3. Invalid Address - Too Short (should return 400)"
http "${HTTP_OPTS[@]}" --check-status GET "$API_HOST/api/$API_VERSION/address/0x123/balance" Accept:application/json || echo "Expected failure: $?"
echo

echo "4. Invalid Address - Too Long (should return 400)"
http "${HTTP_OPTS[@]}" --check-status GET "$API_HOST/api/$API_VERSION/address/0x00000000219ab540356cBB839Cbe05303d7705FaXXXX/balance" Accept:application/json || echo "Expected failure: $?"
echo

echo "5. Invalid Address - Missing 0x Prefix (should return 400)"
http "${HTTP_OPTS[@]}" --check-status GET "$API_HOST/api/$API_VERSION/address/00000000219ab540356cBB839Cbe05303d7705Fa/balance" Accept:application/json || echo "Expected failure: $?"
echo

echo "6. Empty Address (should return 404 or 400)"
http "${HTTP_OPTS[@]}" --check-status GET "$API_HOST/api/$API_VERSION/address//balance" Accept:application/json || echo "Expected failure: $?"
echo

echo "7. Special Characters in Address (should return 400)"
http "${HTTP_OPTS[@]}" --check-status GET "$API_HOST/api/$API_VERSION/address/0x<script>alert('xss')</script>/balance" Accept:application/json || echo "Expected failure: $?"
echo

echo "8. SQL Injection Attempt (should be safely handled)"
http "${HTTP_OPTS[@]}" --check-status GET "$API_HOST/api/$API_VERSION/address/0x'; DROP TABLE users; --/balance" Accept:application/json || echo "Expected failure: $?"
echo

echo "9. Maximum Balance Address (should handle extremely large numbers)"
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF/balance" Accept:application/json
echo

echo "10. Non-Existent Endpoint (should return 404)"
http "${HTTP_OPTS[@]}" --check-status GET "$API_HOST/api/$API_VERSION/health/nonexistent" Accept:application/json || echo "Expected failure: $?"
echo

echo "11. Wrong HTTP Method (should return 405)"
echo '{"test":"data"}' | http "${HTTP_OPTS[@]}" --check-status POST "$API_HOST/api/$API_VERSION/address/$VITALIK/balance" Accept:application/json Content-Type:application/json || echo "Expected failure: $?"
echo

echo "12. Large Request Headers"
# Create a large header value
LARGE_HEADER=$(printf 'A%.0s' {1..1000})
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/$VITALIK/balance" Accept:application/json X-Large-Header:"$LARGE_HEADER"
echo

echo "=== All edge case tests completed ==="
