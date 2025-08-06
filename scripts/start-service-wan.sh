#!/usr/bin/env bash
set -euo pipefail

# Helper script to start the service with WAN configuration
# This script configures the service to use local mocks but real Infura API

echo "Starting TRM service with WAN configuration (local mocks + real Infura API)..."

# Check if INFURA_API_KEY is set
if [[ -z "${INFURA_API_KEY:-}" ]]; then
    echo "ERROR: INFURA_API_KEY environment variable must be set"
    echo "Please set it with your actual Infura API key:"
    echo "  export INFURA_API_KEY=your_actual_api_key"
    exit 1
fi

# Set environment variables for WAN configuration
export USE_FILE_BASED_INFRASTRUCTURE=false
export CONFIG_FILE=configs/local-dev-mocks.yaml

echo "Configuration:"
echo "  USE_FILE_BASED_INFRASTRUCTURE=${USE_FILE_BASED_INFRASTRUCTURE}"
echo "  INFURA_API_KEY=***hidden***"
echo "  CONFIG_FILE=${CONFIG_FILE}"
echo

# Start the service
echo "Starting service..."
python -m src.main
