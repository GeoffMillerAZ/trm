#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Quick Docker test for devbox setup"

# Test basic build
echo "📦 Building image..."
docker build -f docker/dockerfiles/Dockerfile.devbox -t trm1-devbox:quicktest . || {
    echo "❌ Build failed"
    exit 1
}

# Test with mounted Nix store (if available)
if [ -d "/nix/store" ]; then
    echo "✅ Nix store found, testing with mount..."
    docker run --rm \
        -v /nix/store:/nix/store:ro \
        -v ~/.cache/nix:/home/devbox/.cache/nix:ro \
        trm1-devbox:quicktest \
        devbox run -- python --version
else
    echo "⚠️  No Nix store found, testing without mount..."
    docker run --rm \
        trm1-devbox:quicktest \
        devbox run -- python --version
fi

echo "✅ Basic test passed!"