# Docker Configuration

This directory contains all Docker-related configurations for the TRM1 project, organized for clarity and maintainability.

## Directory Structure

```
docker/
├── dockerfiles/          # All Dockerfile variants
│   ├── Dockerfile.python         # Standard Python image (production)
│   ├── Dockerfile.devbox         # Devbox-based development image
│   ├── Dockerfile.devbox.buildkit # BuildKit-optimized for local builds
│   ├── Dockerfile.devbox.github   # GitHub Actions optimized
│   └── Dockerfile.devbox.optimized # Multi-stage optimized build
├── compose/              # Docker Compose configurations
│   ├── docker-compose.prod.yml      # Production configuration
│   ├── docker-compose.dev.yml       # Development services only
│   ├── docker-compose.devbox.yml    # Devbox development
│   ├── docker-compose.devbox-test.yml # Devbox with Nix mounting
│   ├── docker-compose.redis.yml     # Redis-specific config
│   ├── docker-compose.services.yml  # Shared services
│   └── docker-compose.test.yml      # Test environment
└── scripts/              # Docker-related scripts
    ├── test-devbox-docker.sh  # Comprehensive devbox testing
    └── quick-docker-test.sh   # Quick validation script
```

## Quick Start

### Development (Default)
```bash
# Uses symlink to docker/compose/docker-compose.dev.yml
docker-compose up
```

### Production
```bash
docker-compose -f docker/compose/docker-compose.prod.yml up
```

### Devbox Development
```bash
# With Nix store mounting (fastest for local dev)
docker-compose -f docker/compose/docker-compose.devbox-test.yml up

# Without Nix mounting
docker-compose -f docker/compose/docker-compose.devbox.yml up
```

### Testing
```bash
# Run tests in container
docker-compose -f docker/compose/docker-compose.test.yml up

# Or use the test script
./docker/scripts/test-devbox-docker.sh
```

## Dockerfile Variants

### 1. **Dockerfile.python** (Production)
- Standard Python 3.12 image
- Uses UV for dependency management
- Minimal size for production deployment
- No development tools included

### 2. **Dockerfile.devbox** (Development)
- Includes full Devbox environment
- All development tools pre-installed
- Larger image but complete dev environment
- Best for consistent development experience

### 3. **Dockerfile.devbox.buildkit** (Local Optimization)
- Uses BuildKit cache mounts for Nix store
- Fastest rebuilds on local machine
- Requires BuildKit and local Nix store
- Not suitable for CI/CD

### 4. **Dockerfile.devbox.github** (CI/CD Optimization)
- Optimized for GitHub Actions caching
- Includes Nix store in image layers
- Works with `type=gha` caching
- Best for CI/CD pipelines

### 5. **Dockerfile.devbox.optimized** (Multi-stage)
- Multi-stage build for better caching
- Separates dependencies from application code
- Good balance of size and build speed

## Docker Compose Configurations

### Production (`docker-compose.prod.yml`)
- Full application stack
- Uses standard Python image
- Includes all required services
- Environment variables from `.env`

### Development (`docker-compose.dev.yml`)
- Development services only (Redis, DynamoDB)
- No API service (run locally)
- Includes DynamoDB Admin UI
- Health checks enabled

### Devbox (`docker-compose.devbox.yml`)
- Uses Devbox image
- Mounts code for hot reload
- Includes volume for Nix cache
- Interactive shell support

### Devbox Test (`docker-compose.devbox-test.yml`)
- Optimized for testing with Nix mounting
- Includes test-runner service
- Separate workspace volumes
- Network isolation

## Caching Strategies

### Local Development
1. **Volume Mounts**: Mount `/nix/store` from host
2. **BuildKit Cache**: Use cache mounts in Dockerfile
3. **Layer Caching**: Docker's built-in layer cache

### CI/CD (GitHub Actions)
1. **GitHub Actions Cache**: `type=gha` in build
2. **Registry Cache**: Store layers in GHCR
3. **Inline Cache**: Metadata in image

## Common Commands

### Build Images
```bash
# Standard build
docker build -f docker/dockerfiles/Dockerfile.python -t trm1:latest .

# Devbox build with BuildKit
DOCKER_BUILDKIT=1 docker build -f docker/dockerfiles/Dockerfile.devbox -t trm1:devbox .

# Build with caching
docker buildx build \
  --cache-from type=gha \
  --cache-to type=gha,mode=max \
  -f docker/dockerfiles/Dockerfile.devbox.github \
  -t trm1:ci .
```

### Run Containers
```bash
# Run with host Nix store
docker run -v /nix/store:/nix/store:ro trm1:devbox

# Run interactively
docker run -it trm1:devbox devbox shell

# Run with environment file
docker run --env-file .env trm1:latest
```

### Docker Compose Operations
```bash
# Start specific service
docker-compose -f docker/compose/docker-compose.dev.yml up redis

# Run one-off command
docker-compose run --rm api uv run pytest

# View logs
docker-compose logs -f api

# Clean up
docker-compose down -v
```

## Troubleshooting

### Slow Builds
1. Enable BuildKit: `export DOCKER_BUILDKIT=1`
2. Use appropriate Dockerfile variant for your use case
3. Mount Nix store for devbox builds
4. Check Docker's disk usage: `docker system df`

### Permission Issues
1. Ensure user IDs match between host and container
2. Use `--chown` in COPY commands
3. Check volume mount permissions

### Nix Store Issues
1. Ensure Nix is installed on host for mounting
2. Use `nix-store --optimise` to reduce size
3. Clear cache if corrupted: `rm -rf ~/.cache/nix`

### Out of Space
```bash
# Clean up unused resources
docker system prune -a

# Remove specific volumes
docker volume rm $(docker volume ls -q)

# Check disk usage
docker system df
```

## Best Practices

1. **Choose the Right Image**
   - Production: Use minimal Python image
   - Development: Use Devbox with mounting
   - CI/CD: Use GitHub-optimized image

2. **Optimize Caching**
   - Order Dockerfile commands by change frequency
   - Use multi-stage builds
   - Leverage BuildKit features

3. **Security**
   - Don't include secrets in images
   - Use specific versions, not `latest`
   - Scan images for vulnerabilities

4. **Development Workflow**
   - Use volume mounts for code
   - Keep services in separate compose files
   - Use profiles for optional services

## Contributing

When adding new Docker configurations:

1. Place Dockerfiles in `docker/dockerfiles/`
2. Place compose files in `docker/compose/`
3. Update this README with usage instructions
4. Test with local build before committing
5. Ensure CI/CD compatibility