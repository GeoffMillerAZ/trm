#!/bin/bash
# Local unit test runner - runs unit tests without using act
# This is a workaround for act/Colima compatibility issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}TRM Block Explorer - Local Unit Tests${NC}"
echo "======================================================"

# Check if we're in a devbox shell
if ! command -v uv &> /dev/null; then
    echo -e "${RED}Error: 'uv' is not found${NC}"
    echo "Please run this script inside a devbox shell:"
    echo "  devbox shell"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
uv sync --dev

# Create workspace directories for file-based infrastructure
echo -e "${YELLOW}Setting up workspace directories...${NC}"
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

echo
echo -e "${BLUE}Running unit tests:${NC}"

# Run unit tests with coverage
echo -e "${YELLOW}Running pytest with coverage...${NC}"
if uv run pytest tests/unit/ -v --cov=src --cov-report=term-missing --cov-report=html; then
    echo -e "${GREEN}✓ All unit tests passed!${NC}"
    echo
    echo -e "${YELLOW}Coverage report:${NC}"
    echo "  - Terminal: See above"
    echo "  - HTML: Open htmlcov/index.html"
    exit 0
else
    echo -e "${RED}✗ Unit tests failed${NC}"
    exit 1
fi