#!/usr/bin/env bash
# Script to test ECR image locally with mock data

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting ECR local test environment...${NC}"

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Login to ECR
echo -e "\n${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 754419183698.dkr.ecr.us-west-2.amazonaws.com

# Start services
echo -e "\n${YELLOW}Starting services...${NC}"
docker-compose -f docker/compose/docker-compose.ecr-test.yml up -d

# Wait for services to be ready
echo -e "\n${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Check health
echo -e "\n${YELLOW}Checking API health...${NC}"
if curl -s http://localhost:8080/health | grep -q "healthy"; then
    echo -e "${GREEN}✓ API is healthy${NC}"
else
    echo -e "${RED}✗ API health check failed${NC}"
fi

echo -e "\n${GREEN}Services are running!${NC}"
echo -e "- API: http://localhost:8080"
echo -e "- DynamoDB Admin: http://localhost:8012"
echo -e "- Redis Commander: http://localhost:8013"

echo -e "\n${YELLOW}Test commands:${NC}"
echo "# Get address balance:"
echo "curl http://localhost:8080/address/balance/0x742d35Cc6634C0532925a3b844Bc9e7595f62b0e"
echo ""
echo "# View logs:"
echo "docker-compose -f docker/compose/docker-compose.ecr-test.yml logs -f trm-api"
echo ""
echo "# Stop services:"
echo "docker-compose -f docker/compose/docker-compose.ecr-test.yml down"