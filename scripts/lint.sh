#!/bin/bash
# Local linting script - runs the same checks as CI without using act
# This is a workaround for act/Colima compatibility issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}TRM Block Explorer - Local Linting${NC}"
echo "======================================================"

# Check if we're in a devbox shell (skip in CI)
if [ -z "$CI" ] && ! command -v uv &> /dev/null; then
    echo -e "${RED}Error: 'uv' is not found${NC}"
    echo "Please run this script inside a devbox shell:"
    echo "  devbox shell"
    exit 1
fi

# Function to run a command and report status
run_check() {
    local name=$1
    local cmd=$2
    
    echo -ne "${YELLOW}Running $name...${NC} "
    
    if eval "$cmd" > /tmp/lint_output_$$.log 2>&1; then
        echo -e "${GREEN}✓ Passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed${NC}"
        echo -e "${RED}Output:${NC}"
        cat /tmp/lint_output_$$.log
        rm -f /tmp/lint_output_$$.log
        return 1
    fi
}

# Track overall status
FAILED=0

echo -e "${YELLOW}Installing dependencies...${NC}"
uv sync --dev

echo
echo -e "${BLUE}Running lint checks:${NC}"

# Run all the checks
run_check "Ruff linting" "uv run ruff check ." || ((FAILED++))
run_check "Ruff formatting" "uv run ruff format --check ." || ((FAILED++))
run_check "MyPy type checking" "uv run mypy src/" || ((FAILED++))

# Validate YAML configurations if they exist
if [ -d "configs" ]; then
    run_check "YAML validation" "find configs -name '*.yaml' -o -name '*.yml' | xargs -I {} uv run python -c \"import yaml; yaml.safe_load(open('{}'))\" 2>&1" || ((FAILED++))
fi

# Summary
echo
echo -e "${BLUE}Summary:${NC}"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All checks passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}$FAILED check(s) failed ✗${NC}"
    echo -e "${YELLOW}Fix the issues above and run again.${NC}"
    exit 1
fi