# CI/CD Quick Reference

## Workflow Files

### Active Workflows
- **PR Tests**: `.github/workflows/pr-tests-fast-improved.yml` - Fast PR tests with caching (1-2 min)
- **Dev Deploy**: `.github/workflows/dev-deploy.yml` - Deploy to dev environment
- **Prod Deploy**: `.github/workflows/prod-deploy.yml` - Deploy to production

### Disabled Workflows
- `.github/workflows/pr-tests.yml` - Container-based (disabled, too slow)
- `.github/workflows/pr-tests-fast.yml` - Original fast tests (disabled, replaced by improved)

## Common Tasks

### Run PR Tests Locally
```bash
# Using devbox (recommended)
devbox run -- task test:all
devbox run -- task python:lint
devbox run -- task python:format:check

# Using Docker
task dev:container
```

### Update Dependencies
```bash
# Update devbox packages
devbox update
git add devbox.lock

# Update Python packages
uv add <package>
git add uv.lock

# Always commit lock files!
git commit -m "chore: Update dependencies"
```

### Trigger Workflows Manually
```bash
# Trigger PR tests
gh workflow run "PR Tests (Fast - Improved)"

# Trigger dev deployment
gh workflow run dev-deploy.yml

# Watch workflow progress
gh run watch
```

### Check PR Status
```bash
# View PR checks
gh pr checks

# Watch PR checks live
gh pr checks --watch

# View specific workflow run
gh run view <run-id>
```

## Performance Expectations

| Workflow Type | Cold Cache | Warm Cache |
|--------------|------------|------------|
| PR Tests | ~14-15 min | ~1-2 min |
| Dev Deploy | ~5-7 min | ~2-3 min |
| Prod Deploy | ~5-7 min | ~2-3 min |

## Troubleshooting

### Slow PR Tests
1. Check if it's the first run after dependency updates (expected)
2. Look for "Cache restored" in logs
3. Verify devbox.lock is in sync

### Failed Checks
```bash
# View failed job logs
gh run view <run-id> --log-failed

# Re-run failed jobs only
gh run rerun <run-id> --failed
```

### Cache Issues
```bash
# Update lock files
devbox update
uv lock

# Clear local devbox cache
rm -rf ~/.cache/devbox ~/.local/share/devbox

# Reinstall
devbox install
```

## Branch Protection

Protected branches require:
- `PR Status Check` - Must pass
- `Docker Build Validation` - Must pass

## Quick Commands

```bash
# Check workflow status
gh run list

# Cancel a workflow run
gh run cancel <run-id>

# Download workflow artifacts
gh run download <run-id>

# View workflow file
gh workflow view "PR Tests (Fast - Improved)"
```