# GitHub Actions Workflows

This repository uses a streamlined workflow architecture with just two primary workflows.

## Workflows

### 1. PR Tests (`pr-tests.yml`)
**Trigger:** Pull requests to `main` or `dev` branches

**Purpose:** Validate all changes before merge

**Jobs:**
- **quick-checks**: File size and merge conflict detection
- **python-tests**: Quality checks, unit tests, and integration tests (parallel matrix)
- **security-scan**: Dependency vulnerability scanning
- **terraform-check**: Terraform format and validation
- **docker-check**: Production Dockerfile build validation
- **opa-policy-check**: OPA policy validation (warnings only)
- **pr-status**: Final status check

**Key Features:**
- Comprehensive caching strategy for fast execution
- Parallel test execution using job matrices
- OPA policy validation shows warnings but doesn't block PRs
- DynamoDB service for integration tests

### 2. Deploy (`deploy.yml`)
**Trigger:** 
- Push to `dev` branch → Deploy to development
- Push to `main` branch → Deploy to production
- Manual workflow dispatch

**Purpose:** Deploy infrastructure and application changes

**Jobs:**
1. **determine-environment**: Set environment based on branch
2. **test**: Run full test suite
3. **build-docker**: Build and push Docker image to ECR
4. **terraform-plan**: Generate Terraform plans
5. **opa-validate**: Validate plans against OPA policies
   - Development: Warnings only
   - Production: Strict enforcement (blocks on violations)
6. **approval**: Manual approval gate (production only)
7. **deploy-infrastructure**: Apply Terraform changes
8. **deploy-application**: Deploy Docker image
9. **smoke-tests**: Post-deployment validation
10. **notify**: Deployment status notification

**Key Features:**
- Environment-specific configuration
- Manual approval required for production
- OPA policy enforcement (strict for production)
- Comprehensive error handling and notifications
- Optional test skipping for emergencies

## Caching Strategy

All workflows use consistent caching:
- **Nix Store**: `~/.cache/nix`, `/nix/store`
- **Devbox**: `~/.cache/devbox`, `~/.local/share/devbox`
- **UV Packages**: `~/.cache/uv`, `~/.local/share/uv`
- **Terraform Plugins**: `~/.terraform.d/plugin-cache`
- **Docker Layers**: GitHub Actions cache + registry cache
- **OPA Binary**: Cached at specific version

## OPA Policy Integration

Policies are located in `iac/policies/opa/` and validate:
- Security requirements (IAM, encryption, network)
- AWS service configurations (S3, Lambda, DynamoDB)
- Required tags and naming conventions

**Enforcement:**
- **Pull Requests**: Warnings only
- **Development Deployment**: Warnings only
- **Production Deployment**: Strict enforcement (blocks deployment)

## Environment Configuration

| Environment | Branch | AWS Region | Approval Required | OPA Mode |
|------------|---------|------------|-------------------|----------|
| Development | `dev` | us-east-2 | No | Warning |
| Production | `main` | us-west-2 | Yes | Strict |

## Testing Workflows

Run the validation scripts to ensure workflows are configured correctly:

```bash
# Test PR workflow
./test-pr-workflow.sh

# Test Deploy workflow
./test-deploy-workflow.sh
```

## Maintenance

When updating workflows:
1. Test changes locally using the validation scripts
2. Update this README if adding/removing jobs
3. Ensure caching strategies remain consistent
4. Verify OPA policies work with new infrastructure