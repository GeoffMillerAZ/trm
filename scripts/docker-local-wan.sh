#!/usr/bin/env bash
set -euo pipefail

# Helper script to run the local-wan Docker Compose configuration
# This setup uses local mocks for services but connects to the real Ethereum blockchain via Infura

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Starting TRM services with local-wan configuration..."
echo "This uses local mocks but connects to real Ethereum blockchain via Infura"
echo

# Check if INFURA_API_KEY is set
if [[ -z "${INFURA_API_KEY:-}" ]]; then
    echo "ERROR: INFURA_API_KEY environment variable must be set"
    echo "Please set it with your actual Infura API key:"
    echo "  export INFURA_API_KEY=your_actual_api_key"
    echo "  $0"
    exit 1
fi

echo "Configuration:"
echo "  INFURA_API_KEY: ***hidden***"
echo "  Mode: Local mocks + Real Infura API"
echo

cd "$PROJECT_ROOT"

# Check Docker daemon
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon is not running or accessible"
    echo "Please start Docker Desktop or restart the Docker daemon"
    echo "On macOS: restart Docker Desktop"
    echo "On Linux: sudo systemctl restart docker"
    exit 1
fi

# Start the services
echo "Starting services with docker-compose..."
docker-compose -f docker/compose/docker-compose.local-wan.yml up --build --remove-orphans "$@"
