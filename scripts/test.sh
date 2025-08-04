#!/bin/bash
# Local test runner - runs tests without using act
# This is a workaround for act/Colima compatibility issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}TRM Block Explorer - Local Test Runner${NC}"
echo "======================================================"

# Check if we're in a devbox shell
if ! command -v uv &> /dev/null; then
    echo -e "${RED}Error: 'uv' is not found${NC}"
    echo "Please run this script inside a devbox shell:"
    echo "  devbox shell"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  lint        Run linting checks (ruff, mypy)"
    echo "  unit        Run unit tests"
    echo "  integration Run integration tests"
    echo "  e2e         Run end-to-end tests"
    echo "  httpie      Run HTTPie API tests"
    echo "  all         Run all tests (default)"
    echo "  help        Show this help message"
    echo
    echo "Examples:"
    echo "  $0          # Run all tests"
    echo "  $0 lint     # Run only linting"
    echo "  $0 unit     # Run only unit tests"
    exit 0
}

# Install dependencies
install_deps() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    uv sync --dev
}

# Setup environment
setup_env() {
    echo -e "${YELLOW}Setting up test environment...${NC}"
    
    # Create workspace directories for file-based infrastructure
    mkdir -p workspace/{cache,db,logging,secrets,tracing,config}
    
    # Set environment variables for testing
    export ENVIRONMENT=testing
    export USE_MOCK_BLOCKCHAIN=true
    export USE_FILE_BASED_INFRASTRUCTURE=true
    export WORKSPACE_BASE_PATH=./workspace
    export LOG_LEVEL=DEBUG
    export CACHE_ENABLED=true
    export TRACING_BACKEND=console
    export SECRETS_BACKEND=environment
    export ENABLE_CORS=true
    export CORS_ORIGINS='["*"]'
}

# Run linting
run_lint() {
    echo -e "${BLUE}Running lint checks...${NC}"
    ./scripts/lint-local.sh
}

# Run unit tests
run_unit() {
    echo -e "${BLUE}Running unit tests...${NC}"
    if uv run pytest tests/unit/ -v --cov=src --cov-report=term-missing; then
        echo -e "${GREEN}✓ Unit tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Unit tests failed${NC}"
        return 1
    fi
}

# Run integration tests
run_integration() {
    echo -e "${BLUE}Running integration tests...${NC}"
    
    # Start services if needed
    echo -e "${YELLOW}Starting test services...${NC}"
    docker-compose -f docker-compose.test.yml up -d
    
    # Wait for services to be ready
    echo -e "${YELLOW}Waiting for services to be ready...${NC}"
    sleep 5
    
    # Run tests
    if uv run pytest tests/integration/ -v; then
        echo -e "${GREEN}✓ Integration tests passed${NC}"
        docker-compose -f docker-compose.test.yml down
        return 0
    else
        echo -e "${RED}✗ Integration tests failed${NC}"
        docker-compose -f docker-compose.test.yml down
        return 1
    fi
}

# Run E2E tests
run_e2e() {
    echo -e "${BLUE}Running E2E tests...${NC}"
    
    # Start services
    echo -e "${YELLOW}Starting services for E2E tests...${NC}"
    docker-compose -f docker-compose.test.yml up -d
    
    # Wait for services
    echo -e "${YELLOW}Waiting for services to be ready...${NC}"
    sleep 10
    
    # Run E2E tests
    if uv run pytest tests/e2e/ -v; then
        echo -e "${GREEN}✓ E2E tests passed${NC}"
        docker-compose -f docker-compose.test.yml down
        return 0
    else
        echo -e "${RED}✗ E2E tests failed${NC}"
        docker-compose -f docker-compose.test.yml down
        return 1
    fi
}

# Run HTTPie tests
run_httpie() {
    echo -e "${BLUE}Running HTTPie API tests...${NC}"
    
    # Start API
    echo -e "${YELLOW}Starting API for HTTPie tests...${NC}"
    docker-compose -f docker-compose.test.yml up -d
    
    # Wait for API
    echo -e "${YELLOW}Waiting for API to be ready...${NC}"
    sleep 10
    
    # Run HTTPie tests
    if HOST=http://localhost:8000 ./scripts/test-httpie.sh; then
        echo -e "${GREEN}✓ HTTPie tests passed${NC}"
        docker-compose -f docker-compose.test.yml down
        return 0
    else
        echo -e "${RED}✗ HTTPie tests failed${NC}"
        docker-compose -f docker-compose.test.yml down
        return 1
    fi
}

# Run all tests
run_all() {
    local failed=0
    
    run_lint || ((failed++))
    echo
    
    run_unit || ((failed++))
    echo
    
    run_integration || ((failed++))
    echo
    
    run_e2e || ((failed++))
    echo
    
    run_httpie || ((failed++))
    
    echo
    echo -e "${BLUE}Test Summary:${NC}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        return 0
    else
        echo -e "${RED}$failed test suite(s) failed ✗${NC}"
        return 1
    fi
}

# Main execution
install_deps
setup_env

case "${1:-all}" in
    lint)
        run_lint
        ;;
    unit)
        run_unit
        ;;
    integration)
        run_integration
        ;;
    e2e)
        run_e2e
        ;;
    httpie)
        run_httpie
        ;;
    all)
        run_all
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        usage
        ;;
esac