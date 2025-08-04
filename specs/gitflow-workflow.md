# GitFlow Workflow Specification

## Goal
Establish a standardized GitFlow-inspired workflow that ensures consistent development practices, automated deployments, and clear release management for both solo and team development scenarios.

## Context
The project follows a GitFlow-inspired workflow optimized for continuous deployment with automated quality gates. This specification formalizes the branching strategy, PR processes, and deployment triggers documented in `docs/GITFLOW.md`.

**Business Requirements:**
- **Continuous Deployment**: Automatic deployment to appropriate environments based on branch
- **Quality Assurance**: All changes must pass automated tests before merging
- **Release Management**: Clear versioning and release process for production
- **Rollback Capability**: Quick reversion of problematic changes
- **Audit Trail**: Complete history of changes and deployments

## Requirements

### Branch Strategy

#### Main Branches
- **`main`** - Production branch
  - Protected branch requiring PR and passing tests
  - Automatically deploys to production environment
  - Tagged with semantic version numbers for releases
  - Only accepts merges from `dev` or `hotfix/*` branches
  
- **`dev`** - Development integration branch
  - Integration point for all feature development
  - Automatically deploys to development environment
  - Requires passing tests but more relaxed review requirements
  - Accepts merges from `feature/*` branches

#### Supporting Branches
- **`feature/*`** - Feature development branches
  - Branch from: `dev`
  - Merge to: `dev` via PR
  - Naming convention: `feature/descriptive-feature-name`
  - Deleted after merge
  
- **`hotfix/*`** - Emergency production fixes
  - Branch from: `main`
  - Merge to: Both `main` AND `dev` via PRs
  - Naming convention: `hotfix/critical-issue-description`
  - Deleted after merge

### Pull Request Requirements

#### PR Creation Standards
```yaml
# Required PR information
title: "[Type] Brief description"  # Type: feat, fix, chore, docs
body: |
  ## Description
  Clear description of changes
  
  ## Testing
  - [ ] Unit tests pass
  - [ ] Integration tests pass
  - [ ] Manual testing completed
  
  ## Checklist
  - [ ] Code follows project standards
  - [ ] Documentation updated if needed
  - [ ] No sensitive information exposed
```

#### Automated PR Checks
- All tests must pass (unit, integration, quality)
- Code coverage must not decrease
- Security scanning must pass
- Lint and format checks must pass
- Commit messages follow conventional format

### Deployment Triggers

#### Development Deployment
- **Trigger**: Push to `dev` branch
- **Environment**: development
- **Automation**: Fully automated
- **Rollback**: Automatic on failure

#### Production Deployment
- **Trigger**: Push to `main` branch
- **Environment**: production
- **Approval**: Manual approval required (future)
- **Validation**: Post-deployment smoke tests
- **Rollback**: Manual trigger available

### Commit Message Standards
Follow conventional commit format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test additions or fixes
- `chore`: Build process or auxiliary tool changes

### Version Management

#### Version Bumping
- **Major**: Breaking changes (1.0.0 → 2.0.0)
- **Minor**: New features (1.0.0 → 1.1.0)
- **Patch**: Bug fixes (1.0.0 → 1.0.1)

#### Release Process
1. Create PR from `dev` to `main`
2. Title: "Release vX.Y.Z"
3. Body includes changelog
4. After merge: automatic version tag creation
5. GitHub release created with changelog

## Acceptance Tests

### Feature Development Flow
1. Create feature branch from dev
   ```bash
   git checkout dev && git pull
   git checkout -b feature/new-capability
   ```
2. Make changes and push
3. Create PR to dev
4. Verify all checks pass
5. Merge to dev triggers deployment
6. Verify deployment successful

### Hotfix Flow
1. Create hotfix branch from main
   ```bash
   git checkout main && git pull
   git checkout -b hotfix/critical-fix
   ```
2. Make minimal fix and push
3. Create PR to main
4. After main merge, create PR to dev
5. Verify both deployments successful

### Release Flow
1. Create release PR from dev to main
2. Verify changelog is accurate
3. Merge triggers production deployment
4. Verify version tag created
5. Verify GitHub release published

## Implementation Details

### Branch Protection Rules

**Main Branch:**
```yaml
protection_rules:
  - require_pull_request_reviews:
      required_approving_review_count: 1
  - require_status_checks:
      strict: true
      contexts:
        - "PR Tests"
        - "Security Scan"
  - enforce_admins: false
  - require_linear_history: true
  - allow_force_pushes: false
  - allow_deletions: false
```

**Dev Branch:**
```yaml
protection_rules:
  - require_status_checks:
      contexts:
        - "PR Tests"
  - require_linear_history: true
  - allow_force_pushes: false
```

### GitHub CLI Commands

```bash
# Create PR
gh pr create --base dev --title "feat: Add new feature" --body "Description..."

# Check PR status
gh pr status

# Merge PR
gh pr merge --squash --delete-branch

# Create release
gh release create v1.0.0 --title "Version 1.0.0" --notes "Release notes..."
```

### Automation Scripts

```bash
# Auto-generate changelog
git log --pretty=format:"* %s (%h)" dev..main

# Version bump script
npm version patch  # or minor, major

# Deploy verification
curl -f https://api-dev.example.com/health || exit 1
```

## Success Metrics
- **PR Merge Time**: < 24 hours for feature PRs
- **Deployment Success Rate**: > 99%
- **Hotfix Response Time**: < 2 hours from identification to production
- **Release Frequency**: At least weekly
- **Rollback Time**: < 5 minutes when needed

## Migration Notes
- Existing branches should be migrated to new naming convention
- Historical commits don't need to follow conventional format
- Start enforcement with new PRs only
- Gradually introduce automation to avoid disruption