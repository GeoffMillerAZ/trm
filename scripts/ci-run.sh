#!/bin/bash
# CI runner script - executes test scripts in CI environment
# This script is used by GitHub Actions to run tests

set -e

# Colors for output (disabled in CI for cleaner logs)
if [ -z "$CI" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to display usage
usage() {
    echo "Usage: $0 <job>"
    echo
    echo "Jobs:"
    echo "  lint        Run linting and validation"
    echo "  unit        Run unit tests"
    echo "  integration Run integration tests"
    echo "  e2e         Run end-to-end tests"
    echo "  security    Run security scans"
    echo
    exit 1
}

# Check arguments
if [ $# -ne 1 ]; then
    usage
fi

JOB=$1

echo -e "${BLUE}Running CI job: $JOB${NC}"

case "$JOB" in
    lint)
        exec "$SCRIPT_DIR/lint.sh"
        ;;
    unit)
        exec "$SCRIPT_DIR/test-unit.sh"
        ;;
    integration|e2e)
        # For integration/e2e, use the full test script
        exec "$SCRIPT_DIR/test.sh" "$JOB"
        ;;
    security)
        echo -e "${YELLOW}Running security scans...${NC}"
        # Safety check for Python dependencies
        uv run safety check --json || true
        # Bandit for security issues in code
        uv run bandit -r src/ -f json -o bandit-report.json || true
        echo -e "${GREEN}Security scans completed${NC}"
        ;;
    *)
        echo -e "${RED}Unknown job: $JOB${NC}"
        usage
        ;;
esac