# HTTPie API Tests

This directory contains automated API tests using HTTPie.

## Prerequisites

- HTTPie must be installed (already included in devbox configuration)
- API must be running on the specified host

## Running Tests

### Run all tests:
```bash
# From project root
./scripts/test-httpie.sh

# Or from this directory
./run_all_tests.sh
```

### Run individual test suites:
```bash
# Health checks
./test_health.sh

# Balance endpoints
./test_balance.sh

# Edge cases and error handling
./test_edge_cases.sh

# Concurrent requests
./test_concurrent.sh
```

### Test against different hosts:
```bash
# Test local development
HOST=http://localhost:8000 ./run_all_tests.sh

# Test Docker container
HOST=http://localhost:8080 ./run_all_tests.sh

# Test staging environment
HOST=https://staging.example.com ./run_all_tests.sh

# Test with environment files (new approach)
./run_all_tests.sh --env dev                    # Dev environment
./run_all_tests.sh --env file-based             # File-based testing
./run_all_tests.sh --env local                  # Local development
```

## Environment Files

The tests now support environment files in the `envs/` directory:

- **`local.env`** - Local development (http://localhost:8000)
- **`dev.env`** - Development environment (https://api.dev.trm.geoffmiller.cloud)
- **`prod.env`** - Production environment (use with caution)
- **`mock.env`** - Mock/testing environment with controlled data
- **`file-based.env`** - File-based testing using local file implementations

### File-Based Testing

The `file-based.env` environment is designed for testing with the docker-compose.test.yml configuration. This uses:

- File-based implementations (`file_repository.py`, `file_cache.py`, etc.)
- Test data stored in `workspace/db/balances/`
- Predictable, controlled test data instead of live blockchain data
- High-performance testing (no external API calls)

Example usage:
```bash
# Start the file-based test environment
docker-compose -f docker/compose/docker-compose.test.yml up -d

# Run tests against the file-based API
./run_all_tests.sh --env file-based

# Run specific tests
./test_balance.sh --env file-based
```

## Test Structure

- **test_health.sh**: Basic health check endpoints
- **test_balance.sh**: Address balance endpoint tests with various addresses
- **test_edge_cases.sh**: Error handling and invalid input tests
- **test_concurrent.sh**: Concurrent request handling
- **run_all_tests.sh**: Main test runner that executes all test suites

## Features

- Color-coded output (green for pass, red for fail)
- Automatic API availability check
- Test summary with pass/fail counts
- Exit codes for CI/CD integration (0 for success, 1 for failure)
- Support for testing different environments via HOST variable

## HTTPie Advantages

- Clean, readable syntax
- Built-in JSON support
- Excellent error messages
- Easy to read in test scripts
- Native support for headers and authentication
