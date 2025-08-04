#!/bin/bash
# Build Lambda deployment package for Python runtime

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build/lambda"
PACKAGE_PATH="${PROJECT_ROOT}/src/lambda_package.zip"

echo "Building Lambda deployment package..."

# Clean up previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Copy source code
echo "Copying source code..."
cp -r "${PROJECT_ROOT}/src" "${BUILD_DIR}/"

# Install dependencies
echo "Installing dependencies..."
cd "${BUILD_DIR}"

# Create a temporary requirements file for production dependencies
cat > requirements.txt << EOF
fastapi==0.114.0
mangum==0.19.0
structlog==24.4.0
pydantic==2.8.2
pydantic-settings==2.4.0
dependency-injector==4.42.0
httpx==0.27.0
boto3==1.35.14
redis==5.0.8
email-validator==2.2.0
EOF

# Use uv to install dependencies
uv pip install --target . --no-cache -r requirements.txt

# Remove unnecessary files to reduce package size
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete
find . -type f -name "*.pyo" -delete
find . -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true

# Create zip package
echo "Creating zip package..."
zip -r9 "${PACKAGE_PATH}" . -x "*.git*" "*.DS_Store"

# Clean up build directory
rm -rf "${BUILD_DIR}"

# Show package info
PACKAGE_SIZE=$(du -h "${PACKAGE_PATH}" | cut -f1)
echo "Lambda package created: ${PACKAGE_PATH} (${PACKAGE_SIZE})"