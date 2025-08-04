# GitHub Actions Workflow Strategy

## Goal
Establish a streamlined, efficient, and maintainable GitHub Actions workflow architecture that provides fast feedback on pull requests, reliable deployments, and comprehensive infrastructure validation while minimizing complexity and maximizing performance through intelligent caching and parallelization.

## Context
The project has successfully consolidated from 9 GitHub Actions workflows to 2 clearly-focused workflows, achieving significant performance improvements through optimized caching strategies. The consolidation has reduced PR test execution time from ~14-15 minutes to ~1.5 minutes (9x improvement).

**Current State:**
- ✅ Two consolidated workflows: `pr-tests.yml` and `deploy.yml`
- ✅ Effective caching strategy achieving > 80% cache hit rate
- ✅ Parallel test execution using job matrices
- ✅ Clear separation of PR testing and deployment concerns
- ✅ Environment-based deployment triggers (dev→development, main→production)

**Remaining Gaps:**
- Security scanning (pip-audit, bandit) not yet implemented
- Terraform validation and OPA policy testing not integrated
- Docker build validation missing from PR tests
- Manual approval gates for production deployments not configured
- Post-deployment smoke tests not implemented
- Container-based workflows not yet migrated from Devbox

**Business Requirements:**
- **Fast PR Feedback**: Developers need quick validation of their changes
- **Reliable Deployments**: Consistent deployment process across environments
- **Cost Efficiency**: Minimize GitHub Actions minutes through caching and parallelization
- **Compliance**: Infrastructure changes must pass policy validation before deployment
- **Auditability**: Clear workflow logs and approval processes for production changes

## Requirements

### Functional Requirements

#### PR Testing Workflow (pr-tests.yml)
- **Trigger**: On pull requests to main and dev branches
- **Quick Checks**: File size validation, merge conflict detection
- **Python Testing**: Quality checks (lint, format, type), unit tests, integration tests
- **Security Scanning**: Container vulnerability scanning (Trivy), dependency scanning (pip-audit)
- **Terraform Validation**: Format and syntax validation for all environments
- **Docker Build**: Validate production Dockerfile builds and push to GitHub Container Registry
- **OPA Policy Testing**: Run terraform plan and validate against OPA policies (warnings only)
- **Container Testing**: Build and test containers in CI environment

#### Deployment Workflow (deploy.yml)
- **Triggers**: 
  - Push to `dev` branch → deploy to development environment
  - Push to `main` branch → deploy to production environment
- **Container Build**: Build production Docker image and push to ECR
- **Testing**: Full test suite execution using containerized environment
- **Terraform Planning**: Generate plans for target environment including ECS infrastructure
- **OPA Validation**: 
  - Development: Policy violations as warnings
  - Production: Policy violations as hard failures
- **Approval Gates**: Manual approval required for production deployments
- **Deployment**: 
  - Infrastructure: Terraform deployment of ECS clusters, ALB, networking
  - Application: ECS service deployment with blue-green strategy
- **Validation**: ALB health checks and container health validation

### Non-Functional Requirements

#### Performance
- **PR Tests**: Complete within 5 minutes for typical changes
- **Caching**: 80%+ cache hit rate for dependencies and build artifacts
- **Parallelization**: Independent jobs run concurrently
- **Resource Usage**: Optimize runner usage through job matrices

#### Caching Strategy
Implement multi-layer caching for optimal performance:

**Nix Store Cache** (largest, ~1.4GB):
```yaml
- name: Cache Nix store
  uses: actions/cache@v4
  with:
    path: |
      ~/.cache/nix
      /nix/store
    key: nix-store-${{ runner.os }}-${{ hashFiles('devbox.json') }}
    restore-keys: |
      nix-store-${{ runner.os }}-
```

**Devbox Downloads Cache**:
```yaml
- name: Cache Devbox downloads
  uses: actions/cache@v4
  with:
    path: |
      ~/.cache/devbox
      ~/.local/share/devbox
    key: devbox-downloads-${{ runner.os }}-${{ hashFiles('devbox.json') }}
    restore-keys: |
      devbox-downloads-${{ runner.os }}-
```

**UV Python Packages Cache**:
```yaml
- name: Cache UV packages
  uses: actions/cache@v4
  with:
    path: |
      ~/.cache/uv
      ~/.local/share/uv
    key: uv-${{ runner.os }}-${{ hashFiles('uv.lock') }}
    restore-keys: |
      uv-${{ runner.os }}-
```

**Additional Caches**:
- **Terraform Plugins**: Cache ~/.terraform.d/plugin-cache and .terraform/providers
- **Docker Layers**: Use GitHub Actions cache (type=gha) and registry cache
- **Container Images**: Cache base layers in GitHub Container Registry
- **Build Tools**: Cache container build tools matching Devbox versions

#### Security
- **Secrets Management**: Use GitHub Secrets for sensitive values
- **OIDC Authentication**: Prefer OIDC over long-lived AWS credentials
- **Least Privilege**: Workflows have minimal required permissions
- **Approval Process**: Production deployments require human approval

## Acceptance Tests

### PR Testing Workflow
1. Create a PR with Python code changes
   - Verify all quality checks run in parallel
   - Confirm caching reduces execution time on subsequent runs
   - Validate OPA policies are tested but don't block on violations

2. Create a PR with Terraform changes
   - Verify terraform fmt and validate run successfully
   - Confirm terraform plan executes for affected environments
   - Validate OPA policies are evaluated against the plans

3. Push multiple commits to a PR
   - Verify incremental caching works correctly
   - Confirm previous workflow runs are cancelled

### Deployment Workflow
1. Push to dev branch
   - Verify deployment triggers automatically
   - Confirm all tests pass before deployment
   - Validate OPA warnings are displayed but don't block
   - Verify successful deployment to development environment

2. Push to main branch
   - Verify manual approval is required
   - Confirm OPA policy violations block deployment
   - Validate rollback capability on failure
   - Verify production deployment completes successfully

3. Infrastructure change deployment
   - Push Terraform changes to dev branch
   - Verify terraform plan is generated and reviewed
   - Confirm OPA policies are evaluated
   - Validate infrastructure updates are applied correctly

## Success Metrics
- **Workflow Count**: Reduced from 9 to 2 workflows
- **PR Feedback Time**: < 5 minutes for typical changes
- **Cache Hit Rate**: > 80% for all cached resources
- **Deployment Reliability**: 99%+ success rate for deployments
- **Policy Compliance**: 100% of infrastructure changes validated by OPA
- **Container Build Time**: < 3 minutes with layer caching
- **ECS Deployment Time**: < 10 minutes for blue-green deployment

## Implementation Notes

### Test Matrix Strategy
Use job matrices for parallel test execution:
```yaml
strategy:
  fail-fast: false
  matrix:
    test-type:
      - quality      # lint, format, type checks
      - unit        # unit tests with coverage
      - integration # integration tests
```

### Devbox Lock Verification
Ensure reproducible builds by verifying lock file sync:
```yaml
- name: Verify devbox.lock is in sync
  run: |
    cp devbox.lock devbox.lock.orig
    devbox update
    if ! diff -q devbox.lock devbox.lock.orig > /dev/null; then
      echo "❌ devbox.lock is out of sync!"
      exit 1
    fi
```

### Additional Best Practices
- Implement proper job dependencies to optimize execution flow
- Use composite actions for reusable workflow steps
- Maintain clear job names and step grouping for readability
- Document workflow inputs and secrets in workflow files
- Use workflow_dispatch for manual triggers with environment selection

### Container Strategy
- **Production Images**: Minimal base images without development tools
- **CI Images**: Specialized containers for different workflow stages
- **Native Actions**: Prefer GitHub Actions over custom containers where available
- **Layer Caching**: Optimize Dockerfiles for maximum layer reuse
- **Security Scanning**: Scan all container images before deployment