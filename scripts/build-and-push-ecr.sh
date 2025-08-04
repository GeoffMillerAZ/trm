#!/usr/bin/env bash
# Script to build and push TRM Block Explorer container to ECR
# Usage: ./scripts/build-and-push-ecr.sh [tag]

set -euo pipefail

# Ensure non-interactive mode for all commands
export DEBIAN_FRONTEND=noninteractive
export DOCKER_BUILDKIT=1
export BUILDX_NO_DEFAULT_ATTESTATIONS=1

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_ACCOUNT_ID="754419183698"
AWS_REGION="us-west-2"
ECR_REPOSITORY="trm-blockexplorer"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_ECR_URI="${ECR_URI}/${ECR_REPOSITORY}"

# Get the tag from argument or use 'latest'
TAG="${1:-latest}"

# Get git commit hash for additional tagging
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")

echo -e "${YELLOW}Building and pushing TRM Block Explorer to ECR${NC}"
echo -e "Repository: ${FULL_ECR_URI}"
echo -e "Tag: ${TAG}"
echo -e "Git Hash: ${GIT_HASH}"

# Step 1: Authenticate Docker to ECR
echo -e "\n${YELLOW}Step 1: Authenticating to ECR...${NC}"
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_URI}" >/dev/null 2>&1

# Step 2: Create ECR repository if it doesn't exist
echo -e "\n${YELLOW}Step 2: Ensuring ECR repository exists...${NC}"
aws ecr describe-repositories --repository-names "${ECR_REPOSITORY}" --region "${AWS_REGION}" >/dev/null 2>&1 || \
    aws ecr create-repository --repository-name "${ECR_REPOSITORY}" --region "${AWS_REGION}" --image-scanning-configuration scanOnPush=true >/dev/null 2>&1

# Step 3: Generate requirements.txt from pyproject.toml if it doesn't exist
echo -e "\n${YELLOW}Step 3: Generating requirements.txt...${NC}"
if ! [ -f requirements.txt ]; then
    echo -e "${YELLOW}requirements.txt not found, generating from pyproject.toml...${NC}"
    # Use uv to export requirements
    if command -v uv &> /dev/null; then
        uv pip compile pyproject.toml -o requirements.txt
    else
        echo -e "${RED}Error: uv not found. Please install uv or create requirements.txt manually.${NC}"
        exit 1
    fi
fi

# Step 4: Build the Docker image
echo -e "\n${YELLOW}Step 4: Building Docker image...${NC}"

# Use the default working builder (colima in this case)
# First check if we have a working builder
WORKING_BUILDER=$(docker buildx ls | grep -E "^\S+\*" | awk '{print $1}' | sed 's/\*//')
if [ -z "$WORKING_BUILDER" ]; then
    # Find any running builder
    WORKING_BUILDER=$(docker buildx ls | grep "running" | head -1 | awk '{print $1}')
fi

if [ -n "$WORKING_BUILDER" ]; then
    echo -e "${YELLOW}Using working buildx builder: ${WORKING_BUILDER}${NC}"
    docker buildx use "$WORKING_BUILDER" >/dev/null 2>&1
else
    echo -e "${RED}Error: No working buildx builder found${NC}"
    exit 1
fi

docker buildx build \
    --platform linux/amd64 \
    --tag "${FULL_ECR_URI}:${TAG}" \
    --tag "${FULL_ECR_URI}:${GIT_HASH}" \
    --tag "${FULL_ECR_URI}:latest" \
    --push \
    --progress=plain \
    . || {
        echo -e "${RED}Error: Docker build failed${NC}"
        exit 1
    }

# Step 5: Images are already pushed by buildx
echo -e "\n${YELLOW}Step 5: Images pushed to ECR via buildx...${NC}"
echo -e "${GREEN}Images successfully pushed:${NC}"
echo -e "  - ${FULL_ECR_URI}:${TAG}"
echo -e "  - ${FULL_ECR_URI}:${GIT_HASH}"
echo -e "  - ${FULL_ECR_URI}:latest"

# Step 6: Clean up local images (buildx doesn't store locally)
echo -e "\n${YELLOW}Step 6: Buildx doesn't store images locally, no cleanup needed...${NC}"

echo -e "\n${GREEN}Successfully built and pushed images:${NC}"
echo -e "  - ${FULL_ECR_URI}:${TAG}"
echo -e "  - ${FULL_ECR_URI}:${GIT_HASH}"
echo -e "  - ${FULL_ECR_URI}:latest"

# Output the image URI for use in Terraform
echo -e "\n${GREEN}Use this image URI in your Terraform configuration:${NC}"
echo -e "${FULL_ECR_URI}:${TAG}"
