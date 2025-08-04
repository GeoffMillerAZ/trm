# CI/CD Caching Strategy

This document describes the caching strategy implemented in our GitHub Actions workflows to achieve 9x faster PR test execution times.

## Overview

Our caching strategy reduces PR test execution time from ~14-15 minutes to ~1.5 minutes by effectively caching development dependencies across workflow runs. This is achieved through multiple complementary cache layers that work together to minimize redundant downloads and installations.

## Performance Results

- **First run**: 14m 33s (cold cache)
- **Second run**: 1m 35s (with cache) - **9x faster!**
- **Subsequent runs**: ~1m 30s (consistent performance)

## Cache Layers

### 1. Nix Store Cache
The largest and most important cache, containing all Devbox packages (~1.4GB).

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

**Key features:**
- Caches the entire Nix store containing all Devbox packages
- Key based on OS and devbox.json content
- Fallback to OS-specific cache if exact match not found

### 2. Devbox Downloads Cache
Caches Devbox-specific downloads and metadata.

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

### 3. UV Package Cache
Caches Python packages installed via UV package manager.

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

### 4. Security Tools Cache
Caches pip-installed security scanning tools.

```yaml
- name: Cache security tools
  uses: actions/cache@v4
  with:
    path: |
      ~/.cache/pip
      ~/.local/bin
    key: security-tools-${{ runner.os }}-${{ hashFiles('pyproject.toml') }}
    restore-keys: |
      security-tools-${{ runner.os }}-
```

### 5. Terraform Plugin Cache
Caches Terraform providers and plugins.

```yaml
- name: Cache Terraform plugins
  uses: actions/cache@v4
  with:
    path: |
      ~/.terraform.d/plugin-cache
      **/.terraform/providers
    key: terraform-${{ runner.os }}-${{ hashFiles('**/*.tf') }}
    restore-keys: |
      terraform-${{ runner.os }}-
```

## Devbox Lock File Synchronization

A critical component of our caching strategy is ensuring the devbox.lock file remains synchronized to prevent cache key mismatches.

### The Problem
The devbox-install-action has a known issue where it updates the lock file during installation, causing the cache key to change between the restore and save phases. This results in cache misses on subsequent runs.

### The Solution
1. **Prevent lock file updates during CI:**
   ```yaml
   env:
     DEVBOX_NO_REFRESH: 'true'
   ```

2. **Verify lock file synchronization:**
   ```yaml
   - name: Verify devbox.lock is in sync
     run: |
       cp devbox.lock devbox.lock.orig
       devbox update
       if ! diff -q devbox.lock devbox.lock.orig > /dev/null; then
         echo "❌ devbox.lock is out of sync!"
         exit 1
       fi
       echo "✅ devbox.lock is in sync"
   ```

## Workflow Configuration

### Complete Example

Here's a complete example of a job with all caching strategies:

```yaml
python-tests:
  name: Python ${{ matrix.test-type }}
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    # Multiple cache layers
    - name: Cache Nix store
      uses: actions/cache@v4
      with:
        path: |
          ~/.cache/nix
          /nix/store
        key: nix-store-${{ runner.os }}-${{ hashFiles('devbox.json') }}
        restore-keys: |
          nix-store-${{ runner.os }}-
    
    - name: Cache Devbox downloads
      uses: actions/cache@v4
      with:
        path: |
          ~/.cache/devbox
          ~/.local/share/devbox
        key: devbox-downloads-${{ runner.os }}-${{ hashFiles('devbox.json') }}
        restore-keys: |
          devbox-downloads-${{ runner.os }}-
    
    - name: Install Devbox with frozen lockfile
      uses: jetify-com/devbox-install-action@v0.13.0
      with:
        enable-cache: 'true'
        project-path: '.'
      env:
        DEVBOX_NO_REFRESH: 'true'
    
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

## Docker Container Caching

For workflows using Docker containers, we implement BuildKit cache mounts:

```dockerfile
# Install devbox packages with cache at alternative location
RUN --mount=type=cache,target=/tmp/nix-store-cache,sharing=locked \
    if [ -d "/tmp/nix-store-cache" ] && [ -n "$(ls -A /tmp/nix-store-cache 2>/dev/null)" ]; then \
        echo "Using cached Nix store..." && \
        mkdir -p /nix/store && \
        cp -r /tmp/nix-store-cache/* /nix/store/ 2>/dev/null || true; \
    fi && \
    devbox install && \
    echo "Updating Nix store cache..." && \
    mkdir -p /tmp/nix-store-cache && \
    cp -r /nix/store/* /tmp/nix-store-cache/ 2>/dev/null || true
```

**Important:** We mount the cache at `/tmp/nix-store-cache` instead of directly at `/nix/store` to avoid breaking Nix profile symlinks.

## Shared Cache Keys

All workflows use consistent cache key patterns to maximize cache reuse:

```yaml
cache-from: |
  type=gha,scope=shared
  type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
cache-to: |
  type=gha,mode=max,scope=shared
  type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max
```

## Best Practices

1. **Keep lock files in sync**: Run `devbox update` and `uv lock` locally before committing
2. **Use consistent cache keys**: Follow the patterns shown above
3. **Monitor cache hit rates**: Check workflow logs for "Cache restored" messages
4. **Clean up old caches**: GitHub automatically evicts unused caches after 7 days
5. **Test caching locally**: Use `act` or similar tools to test workflows locally

## Troubleshooting

### Cache Misses
1. Check if lock files are out of sync
2. Verify cache key patterns match across workflows
3. Look for "Cache not found" messages in logs

### Slow First Runs
- First runs after dependency updates will be slow (cold cache)
- This is expected and subsequent runs will be fast

### Devbox Lock File Issues
If you see "devbox.lock is out of sync" errors:
```bash
devbox update
git add devbox.lock
git commit -m "chore: Update devbox.lock"
```

## Maintenance

### Updating Dependencies
When updating dependencies:
1. Update the dependency specification (devbox.json, pyproject.toml, etc.)
2. Update lock files: `devbox update`, `uv lock`
3. Commit both specification and lock files together
4. First CI run will be slow (rebuilding cache)
5. Subsequent runs will be fast again

### Cache Invalidation
Caches are automatically invalidated when:
- Lock files change
- Dependency specifications change
- Cache keys are updated
- 7 days pass without use (GitHub's eviction policy)

## Future Improvements

1. **Investigate native Nix caching**: Use Cachix or similar for better Nix store caching
2. **Parallel cache restoration**: Restore multiple caches in parallel
3. **Cache warming**: Pre-build caches on dependency updates
4. **Cache analytics**: Track cache hit rates and sizes

## References

- [GitHub Actions Cache](https://github.com/actions/cache)
- [Devbox CI/CD Guide](https://www.jetify.com/docs/devbox/continuous_integration/)
- [BuildKit Cache Mounts](https://docs.docker.com/build/cache/backends/)
- [Nix Store Caching](https://nixos.wiki/wiki/Binary_Cache)