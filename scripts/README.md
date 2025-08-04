# Scripts Directory

This directory contains utility scripts for development, testing, and deployment.

## Test Scripts

### Overview

All test scripts work both locally and in CI environments. They provide consistent testing capabilities without requiring additional tools like `act`.

### Available Scripts

#### lint.sh
Run all linting and validation checks:
```bash
./scripts/lint.sh
```
- Ruff linting and formatting
- MyPy type checking
- YAML configuration validation

#### test-unit.sh
Run unit tests with coverage:
```bash
./scripts/test-unit.sh
```
- Runs all unit tests
- Generates coverage reports (terminal and HTML)
- Sets up test environment automatically

#### test.sh
Comprehensive test runner for all test types:
```bash
# Run all tests
./scripts/test.sh

# Run specific test suites
./scripts/test.sh lint        # Linting only
./scripts/test.sh unit        # Unit tests only
./scripts/test.sh integration # Integration tests
./scripts/test.sh e2e         # End-to-end tests
./scripts/test.sh httpie      # HTTPie API tests
```

#### test-httpie.sh
Run HTTPie-based API tests:
```bash
# Test against local API
./scripts/test-httpie.sh

# Test against different host
HOST=http://localhost:8080 ./scripts/test-httpie.sh
```

#### ci-run.sh
CI runner wrapper (used by GitHub Actions):
```bash
./scripts/ci-run.sh lint
./scripts/ci-run.sh unit
./scripts/ci-run.sh integration
./scripts/ci-run.sh security
```

### Prerequisites

1. **Devbox**: All scripts require devbox for consistent environments
   ```bash
   devbox shell
   ```

2. **Docker**: Required for integration/E2E tests
   - Works with Docker Desktop, Colima, or any Docker runtime
   - No special configuration needed

### Features

- **Universal compatibility**: Works with any Docker runtime (Docker Desktop, Colima, etc.)
- **Consistent environment**: Same tests run locally and in CI
- **Clear output**: Color-coded results with pass/fail indicators
- **Auto-setup**: Creates necessary directories and sets environment variables
- **Service management**: Automatically manages Docker services for tests

### Example Workflow

```bash
# 1. Enter devbox shell
devbox shell

# 2. Make code changes

# 3. Run linting
./scripts/lint.sh

# 4. Run unit tests
./scripts/test-unit.sh

# 5. Run all tests before pushing
./scripts/test.sh

# 6. Push with confidence!
git push
```

### Environment Variables

Scripts automatically set up the test environment with:
- `ENVIRONMENT=testing`
- `USE_MOCK_BLOCKCHAIN=true`
- `USE_FILE_BASED_INFRASTRUCTURE=true`
- And other necessary test configurations

### Troubleshooting

#### Permission Issues
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

#### Port Conflicts
If you get port conflicts (6379 for Redis, 8000 for API):
```bash
# Check what's using the ports
lsof -i :6379
lsof -i :8000

# Stop any running containers
docker-compose -f docker-compose.test.yml down
```

#### Docker Issues
```bash
# Ensure Docker is running
docker info

# For Colima users
colima status
```

## Configuration Testing

The CI pipeline includes comprehensive configuration validation:

1. **YAML validation**: Ensures all configuration files are valid YAML
2. **Settings loading**: Tests that configurations can be loaded without errors
3. **Environment-specific testing**: Tests different configuration scenarios
4. **Dependency validation**: Verifies all required services can be initialized

## Security Scanning

The pipeline includes security scanning with:
- **Safety**: Python dependency vulnerability scanning
- **Bandit**: Static security analysis for Python code
- **Results upload**: Security scan results are uploaded as artifacts

## Deployment Pipeline

The CI/CD pipeline supports:
- **Staging deployment**: Automatic deployment from `develop` branch
- **Production deployment**: Automatic deployment from `main` branch
- **Lambda packaging**: Creates deployment packages for AWS Lambda
- **Artifact management**: Builds and stores deployment artifacts