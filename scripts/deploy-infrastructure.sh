#!/bin/bash
set -e

# Deploy infrastructure using Terraform
# This script is called from the GitHub Actions workflow
# Note: Lambda deployment is now handled separately by deploy-lambda.sh

ENV_DIR="${1:-dev}"
ENVIRONMENT="${2:-development}"
WORKSPACE_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"

echo "Deploying infrastructure to ${ENVIRONMENT} environment (${ENV_DIR})"
echo "Workspace root: ${WORKSPACE_ROOT}"

# Create plugin cache directory
mkdir -p ~/.terraform.d/plugin-cache
export TF_PLUGIN_CACHE_DIR=~/.terraform.d/plugin-cache

# Apply account bootstrap infrastructure
if [ -f "${WORKSPACE_ROOT}/iac/deploy/account-bootstrap/tfplan" ]; then
  echo "::group::Applying account bootstrap infrastructure"
  cd iac/deploy/account-bootstrap
  terraform init -backend-config=backend-config.hcl
  terraform apply tfplan
  cd "${WORKSPACE_ROOT}"
  echo "::endgroup::"
fi

# Apply trm-blockexplorer global infrastructure
if [ -f "${WORKSPACE_ROOT}/iac/deploy/${ENV_DIR}/global/tfplan" ]; then
  echo "::group::Applying trm-blockexplorer global infrastructure"
  cd iac/deploy/${ENV_DIR}/global
  terraform init -backend-config=backend-config.hcl
  terraform apply tfplan
  cd "${WORKSPACE_ROOT}"
  echo "::endgroup::"
fi

# Apply primary region (us-west-2) infrastructure
if [ -f "${WORKSPACE_ROOT}/iac/deploy/${ENV_DIR}/us-west-2/tfplan" ] && [ ! -f "${WORKSPACE_ROOT}/iac/deploy/${ENV_DIR}/us-west-2/tfplan.skip" ]; then
  echo "::group::Applying primary region (us-west-2) infrastructure"
  cd iac/deploy/${ENV_DIR}/us-west-2
  terraform init -backend-config=backend-config.hcl
  terraform apply tfplan
  cd "${WORKSPACE_ROOT}"
  echo "::endgroup::"
  
  # Minimal testing for primary region
  echo "::group::Testing primary region deployment"
  cd iac/deploy/${ENV_DIR}/us-west-2
  PRIMARY_ENDPOINT=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
  cd "${WORKSPACE_ROOT}"
  
  if [ ! -z "$PRIMARY_ENDPOINT" ]; then
    echo "Testing health endpoint: ${PRIMARY_ENDPOINT}/health"
    for i in {1..6}; do
      if curl -f -s "${PRIMARY_ENDPOINT}/health" > /dev/null; then
        echo "✅ Primary region health check passed"
        break
      else
        echo "⏳ Waiting for primary region to be ready... (attempt $i/6)"
        sleep 20
      fi
    done
  else
    echo "⚠️ No API endpoint found, skipping health check"
  fi
  echo "::endgroup::"
elif [ -f "${WORKSPACE_ROOT}/iac/deploy/${ENV_DIR}/us-west-2/tfplan.skip" ]; then
  echo "⚠️ Skipping us-west-2 deployment due to lock issue"
fi

# Apply secondary region (us-east-2) infrastructure
if [ -f "${WORKSPACE_ROOT}/iac/deploy/${ENV_DIR}/us-east-2/tfplan" ] && [ ! -f "${WORKSPACE_ROOT}/iac/deploy/${ENV_DIR}/us-east-2/tfplan.skip" ]; then
  echo "::group::Applying secondary region (us-east-2) infrastructure"
  cd iac/deploy/${ENV_DIR}/us-east-2
  terraform init -backend-config=backend-config.hcl
  terraform apply tfplan
  cd "${WORKSPACE_ROOT}"
  echo "::endgroup::"
  
  # Minimal testing for secondary region
  echo "::group::Testing secondary region deployment"
  cd iac/deploy/${ENV_DIR}/us-east-2
  SECONDARY_ENDPOINT=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
  cd "${WORKSPACE_ROOT}"
  
  if [ ! -z "$SECONDARY_ENDPOINT" ]; then
    echo "Testing health endpoint: ${SECONDARY_ENDPOINT}/health"
    for i in {1..6}; do
      if curl -f -s "${SECONDARY_ENDPOINT}/health" > /dev/null; then
        echo "✅ Secondary region health check passed"
        break
      else
        echo "⏳ Waiting for secondary region to be ready... (attempt $i/6)"
        sleep 20
      fi
    done
  else
    echo "⚠️ No API endpoint found, skipping health check"
  fi
  echo "::endgroup::"
elif [ -f "${WORKSPACE_ROOT}/iac/deploy/${ENV_DIR}/us-east-2/tfplan.skip" ]; then
  echo "⚠️ Skipping us-east-2 deployment due to lock issue"
fi

# Tag deployment if production
if [[ "${ENVIRONMENT}" == "production" ]]; then
  echo "::group::Tagging production deployment"
  git config user.name "GitHub Actions"
  git config user.email "actions@github.com"
  git tag -a "deploy-prod-$(date +%Y%m%d-%H%M%S)" -m "Production deployment" || true
  git push origin --tags || true
  echo "::endgroup::"
fi

echo "Infrastructure deployment complete!"
echo "Note: Lambda functions are deployed separately by deploy-lambda.sh"