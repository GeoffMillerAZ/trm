#!/usr/bin/env bash
set -euo pipefail

# Unified test runner for different test modes
# Usage: ./scripts/run-tests.sh [mode] [test-pattern]
#   mode: mock, file-based, services, wan (default: mock)
#   test-pattern: Pattern to match test files (default: all)

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
TEST_MODE="${1:-mock}"
TEST_PATTERN="${2:-*}"
COMPOSE_FILE="docker/compose/docker-compose.unified.yml"
ENV_FILE="docker/compose/envs/${TEST_MODE}.env"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up containers...${NC}"
    cd "$PROJECT_ROOT"
    docker-compose -f "$COMPOSE_FILE" --profile "$TEST_MODE" down -v 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Help function
show_help() {
    echo "Usage: $0 [mode] [test-pattern]"
    echo ""
    echo "Modes:"
    echo "  mock        - All in-memory mocks (fastest)"
    echo "  file-based  - File-based implementations"
    echo "  services    - Docker services with mock blockchain"
    echo "  wan         - Docker services with real Infura (requires INFURA_API_KEY)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests in mock mode"
    echo "  $0 file-based         # Run all tests with file-based mode"
    echo "  $0 services balance   # Run balance tests with services"
    echo "  $0 wan block          # Run block tests with real Infura"
    exit 0
}

# Parse arguments
if [[ "$TEST_MODE" == "--help" || "$TEST_MODE" == "-h" ]]; then
    show_help
fi

# Validate test mode
case "$TEST_MODE" in
    mock|file-based|services|wan)
        ;;
    *)
        echo -e "${RED}Error: Invalid test mode '$TEST_MODE'${NC}"
        echo "Valid modes: mock, file-based, services, wan"
        exit 1
        ;;
esac

# Check for WAN mode requirements
if [[ "$TEST_MODE" == "wan" ]] && [[ -z "${INFURA_API_KEY:-}" ]]; then
    echo -e "${RED}Error: WAN mode requires INFURA_API_KEY environment variable${NC}"
    echo "Usage: INFURA_API_KEY=your_key $0 wan"
    exit 1
fi

echo -e "${BLUE}=== TRM Block Explorer Test Runner ===${NC}"
echo -e "${YELLOW}Mode: $TEST_MODE${NC}"
echo -e "${YELLOW}Pattern: $TEST_PATTERN${NC}"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Check if environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}Error: Environment file not found: $ENV_FILE${NC}"
    exit 1
fi

# Load environment variables
echo -e "${BLUE}Loading environment from $ENV_FILE...${NC}"
set -a
source "$ENV_FILE"
set +a

# Export TEST_MODE for docker-compose
export TEST_MODE

# Stop any existing containers
echo -e "${BLUE}Stopping existing containers...${NC}"
docker-compose -f "$COMPOSE_FILE" --profile "$TEST_MODE" down -v 2>/dev/null || true

# Start containers
echo -e "${BLUE}Starting containers for $TEST_MODE mode...${NC}"
if [[ "$TEST_MODE" == "wan" ]]; then
    # For WAN mode, we need to pass INFURA_API_KEY
    INFURA_API_KEY="$INFURA_API_KEY" docker-compose -f "$COMPOSE_FILE" --profile "$TEST_MODE" up -d --build
else
    docker-compose -f "$COMPOSE_FILE" --profile "$TEST_MODE" up -d --build
fi

# Wait for API to be healthy
echo -e "${BLUE}Waiting for API to be healthy...${NC}"
sleep 3  # Initial sleep to give API time to start
MAX_RETRIES=30
RETRY_COUNT=0

while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    if curl -s -f http://localhost:${API_PORT:-8000}/api/v1/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API is healthy${NC}"
        break
    fi
    
    echo -n "."
    sleep 3
    ((RETRY_COUNT++))
done

echo ""

if [[ $RETRY_COUNT -eq $MAX_RETRIES ]]; then
    echo -e "${RED}✗ API failed to become healthy${NC}"
    echo -e "${YELLOW}Container logs:${NC}"
    docker-compose -f "$COMPOSE_FILE" --profile "$TEST_MODE" logs api
    exit 1
fi

# Map test mode to httpie environment
case "$TEST_MODE" in
    mock)
        HTTPIE_ENV="mock"
        ;;
    file-based)
        HTTPIE_ENV="file-based"
        ;;
    services)
        HTTPIE_ENV="services"
        ;;
    wan)
        HTTPIE_ENV="local-wan"
        ;;
esac

# Run tests
echo -e "${BLUE}Running tests with pattern '$TEST_PATTERN'...${NC}"
echo ""

# Run HTTPie tests
if [[ "$TEST_PATTERN" == "*" ]]; then
    # Run all tests
    bash tests/httpie/run_all_tests.sh --env "$HTTPIE_ENV"
    TEST_EXIT_CODE=$?
else
    # Run specific test pattern
    for test_file in tests/httpie/test_${TEST_PATTERN}*.sh; do
        if [[ -f "$test_file" ]]; then
            echo -e "${BLUE}Running $(basename "$test_file")...${NC}"
            bash "$test_file" --env "$HTTPIE_ENV"
        fi
    done
    TEST_EXIT_CODE=$?
fi

# Show container logs on failure
if [[ $TEST_EXIT_CODE -ne 0 ]]; then
    echo ""
    echo -e "${YELLOW}Test failed. Container logs:${NC}"
    docker-compose -f "$COMPOSE_FILE" --profile "$TEST_MODE" logs --tail=50 api
fi

# Summary
echo ""
if [[ $TEST_EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed in $TEST_MODE mode${NC}"
else
    echo -e "${RED}✗ Some tests failed in $TEST_MODE mode${NC}"
fi

exit $TEST_EXIT_CODE