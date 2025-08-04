#!/bin/bash
set -euo pipefail

# HTTPie Test Runner
# Convenience script to run HTTPie API tests

# Determine the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to tests directory
cd "$PROJECT_ROOT/tests/httpie"

# Pass all arguments to the test runner
exec ./run_all_tests.sh "$@"