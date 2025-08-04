---
allowed-tools: Bash(gh:*), Read, TodoWrite
description: Analyze GitHub Actions workflow caching effectiveness and identify optimization opportunities
---

# Workflow Caching Analysis

Analyze the last 5 GitHub Actions workflow runs to evaluate caching effectiveness and identify optimization opportunities based on Docker caching strategies.

## Process

1. Retrieve recent workflow runs
2. Analyze caching performance for each workflow
3. Compare against documented caching strategies
4. Identify missing or failing cache implementations
5. Provide optimization recommendations

## Commands

### Get Repository Info
!`gh repo view --json name,owner`

### List Recent Workflow Runs
!`gh run list --limit 5 --json databaseId,name,status,conclusion,createdAt,updatedAt`

### Analyze Individual Runs
For each workflow run:
- Check cache hit rates: !`gh run view <run-id> --json jobs`
- Review workflow timing: !`gh run view <run-id> --log | grep -E "(cache|Cache|CACHE)"`

### Check Workflow Definitions
- List workflows: !`ls -la .github/workflows/`
- Analyze caching configuration in each workflow file

## Analysis Criteria

Based on @docs/docker-caching-strategies.md:

### GitHub Actions Cache Types
1. **Docker Layer Cache (`type=gha`)**: For Docker buildx caching
2. **Registry Cache**: For storing built images
3. **Inline Cache**: For embedding cache metadata
4. **Nix Store Cache**: For Nix-related directories
5. **Terraform Plugin Cache**: For Terraform providers

### Expected Caching Implementations
- Deploy workflow: Should use GitHub Actions cache for Docker layers
- PR Tests workflow: Should leverage caching for faster CI
- Terraform workflows: Should cache plugin directory

### Performance Indicators
- Cache hit rate > 80% for established workflows
- Build time reduction > 50% on cache hits
- No cache-related failures in logs

## Output Format

### Summary Report
- Overall cache effectiveness score
- Per-workflow cache analysis
- Identified issues and failures
- Optimization recommendations

### Detailed Findings
- Cache type coverage
- Hit/miss ratios
- Performance impact metrics
- Configuration gaps

## Reference Files
@.github/workflows/deploy.yml
@.github/workflows/pr-tests.yml
@docs/docker-caching-strategies.md