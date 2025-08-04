#!/bin/bash
set -euo pipefail

# Main test runner for HTTPie API tests
# This script runs all test suites and reports results
# Usage: ./run_all_tests.sh [--env ENV_FILE] [test_pattern]
#   --env ENV_FILE: Load environment from envs/ENV_FILE.env (default: local)
#   test_pattern: Run only tests matching this pattern

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENV_FILE="local"
TEST_PATTERN="*"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env|-e)
            ENV_FILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--env ENV_FILE] [test_pattern]"
            echo ""
            echo "Options:"
            echo "  --env, -e ENV_FILE    Load environment from envs/ENV_FILE.env"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "Available environments:"
            ls envs/*.env 2>/dev/null | xargs -n1 basename | sed 's/.env$//' | sed 's/^/  /'
            echo ""
            echo "Examples:"
            echo "  $0 --env dev                    # Run all tests against dev environment"
            echo "  $0 --env local test_health      # Run health tests against local"
            echo "  $0 --env prod test_balance      # Run balance tests against prod"
            exit 0
            ;;
        *)
            TEST_PATTERN="$1"
            shift
            ;;
    esac
done

# Load environment
source "${SCRIPT_DIR}/load_env.sh" "$ENV_FILE"

# Test results
PASSED=0
FAILED=0

echo -e "${BLUE}=== TRM Block Explorer API Test Suite ===${NC}"
echo -e "${YELLOW}Environment: $ENV_FILE${NC}"
echo "Testing API at: $API_HOST"
echo

# Function to run a test script
run_test() {
    local test_name=$1
    local script_path=$2

    echo -e "${YELLOW}Running: $test_name${NC}"

    if bash "$script_path"; then
        echo -e "${GREEN}✓ $test_name passed${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name failed${NC}"
        ((FAILED++))
    fi
    echo
}

# Check if API is running
echo "Checking if API is accessible..."
if ! http --timeout="$API_TIMEOUT" --check-status GET "$API_HOST/api/$API_VERSION/health" Accept:application/json > /dev/null 2>&1; then
    echo -e "${RED}ERROR: API is not accessible at $API_HOST${NC}"
    echo "Please ensure the API is running and try again."
    exit 1
fi
echo -e "${GREEN}✓ API is accessible${NC}"
echo

# Run all test suites matching the pattern
echo "Looking for tests matching pattern: $TEST_PATTERN"

# Find all test scripts matching the pattern
TEST_SCRIPTS=()
for script in ./test_*.sh; do
    # Check if the file exists first
    if [[ -f "$script" && -x "$script" ]]; then
        # If pattern is *, include all tests
        if [[ "$TEST_PATTERN" == "*" ]]; then
            TEST_SCRIPTS+=("$script")
        # Otherwise check if the script name matches the pattern
        elif [[ "$script" == ./test_"$TEST_PATTERN"* ]]; then
            TEST_SCRIPTS+=("$script")
        fi
    fi
done

if [[ ${#TEST_SCRIPTS[@]} -eq 0 ]]; then
    echo -e "${RED}No test scripts found matching pattern: $TEST_PATTERN${NC}"
    echo "Available tests:"
    ls ./test_*.sh 2>/dev/null | sed 's/\.\///g' | sed 's/^/  /'
    exit 1
fi

# Run the matching test scripts
for script in "${TEST_SCRIPTS[@]}"; do
    test_name=$(basename "$script" .sh | sed 's/test_//' | tr '_' ' ' | sed 's/\b\w/\U&/g')
    run_test "$test_name" "$script"
done

# Summary
echo -e "${YELLOW}=== Test Summary ===${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
