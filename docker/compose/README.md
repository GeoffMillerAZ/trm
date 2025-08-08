# Docker Compose Test Infrastructure

This directory contains a unified Docker Compose setup that supports multiple testing configurations for the TRM Block Explorer API.

## Quick Start

```bash
# Run tests in mock mode (no external dependencies)
./scripts/run-tests.sh mock

# Run tests against real AWS development environment
./scripts/run-tests.sh dev

# Run tests with real Infura blockchain
export INFURA_API_KEY="your-api-key"
./scripts/run-tests.sh wan
```

## Available Profiles

### 1. Mock Mode (`mock`)
- **Purpose**: Quick local testing with no external dependencies
- **Infrastructure**:
  - Blockchain: In-memory mock
  - Database: In-memory mock
  - Cache: In-memory mock
- **Use Case**: Unit tests, CI/CD pipelines
- **Command**: `./scripts/run-tests.sh mock`

### 2. File-Based Mode (`file-based`)
- **Purpose**: Testing with persistent file storage
- **Infrastructure**:
  - Blockchain: File-based mock with test data
  - Database: File-based storage
  - Cache: File-based storage
- **Use Case**: Testing data persistence without external services
- **Command**: `./scripts/run-tests.sh file-based`

### 3. Services Mode (`services`)
- **Purpose**: Testing with real Docker services
- **Infrastructure**:
  - Blockchain: In-memory mock
  - Database: DynamoDB (Docker)
  - Cache: Redis (Docker)
- **Use Case**: Integration testing with real services
- **Command**: `./scripts/run-tests.sh services`

### 4. WAN Mode (`wan`)
- **Purpose**: Testing with real blockchain data
- **Infrastructure**:
  - Blockchain: Infura API (real Ethereum mainnet)
  - Database: DynamoDB (Docker)
  - Cache: Redis (Docker)
- **Requirements**: `INFURA_API_KEY` environment variable
- **Use Case**: End-to-end testing with real blockchain
- **Command**: 
  ```bash
  export INFURA_API_KEY="your-api-key"
  ./scripts/run-tests.sh wan
  ```

### 5. Dev Mode (`dev`)
- **Purpose**: Testing against AWS development environment
- **Infrastructure**:
  - API Endpoint: https://api.trm.geoffmiller.cloud
  - No local services required
- **Use Case**: Testing from workstation against deployed dev environment
- **Command**: `./scripts/run-tests.sh dev`

## Test Output

When running tests, you'll see:

1. **Test Configuration Summary**
   ```
   === Test Configuration ===
   Mode: wan
   API Endpoint: http://localhost:8000
   Blockchain: Infura (mainnet)
   Database: DynamoDB (docker)
   Cache: Redis (docker)
   ```

2. **Individual Test Results**
   ```
   Test: Get Balance for Ethereum 2.0 Deposit Contract
   Expected: ~36.6M ETH
   Actual: 36668162.325 ETH
   Result: ✓ PASS
   ```

3. **Final Summary**
   ```
   === Test Summary ===
   Total Tests: 6
   Passed: 5
   Failed: 1
   Success Rate: 83.3%
   ```

## Directory Structure

```
docker/compose/
├── README.md                    # This file
├── docker-compose.unified.yml   # Main compose file with all profiles
├── envs/                        # Environment configurations
│   ├── mock.env                # Mock mode configuration
│   ├── file-based.env          # File-based mode configuration
│   ├── services.env            # Services mode configuration
│   ├── wan.env                 # WAN mode configuration
│   └── dev.env                 # Dev mode configuration
└── scripts/                    # DynamoDB initialization scripts
    └── init-dynamodb.sh
```

## Running Specific Tests

```bash
# Run only balance tests in mock mode
./scripts/run-tests.sh mock test_get_address_balance.sh

# Run only block tests in wan mode
./scripts/run-tests.sh wan test_get_block_by_hash.sh

# Run all tests in dev mode
./scripts/run-tests.sh dev
```

## Environment Variables

### Common Variables
- `API_PORT`: Port to expose the API (default: 8000)
- `LOG_LEVEL`: Logging level (default: DEBUG)
- `DEBUG`: Enable debug mode (default: true)

### WAN Mode Specific
- `INFURA_API_KEY`: Required for WAN mode
- `INFURA_NETWORK`: Ethereum network (default: mainnet)

### Services/WAN Mode Specific
- `DYNAMODB_ENDPOINT`: DynamoDB endpoint
- `DYNAMODB_TABLE_NAME`: Table name for blockchain data
- `REDIS_URL`: Redis connection URL

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose -f docker/compose/docker-compose.unified.yml logs api

# Clean up and retry
docker-compose -f docker/compose/docker-compose.unified.yml down -v
```

### Tests timing out
- Increase timeout in test scripts
- Check if services are healthy: `docker ps`
- Verify environment variables are set correctly

### Permission issues
- Ensure Docker daemon is running
- Check file permissions on scripts
- Run with appropriate user permissions

## Adding New Test Modes

1. Create a new environment file in `envs/` directory
2. Add a new profile to `docker-compose.unified.yml`
3. Update the test runner script to handle the new mode
4. Document the new mode in this README