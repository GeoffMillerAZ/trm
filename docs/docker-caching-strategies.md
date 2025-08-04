# Docker Caching Strategies for Devbox

This document explains the different caching strategies for building Docker images with Devbox.

## Overview

We have three different Dockerfile approaches, each optimized for different scenarios:

### 1. Local Development with BuildKit Cache Mounts (`Dockerfile.devbox.buildkit`)

**Best for:** Local development with existing Nix store

```dockerfile
RUN --mount=type=cache,target=/nix,sharing=locked \
    --mount=type=cache,target=/home/${DEVBOX_USER}/.cache/nix,uid=1000,gid=1000 \
    devbox install
```

**Pros:**
- Very fast rebuilds locally
- Reuses host's Nix store via BuildKit cache
- Minimal disk usage

**Cons:**
- Cache mounts are build-time only
- Not portable across machines
- Doesn't work well with GitHub Actions

### 2. GitHub Actions Optimized (`Dockerfile.devbox.github`)

**Best for:** CI/CD pipelines

```dockerfile
RUN devbox install && \
    nix-store --optimise && \
    rm -rf /nix/var/nix/gcroots/auto/*
```

**Pros:**
- Creates cacheable layers for GitHub Actions
- Works with `type=gha` caching
- Optimized Nix store reduces layer size
- Portable across CI runs

**Cons:**
- Larger image size (includes full Nix store)
- Slower initial builds
- No benefit from local Nix store

### 3. Runtime Volume Mount (`docker-compose.devbox-test.yml`)

**Best for:** Local testing and development

```yaml
volumes:
  - /nix/store:/nix/store:ro
  - ~/.cache/nix:/home/devbox/.cache/nix:ro
```

**Pros:**
- Fastest option for local development
- No duplication of Nix packages
- Instant access to host's packages

**Cons:**
- Requires Nix installed on host
- Not portable
- Can't be used in CI/CD

## Caching Comparison

| Strategy | Build Speed | Image Size | Portability | CI/CD Support |
|----------|------------|------------|-------------|---------------|
| BuildKit Cache | Fast (2nd+) | Small | Low | Limited |
| GitHub Optimized | Medium | Large | High | Excellent |
| Volume Mount | N/A | Small | None | None |

## Recommendations

1. **For CI/CD**: Use `Dockerfile.devbox.github` with GitHub Actions caching
2. **For local development**: Use `docker-compose.devbox-test.yml` with volume mounts
3. **For local testing without Nix**: Use `Dockerfile.devbox` (original)

## GitHub Actions Caching Details

The GitHub Actions workflow uses multiple cache strategies:

1. **GitHub Actions Cache (`type=gha`)**: Caches Docker layers between runs
2. **Registry Cache**: Stores built images in GitHub Container Registry
3. **Inline Cache**: Embeds cache metadata in the image
4. **Nix Cache**: Separately caches Nix-related directories (not directly used by Docker)

## Usage Examples

### Local Development with Volume Mounts
```bash
# Start services with Nix store mounted
docker-compose -f docker-compose.devbox-test.yml up

# Run tests with mounted Nix store
docker-compose -f docker-compose.devbox-test.yml run --rm test-runner
```

### CI/CD Build
```bash
# GitHub Actions will automatically use caching
# Manual equivalent:
docker buildx build \
  --cache-from type=gha \
  --cache-to type=gha,mode=max \
  -f Dockerfile.devbox.github \
  -t myapp:latest .
```

### Local Build with BuildKit
```bash
# Enable BuildKit and build
DOCKER_BUILDKIT=1 docker build \
  -f Dockerfile.devbox.buildkit \
  -t myapp:local .
```

## Trade-offs Summary

- **Speed vs Portability**: BuildKit mounts are fastest but least portable
- **Size vs Flexibility**: Including Nix store in image is larger but works everywhere
- **Complexity vs Performance**: Multiple caching strategies add complexity but improve performance

Choose the approach that best fits your workflow and constraints.