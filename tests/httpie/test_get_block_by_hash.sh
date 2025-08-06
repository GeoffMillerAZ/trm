#!/usr/bin/env bash
set -euo pipefail

# Test suite for get_block_by_hash endpoint

# Load environment if --env is provided
if [[ $# -gt 0 && "$1" == "--env" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
    source "${SCRIPT_DIR}/load_env.sh" "$2"
fi

# Use environment variables or defaults
API_HOST="${API_HOST:-http://localhost:8000}"
API_TIMEOUT="${API_TIMEOUT:-30}"
API_VERSION="${API_VERSION:-v1}"

# Test data
VALID_BLOCK_HASH="${VALID_BLOCK_HASH:-0x88e96d4537bea4d9c05d12549907b32561d3bf31f45aae734cdc119f13406cb6}"
NON_EXISTENT_BLOCK_HASH="${NON_EXISTENT_BLOCK_HASH:-0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcd}"
INVALID_BLOCK_HASH="${INVALID_BLOCK_HASH:-0x12345}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
pass() {
    echo -e "${GREEN}✓ $1${NC}"
}

fail() {
    echo -e "${RED}✗ $1${NC}"
}

header() {
    echo -e "${YELLOW}$1${NC}"
}

# Test case: Successfully retrieve a block
test_get_block_success() {
    header "Test: Successfully retrieve block $VALID_BLOCK_HASH"

    # Make the request
    http --check-status --timeout="$API_TIMEOUT" GET "$API_HOST/api/$API_VERSION/block/$VALID_BLOCK_HASH" \
        Accept:application/json

    # Add assertions here if needed, e.g., using jq
    # For now, --check-status is the main assertion

    pass "Successfully retrieved block"
}

# Test case: Block not found
test_get_block_not_found() {
    header "Test: Block not found for hash $NON_EXISTENT_BLOCK_HASH"

    # Make the request and expect a 404
    response_code=$(http --print=h --ignore-stdin --timeout="$API_TIMEOUT" GET "$API_HOST/api/$API_VERSION/block/$NON_EXISTENT_BLOCK_HASH" \
        Accept:application/json 2>&1 | grep "^HTTP" | cut -d' ' -f2)

    if [[ "$response_code" == "404" ]]; then
        pass "Correctly returned 404 for non-existent block"
    else
        fail "Expected 404 but got $response_code for non-existent block"
        return 1
    fi
}

# Test case: Invalid block hash format
test_get_block_invalid_hash() {
    header "Test: Invalid block hash format $INVALID_BLOCK_HASH"

    # Make the request and expect a 400 or 422
    response_code=$(http --print=h --ignore-stdin --timeout="$API_TIMEOUT" GET "$API_HOST/api/$API_VERSION/block/$INVALID_BLOCK_HASH" \
        Accept:application/json 2>&1 | grep "^HTTP" | cut -d' ' -f2)

    if [[ "$response_code" == "400" || "$response_code" == "422" ]]; then
        pass "Correctly returned $response_code for invalid block hash"
    else
        fail "Expected 400 or 422 but got $response_code for invalid block hash"
        return 1
    fi
}

# Run all tests
echo "Running Get Block by Hash tests..."
echo

test_get_block_success
test_get_block_not_found
test_get_block_invalid_hash

echo
echo "Get Block by Hash tests completed."
