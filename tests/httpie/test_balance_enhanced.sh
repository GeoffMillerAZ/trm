#!/bin/bash

# Enhanced test script for balance endpoint with formatted output
# Usage: ./test_balance_enhanced.sh [--env ENV_FILE]

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the test wrapper
source "$SCRIPT_DIR/test_wrapper.sh"

# Default environment
ENV_NAME="local"
TEST_MODE="local"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENV_NAME="$2"
            TEST_MODE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--env ENV_NAME]"
            exit 1
            ;;
    esac
done

# Construct environment file path
ENV_FILE="$SCRIPT_DIR/envs/${ENV_NAME}.env"

# Check if environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Environment file not found: $ENV_FILE"
    exit 1
fi

# Load environment variables
set -a
source "$ENV_FILE"
set +a

# Print test configuration
print_test_configuration "$TEST_MODE"

echo "Testing balance endpoint..."

# Run balance tests
run_test "Ethereum 2.0 Deposit Contract Balance" \
    "http GET '${API_HOST}/api/${API_VERSION}/address/${ETH2_DEPOSIT_ADDRESS}/balance' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "${ETH2_DEPOSIT_EXPECTED:-~36.6M} ETH"

run_test "Vitalik's Address Balance" \
    "http GET '${API_HOST}/api/${API_VERSION}/address/${VITALIK_ADDRESS}/balance' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "${VITALIK_EXPECTED:-~5234.5} ETH"

run_test "Regular User Address Balance" \
    "http GET '${API_HOST}/api/${API_VERSION}/address/${REGULAR_USER_ADDRESS}/balance' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "${REGULAR_USER_EXPECTED:-1.5} ETH"

run_test "Empty Wallet Balance" \
    "http GET '${API_HOST}/api/${API_VERSION}/address/${EMPTY_WALLET_ADDRESS}/balance' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "${EMPTY_WALLET_EXPECTED:-0} ETH"

run_test "Dust Amount Address Balance" \
    "http GET '${API_HOST}/api/${API_VERSION}/address/${DUST_AMOUNT_ADDRESS}/balance' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "${DUST_AMOUNT_EXPECTED:-0.000000000123456789} ETH"

run_test "Whale Address Balance" \
    "http GET '${API_HOST}/api/${API_VERSION}/address/${WHALE_ADDRESS}/balance' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "${WHALE_EXPECTED:-~999999.99} ETH"

# Additional tests
run_test "Mixed Case Address Normalization" \
    "http GET '${API_HOST}/api/${API_VERSION}/address/0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045/balance' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "Same as Vitalik's balance"

run_test "Lowercase Address Support" \
    "http GET '${API_HOST}/api/${API_VERSION}/address/0xd8da6bf26964af9d7eed9e03e53415d37aa96045/balance' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "Same as Vitalik's balance"

# Print summary
print_summary