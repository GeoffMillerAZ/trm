#!/bin/bash
# Deploy Lambda functions using AWS CLI
# This script is run after Terraform infrastructure deployment

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Lambda deployment...${NC}"

# Get workspace root
WORKSPACE_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
ENVIRONMENT="${ENV:-dev}"

# Lambda function configurations
declare -A LAMBDA_FUNCTIONS=(
  ["main"]="trm-blockexplorer-main-${ENVIRONMENT}"
  ["health"]="trm-blockexplorer-health-${ENVIRONMENT}"
  ["watchlist"]="trm-blockexplorer-watchlist-${ENVIRONMENT}"
)

# Regions to deploy to
REGIONS=("us-west-2" "us-east-2")

# Path to Lambda package
LAMBDA_PACKAGE="${WORKSPACE_ROOT}/src/lambda_package.zip"

# Check if Lambda package exists
if [ ! -f "$LAMBDA_PACKAGE" ]; then
  echo -e "${RED}Error: Lambda package not found at $LAMBDA_PACKAGE${NC}"
  exit 1
fi

# Calculate package hash
PACKAGE_HASH=$(openssl dgst -sha256 -binary "$LAMBDA_PACKAGE" | openssl enc -base64)
echo -e "${YELLOW}Lambda package hash: $PACKAGE_HASH${NC}"

# Deploy to each region
for REGION in "${REGIONS[@]}"; do
  echo -e "\n${GREEN}Deploying to region: $REGION${NC}"
  
  # Deploy each function
  for FUNCTION_KEY in "${!LAMBDA_FUNCTIONS[@]}"; do
    FUNCTION_NAME="${LAMBDA_FUNCTIONS[$FUNCTION_KEY]}-${REGION}"
    
    echo -e "\n${YELLOW}Checking function: $FUNCTION_NAME${NC}"
    
    # Check if function exists
    if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
      # Get current deployed hash
      CURRENT_HASH=$(aws lambda get-function \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION" \
        --query 'Configuration.CodeSha256' \
        --output text 2>/dev/null || echo "")
      
      echo "  Current hash: $CURRENT_HASH"
      echo "  New hash:     $PACKAGE_HASH"
      
      if [ "$CURRENT_HASH" != "$PACKAGE_HASH" ]; then
        echo -e "  ${GREEN}Updating function code...${NC}"
        
        # Update function code
        UPDATE_RESULT=$(aws lambda update-function-code \
          --function-name "$FUNCTION_NAME" \
          --zip-file "fileb://$LAMBDA_PACKAGE" \
          --region "$REGION" \
          --query 'CodeSha256' \
          --output text)
        
        if [ "$UPDATE_RESULT" == "$PACKAGE_HASH" ]; then
          echo -e "  ${GREEN}✓ Successfully updated $FUNCTION_NAME${NC}"
        else
          echo -e "  ${RED}✗ Failed to update $FUNCTION_NAME${NC}"
          echo "  Expected: $PACKAGE_HASH"
          echo "  Got:      $UPDATE_RESULT"
        fi
        
        # Wait for function to be active
        echo "  Waiting for function to be active..."
        aws lambda wait function-active --function-name "$FUNCTION_NAME" --region "$REGION"
        echo -e "  ${GREEN}✓ Function is active${NC}"
      else
        echo -e "  ${YELLOW}⊝ Function is already up to date${NC}"
      fi
    else
      echo -e "  ${YELLOW}⚠ Function $FUNCTION_NAME does not exist in $REGION (will be created by Terraform)${NC}"
    fi
  done
done

echo -e "\n${GREEN}Lambda deployment completed!${NC}"