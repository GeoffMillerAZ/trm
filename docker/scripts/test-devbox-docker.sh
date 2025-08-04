#!/usr/bin/env bash
set -euo pipefail

# Script to test Dockerfile.devbox with proper caching and Nix store mounting

echo "=== Testing Devbox Docker Build ==="

# Check if running in devbox shell
if ! command -v devbox &> /dev/null; then
    echo "❌ This script should be run inside a devbox shell"
    echo "   Run: devbox shell"
    exit 1
fi

# Ensure Nix store exists
if [ ! -d "/nix/store" ]; then
    echo "❌ Nix store not found at /nix/store"
    echo "   This is required for mounting into the container"
    exit 1
fi

# Build the image with BuildKit for better caching
echo "📦 Building Docker image with BuildKit..."
DOCKER_BUILDKIT=1 docker build \
    -f docker/dockerfiles/Dockerfile.devbox \
    -t trm1-devbox:test \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from trm1-devbox:test \
    --progress=plain \
    .

echo "✅ Build completed"

# Test the image
echo "🧪 Running tests in container..."
docker run --rm \
    -v /nix/store:/nix/store:ro \
    -v ~/.cache/nix:/home/devbox/.cache/nix:ro \
    -v "$(pwd)":/code:ro \
    -e CONFIG_FILE=configs/local-dev-mocks.yaml \
    -e ENVIRONMENT=test \
    trm1-devbox:test \
    devbox run -- bash -c "cd /code && uv run pytest tests/unit/domain/test_ethereum_address.py -v"

echo "✅ Unit test passed"

# Test environment
echo "🔍 Checking devbox environment..."
docker run --rm \
    -v /nix/store:/nix/store:ro \
    trm1-devbox:test \
    devbox run -- bash -c "
        echo '=== Devbox Environment ==='
        python --version
        uv --version
        task --version
        terraform --version | head -1
        aws --version
        echo '=== Installed Devbox Packages ==='
        devbox list
    "

# Test with docker-compose
echo "🐳 Testing with docker-compose..."
docker-compose -f docker/compose/docker-compose.devbox-test.yml build

echo "✅ All tests passed!"
echo ""
echo "📝 To run the full stack with Nix mounting:"
echo "   docker-compose -f docker/compose/docker-compose.devbox-test.yml up"
echo ""
echo "📝 To run tests only:"
echo "   docker-compose -f docker/compose/docker-compose.devbox-test.yml --profile test up test-runner"