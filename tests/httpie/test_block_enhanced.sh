#!/bin/bash

# Enhanced test script for block endpoint with formatted output
# Usage: ./test_block_enhanced.sh [--env ENV_FILE]

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

echo "Testing block endpoint..."

# Run block tests
run_test "Get Genesis Block (Block 1)" \
    "http GET '${API_HOST}/api/${API_VERSION}/blocks/${VALID_BLOCK_HASH}' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "Block #1 with valid hash"

run_test "Get Non-Existent Block" \
    "http GET '${API_HOST}/api/${API_VERSION}/blocks/${NON_EXISTENT_BLOCK_HASH}' --timeout=${API_TIMEOUT:-30} --print=b 2>/dev/null || echo 'Expected 404'" \
    "404 Not Found"

run_test "Invalid Block Hash Format (Too Short)" \
    "http GET '${API_HOST}/api/${API_VERSION}/blocks/${INVALID_BLOCK_HASH}' --timeout=${API_TIMEOUT:-30} --print=b 2>/dev/null || echo 'Expected 422'" \
    "422 Validation Error"

run_test "Valid Block Hash Format (66 chars)" \
    "http GET '${API_HOST}/api/${API_VERSION}/blocks/0x88e96d4537bea4d9c05d12549907b32561d3bf31f45aae734cdc119f13406cb6' --timeout=${API_TIMEOUT:-30} --check-status --print=b 2>/dev/null" \
    "Block with transactions"

# Additional validation tests
run_test "Block Hash Without 0x Prefix" \
    "http GET '${API_HOST}/api/${API_VERSION}/blocks/88e96d4537bea4d9c05d12549907b32561d3bf31f45aae734cdc119f13406cb6' --timeout=${API_TIMEOUT:-30} --print=b 2>/dev/null || echo 'Expected 422'" \
    "422 Validation Error"

run_test "Block Hash With Invalid Characters" \
    "http GET '${API_HOST}/api/${API_VERSION}/blocks/0xZZZZ6d4537bea4d9c05d12549907b32561d3bf31f45aae734cdc119f13406cb6' --timeout=${API_TIMEOUT:-30} --print=b 2>/dev/null || echo 'Expected 422'" \
    "422 Validation Error"

# Print summary
print_summary