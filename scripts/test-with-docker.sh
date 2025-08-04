#!/usr/bin/env bash
# Script to run tests against docker-compose services

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

COMPOSE_FILE="docker/compose/docker-compose.ecr-test.yml"

echo -e "${YELLOW}Running tests against Docker Compose services...${NC}"

# Function to check if services are running
check_services() {
    echo -e "\n${YELLOW}Checking if services are running...${NC}"
    
    # Check API
    if curl -s http://localhost:8080/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API is running${NC}"
        return 0
    else
        echo -e "${RED}✗ API is not running${NC}"
        return 1
    fi
}

# Function to start services
start_services() {
    echo -e "\n${YELLOW}Starting Docker Compose services...${NC}"
    docker-compose -f $COMPOSE_FILE up -d
    
    echo -e "\n${YELLOW}Waiting for services to be ready...${NC}"
    sleep 15
    
    # Check if services started successfully
    if check_services; then
        echo -e "${GREEN}Services are ready!${NC}"
    else
        echo -e "${RED}Services failed to start${NC}"
        docker-compose -f $COMPOSE_FILE logs
        exit 1
    fi
}

# Parse arguments
RUN_ALL=false
KEEP_RUNNING=false
SPECIFIC_TEST=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            RUN_ALL=true
            shift
            ;;
        --keep-running)
            KEEP_RUNNING=true
            shift
            ;;
        --test)
            SPECIFIC_TEST="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--all] [--keep-running] [--test <test_file>]"
            exit 1
            ;;
    esac
done

# Check if services are already running
if ! check_services; then
    start_services
else
    echo -e "${GREEN}Services already running${NC}"
fi

# Export environment variables for tests
export $(cat .env.docker-test | grep -v '^#' | xargs)

echo -e "\n${YELLOW}Running tests...${NC}"

if [ "$RUN_ALL" = true ]; then
    echo -e "${YELLOW}Running all tests (unit + integration)...${NC}"
    uv run pytest -v --tb=short
elif [ -n "$SPECIFIC_TEST" ]; then
    echo -e "${YELLOW}Running specific test: $SPECIFIC_TEST${NC}"
    uv run pytest "$SPECIFIC_TEST" -v --tb=short
else
    echo -e "${YELLOW}Running Docker Compose integration tests...${NC}"
    uv run pytest tests/test_docker_compose_integration.py -v --tb=short
fi

TEST_EXIT_CODE=$?

# Show test results
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "\n${GREEN}✅ Tests passed!${NC}"
else
    echo -e "\n${RED}❌ Tests failed!${NC}"
fi

# Cleanup
if [ "$KEEP_RUNNING" = false ]; then
    echo -e "\n${YELLOW}Stopping services...${NC}"
    docker-compose -f $COMPOSE_FILE down
else
    echo -e "\n${YELLOW}Services kept running${NC}"
    echo -e "Stop with: docker-compose -f $COMPOSE_FILE down"
fi

exit $TEST_EXIT_CODE