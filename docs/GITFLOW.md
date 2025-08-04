# GitFlow Workflow Guide

This repository follows a GitFlow-inspired workflow optimized for solo development with automated deployments.

## Branch Strategy

### Main Branches

- **`main`** - Production branch
  - Protected branch requiring PR and passing tests
  - Automatically deploys to production environment
  - Tagged with version numbers for releases
  
- **`dev`** - Development branch
  - Integration branch for features
  - Automatically deploys to development environment
  - More relaxed rules but still requires tests to pass

### Supporting Branches

- **`feature/*`** - Feature development
  - Branch from: `dev`
  - Merge to: `dev`
  - Naming: `feature/description-of-feature`
  
- **`hotfix/*`** - Emergency production fixes
  - Branch from: `main`
  - Merge to: `main` AND `dev`
  - Naming: `hotfix/description-of-fix`

## Workflow Process

### 1. Starting a New Feature

```bash
# Make sure dev is up to date
git checkout dev
git pull origin dev

# Create feature branch
git checkout -b feature/my-new-feature

# Make changes and commit
git add .
git commit -m "feat: Add new feature"

# Push feature branch
git push -u origin feature/my-new-feature
```

### 2. Creating a Pull Request

```bash
# Using GitHub CLI
gh pr create --base dev --title "Add new feature" --body "Description of changes"

# Or use the GitHub web interface
```

The PR will automatically:
- Run all tests and quality checks
- Check code coverage
- Scan for security vulnerabilities
- Validate Terraform configurations
- Build Docker images

### 3. Merging to Development

Once all checks pass:
- Review your own changes using the PR checklist
- Merge the PR to `dev`
- The `deploy-dev.yml` workflow automatically deploys to development

### 4. Releasing to Production

When ready to release:

```bash
# Create PR from dev to main
gh pr create --base main --head dev --title "Release vX.Y.Z" --body "Release notes..."
```

After merging to main:
- Version is automatically incremented
- GitHub release is created with changelog
- Production deployment runs with smoke tests
- Automatic rollback on failure

### 5. Hotfixes

For emergency fixes:

```bash
# Branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug-fix

# Make fixes and push
git push -u origin hotfix/critical-bug-fix

# Create PR to main
gh pr create --base main --title "Hotfix: Critical bug"

# After merging to main, also merge to dev
git checkout dev
git merge main
git push origin dev
```

## Automated Workflows

### Pull Request Tests (`pr-tests.yml`)
Runs on all PRs to `main` or `dev`:
- Python linting and formatting
- Type checking
- Unit and integration tests
- Security scanning
- Terraform validation
- Docker build validation
- Documentation checks

### Development Deployment (`deploy-dev.yml`)
Runs on push to `dev`:
- Builds and pushes Docker images
- Deploys infrastructure changes
- Updates Lambda functions
- Runs smoke tests

### Production Deployment (`deploy-prod.yml`)
Runs on push to `main`:
- Creates versioned release
- Full test suite with coverage requirements
- Security audit
- Builds production Docker images
- Deploys with automatic rollback on failure

## Self-Review Checklist

Since this is a solo project, use this checklist before merging PRs:

- [ ] Code follows project style (enforced by ruff)
- [ ] Tests added/updated for new functionality
- [ ] All tests passing locally
- [ ] Documentation updated if needed
- [ ] No hardcoded secrets or credentials
- [ ] Performance impact considered
- [ ] Breaking changes documented

## Quick Commands

```bash
# Start new feature
task feature NAME=my-feature

# Run tests locally
task test:all

# Check code quality
task quality:check

# Create release
task release VERSION=X.Y.Z

# View deployment status
gh run list --workflow=deploy-prod.yml
```

## Environment URLs

- **Development**: https://dev.trm.geoffmiller.cloud
- **Production**: https://trm.geoffmiller.cloud

## Rollback Procedure

If production deployment fails:
1. Automatic rollback triggers
2. Previous Lambda version is restored
3. Issue is created for investigation

Manual rollback:
```bash
# Revert to previous version
aws lambda update-alias \
  --function-name trm-blockexplorer-prod \
  --name production \
  --function-version PREVIOUS_VERSION
```

## Tips for Solo Development

1. **Use PRs for Everything**: Even though you're merging your own PRs, they provide:
   - Automated testing before merge
   - Clear history of changes
   - Rollback points
   - Documentation of decisions

2. **Commit Messages**: Follow conventional commits:
   - `feat:` New features
   - `fix:` Bug fixes
   - `docs:` Documentation changes
   - `chore:` Maintenance tasks
   - `refactor:` Code improvements

3. **Regular Releases**: Deploy to production frequently
   - Smaller changes are easier to debug
   - Quick feedback on issues
   - Maintains deployment confidence

4. **Feature Flags**: For risky changes, consider feature flags
   - Deploy disabled features
   - Enable gradually
   - Quick rollback without deployment

## Troubleshooting

### Tests Failing in CI but Passing Locally
- Check Python version matches
- Verify environment variables
- Look for timing-dependent tests
- Check for missing test dependencies

### Deployment Failures
1. Check CloudWatch logs
2. Verify AWS credentials
3. Check resource limits
4. Review Terraform state

### Large File Issues
If git complains about large files:
```bash
# Use the cleanup script
./scripts/cleanup-repo.sh

# Or manually remove from history
git filter-branch --index-filter 'git rm -r --cached --ignore-unmatch path/to/large/file' HEAD
```

## Security Notes

- Never commit `.env` files
- Use GitHub secrets for sensitive values
- Rotate AWS credentials regularly
- Review security scan results in PRs
- Keep dependencies updated

## Getting Help

- Check GitHub Actions logs for detailed error messages
- Use `gh run view RUN_ID` to see specific run details
- Enable debug logging with `ACTIONS_RUNNER_DEBUG=true`
- Create issues for persistent problems