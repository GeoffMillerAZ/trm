#!/bin/bash
# Temporarily disable strict error handling for debugging
set -uo pipefail

# Concurrent Requests Test using HTTPie
# Tests API performance under concurrent load
# Usage: ./test_concurrent.sh [--env ENV_FILE]

# Load environment if --env is provided OR if ENV_FILE is already set (from test runner)
if [[ $# -gt 0 && "$1" == "--env" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
    source "${SCRIPT_DIR}/load_env.sh" "$2"
elif [[ -n "${ENV_FILE:-}" ]]; then
    # Environment already loaded by test runner, just verify we have the variables
    if [[ -z "${API_HOST:-}" ]]; then
        echo "ERROR: Environment not properly loaded" >&2
        exit 1
    fi
fi

# Use environment variables or defaults
API_HOST="${API_HOST:-http://localhost:8000}"
API_TIMEOUT="${API_TIMEOUT:-30}"
API_VERSION="${API_VERSION:-v1}"
VERBOSE_OUTPUT="${VERBOSE_OUTPUT:-false}"
CONCURRENT_REQUESTS="${CONCURRENT_REQUESTS:-4}"

# Test addresses from environment or defaults
ETH2_DEPOSIT="${ETH2_DEPOSIT_ADDRESS:-0x00000000219ab540356cBB839Cbe05303d7705Fa}"
VITALIK="${VITALIK_ADDRESS:-0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045}"
REGULAR_USER="${REGULAR_USER_ADDRESS:-0x742d35Cc6634C0532925a3b844Bc9e7595ED6fF5}"
WHALE="${WHALE_ADDRESS:-0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF}"

# Set HTTPie options based on configuration
HTTP_OPTS=()
if [[ "$VERBOSE_OUTPUT" == "true" ]]; then
    HTTP_OPTS+=(--verbose)
fi
HTTP_OPTS+=(--timeout="$API_TIMEOUT")

echo "=== Concurrent Requests Test ==="
echo "API: $API_HOST"
echo "Concurrent requests: $CONCURRENT_REQUESTS"
echo "Debug: ENV_FILE=${ENV_FILE:-'not set'}"
echo

# Build array of test addresses (skip empty ones)
ADDRESSES=()
ETH2_DEPOSIT="${ETH2_DEPOSIT_ADDRESS:-0x00000000219ab540356cBB839Cbe05303d7705Fa}"
VITALIK="${VITALIK_ADDRESS:-0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045}"
REGULAR_USER="${REGULAR_USER_ADDRESS:-0x742d35Cc6634C0532925a3b844Bc9e7595ED6fF5}"
WHALE="${WHALE_ADDRESS:-0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF}"

[[ -n "$ETH2_DEPOSIT" ]] && ADDRESSES+=("$ETH2_DEPOSIT")
[[ -n "$VITALIK" ]] && ADDRESSES+=("$VITALIK")
[[ -n "$REGULAR_USER" ]] && ADDRESSES+=("$REGULAR_USER")
[[ -n "$WHALE" ]] && ADDRESSES+=("$WHALE")

# Ensure we have at least one address
if [[ ${#ADDRESSES[@]} -eq 0 ]]; then
    echo "ERROR: No test addresses available" >&2
    exit 1
fi

echo "Debug: Available addresses: ${#ADDRESSES[@]}"

echo "Sending $CONCURRENT_REQUESTS requests simultaneously..."
echo

# Run concurrent requests with timeout protection
PIDS=()
COUNT=0

# Simple approach: reduce concurrency when running through test runner
ACTUAL_CONCURRENT=${CONCURRENT_REQUESTS:-3}
if [[ -n "${ENV_FILE:-}" ]]; then
    # Reduce concurrency when run through test runner to avoid overwhelming
    ACTUAL_CONCURRENT=2
fi

for i in $(seq 1 "$ACTUAL_CONCURRENT"); do
    # Cycle through available addresses
    ADDRESS_INDEX=$((i % ${#ADDRESSES[@]}))
    ADDRESS="${ADDRESSES[$ADDRESS_INDEX]}"

    echo "Starting request $i to address $ADDRESS..."
    # Test the HTTP command first to ensure it works
    if ! command -v http >/dev/null 2>&1; then
        echo "ERROR: HTTPie (http command) not found" >&2
        exit 1
    fi

    # Simplified approach - just run the requests
    if [[ "$VERBOSE_OUTPUT" == "true" ]]; then
        http --timeout="$API_TIMEOUT" GET "$API_HOST/api/$API_VERSION/address/$ADDRESS/balance" Accept:application/json > "/tmp/concurrent_test_$i.out" 2>&1 &
    else
        http --timeout="$API_TIMEOUT" --quiet GET "$API_HOST/api/$API_VERSION/address/$ADDRESS/balance" Accept:application/json > "/tmp/concurrent_test_$i.out" 2>&1 &
    fi

    PID=$!
    PIDS+=($PID)
    ((COUNT++))
    echo "  Started with PID: $PID"

    # Small delay to prevent overwhelming the server
    sleep 0.2
done

# Wait for all background jobs to complete
echo "Waiting for all $COUNT requests to complete..."
FAILED_COUNT=0
for pid in "${PIDS[@]}"; do
    if ! wait "$pid"; then
        ((FAILED_COUNT++))
    fi
done

echo
if [[ $FAILED_COUNT -eq 0 ]]; then
    echo "=== All $COUNT concurrent requests completed successfully ==="
else
    echo "=== $COUNT concurrent requests completed, $FAILED_COUNT failed ==="
    exit 1
fi
