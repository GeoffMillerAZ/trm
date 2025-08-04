#!/bin/bash
set -euo pipefail

# Balance Endpoint Tests using HTTPie
# Tests for the Ethereum address balance endpoint
# Usage: ./test_balance.sh [--env ENV_FILE]

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

# Test addresses from environment or defaults
ETH2_DEPOSIT="${ETH2_DEPOSIT_ADDRESS:-0x00000000219ab540356cBB839Cbe05303d7705Fa}"
VITALIK="${VITALIK_ADDRESS:-0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045}"
REGULAR_USER="${REGULAR_USER_ADDRESS:-0x742d35Cc6634C0532925a3b844Bc9e7595ED6fF5}"
EMPTY_WALLET="${EMPTY_WALLET_ADDRESS:-0x0000000000000000000000000000000000000000}"
DUST_AMOUNT="${DUST_AMOUNT_ADDRESS:-0x1234567890123456789012345678901234567890}"
WHALE="${WHALE_ADDRESS:-0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF}"

# Expected values for validation (if needed)
ETH2_EXPECTED="${ETH2_DEPOSIT_EXPECTED:-}"
VITALIK_EXPECTED="${VITALIK_EXPECTED:-}"
REGULAR_EXPECTED="${REGULAR_USER_EXPECTED:-}"
EMPTY_EXPECTED="${EMPTY_WALLET_EXPECTED:-0}"
WHALE_EXPECTED="${WHALE_EXPECTED:-}"

# Set HTTPie options based on configuration
HTTP_OPTS=()
if [[ "$VERBOSE_OUTPUT" == "true" ]]; then
    HTTP_OPTS+=(--verbose)
fi
HTTP_OPTS+=(--timeout="$API_TIMEOUT")

echo "=== Balance Endpoint Tests ==="
echo "API: $API_HOST"
echo

echo "1. ETH2 Deposit Contract Balance"
if [[ -n "$ETH2_EXPECTED" ]]; then
    echo "   (Expected: ~${ETH2_EXPECTED} ETH)"
fi
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/$ETH2_DEPOSIT/balance" Accept:application/json
echo

echo "2. Vitalik's Address Balance"
if [[ -n "$VITALIK_EXPECTED" ]]; then
    echo "   (Expected: ~${VITALIK_EXPECTED} ETH)"
fi
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/$VITALIK/balance" Accept:application/json
echo

echo "3. Regular User Balance"
if [[ -n "$REGULAR_EXPECTED" ]]; then
    echo "   (Expected: ~${REGULAR_EXPECTED} ETH)"
fi
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/$REGULAR_USER/balance" Accept:application/json
echo

echo "4. Empty Wallet Balance"
echo "   (Expected: ${EMPTY_EXPECTED} ETH)"
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/$EMPTY_WALLET/balance" Accept:application/json
echo

# Optional tests for addresses that may not be available in all environments
if [[ -n "$DUST_AMOUNT" ]]; then
    echo "5. Dust Amount Balance"
    http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/$DUST_AMOUNT/balance" Accept:application/json
    echo
fi

if [[ -n "$WHALE" ]]; then
    echo "6. Whale Address Balance"
    if [[ -n "$WHALE_EXPECTED" ]]; then
        echo "   (Expected: ~${WHALE_EXPECTED} ETH)"
    fi
    http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/$WHALE/balance" Accept:application/json
    echo
fi

echo "7. Test Cache Behavior - First Request"
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/$VITALIK/balance" Accept:application/json
echo

echo "8. Test Cache Behavior - Second Request (should be from cache)"
sleep 1
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/$VITALIK/balance" Accept:application/json
echo

echo "9. Mixed Case Address (should normalize and return balance)"
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045/balance" Accept:application/json
echo

echo "10. Lowercase Address (should work with all lowercase)"
http "${HTTP_OPTS[@]}" GET "$API_HOST/api/$API_VERSION/address/0xd8da6bf26964af9d7eed9e03e53415d37aa96045/balance" Accept:application/json
echo

echo "=== All balance tests completed ==="
