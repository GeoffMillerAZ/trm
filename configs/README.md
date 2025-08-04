# Configuration Files

This directory contains YAML configuration files for different deployment scenarios. These files provide a structured way to manage environment-specific settings beyond simple environment variables.

## Available Configurations

### `local-dev-mocks.yaml`
**Purpose**: Local development using mock services  
**Use Case**: Initial development, testing new features without external dependencies

**Key Features:**
- File-based infrastructure (no external services required)
- Mock blockchain API responses
- Debug logging enabled
- No caching for immediate feedback
- Workspace-based storage (workspace/ directory)

**Usage:**
```bash
export CONFIG_FILE=configs/local-dev-mocks.yaml
python -m src.main
```

### `local-dev-docker.yaml` 
**Purpose**: Local development using Docker services  
**Use Case**: Development with realistic service dependencies

**Key Features:**
- Redis caching enabled
- DynamoDB Local
- Real Infura API integration (requires API key)
- JSON logging format
- Prometheus metrics enabled

**Prerequisites:**
```bash
# Start services
docker run -d -p 6379:6379 redis:7-alpine
docker run -d -p 8000:8000 amazon/dynamodb-local:latest

# Set required environment variables
export INFURA_API_KEY=your_actual_key
export CONFIG_FILE=configs/local-dev-docker.yaml
```

### `test.yaml`
**Purpose**: Testing environments with AWS services  
**Use Case**: CI/CD testing, staging environments

**Key Features:**
- Full AWS integration (DynamoDB, Secrets Manager, X-Ray)
- Goerli testnet for safe blockchain testing
- Enhanced monitoring and logging
- Production-like configurations with test data

**Prerequisites:**
```bash
# AWS credentials required
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export INFURA_API_KEY=your_test_key
export CONFIG_FILE=configs/test.yaml
```

### `production.yaml`
**Purpose**: Production deployment  
**Use Case**: Live production workloads

**Key Features:**
- Full AWS production services
- Mainnet blockchain access
- Comprehensive monitoring and alerting
- Security-hardened configurations
- Multi-region support

**Prerequisites:**
```bash
# Production AWS credentials and secrets
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export INFURA_API_KEY=your_production_key
export CONFIG_FILE=configs/production.yaml
```

## Configuration Structure

Each configuration file follows this structure:

```yaml
# Environment identification
environment: "local|development|staging|production|testing"
debug: true|false

# API settings
api_title: "Application Title"
api_version: "2.0.0"
api_description: "API Description"

# Infrastructure backend selection
use_file_based_infrastructure: true|false
cache_enabled: true|false
secrets_backend: "environment|aws|file"
tracing_backend: "console|xray|silent"

# Service configurations
redis_url: "redis://localhost:6379"
dynamodb_endpoint: "http://localhost:8000"  # null for AWS
aws_region: "us-west-2"

# Logging and monitoring
log_level: "DEBUG|INFO|WARNING|ERROR"
log_format: "text|json"
enable_cloudwatch_logging: true|false
metrics_enabled: true|false

# Security and limits
rate_limit_enabled: true|false
rate_limit_requests_per_minute: 60
api_cors_origins: ["http://localhost:3000"]
```

## Usage Patterns

### Development Workflow

1. **Start with mocks** for rapid development:
   ```bash
   export CONFIG_FILE=configs/local-dev-mocks.yaml
   python -m src.main
   ```

2. **Move to Docker** for integration testing:
   ```bash
   docker-compose up -d redis dynamodb-local
   export CONFIG_FILE=configs/local-dev-docker.yaml
   python -m src.main
   ```

3. **Test with real services** before deployment:
   ```bash
   export CONFIG_FILE=configs/test.yaml
   # Set AWS credentials
   python -m src.main
   ```

### CI/CD Integration

GitHub Actions automatically uses appropriate configurations:
- **Pull Requests**: `local-dev-mocks.yaml` for unit tests
- **Integration Tests**: `local-dev-docker.yaml` with Docker services
- **Staging**: `test.yaml` with AWS test resources
- **Production**: `production.yaml` with production AWS resources

### Environment Variable Override

Configuration files can reference environment variables:

```yaml
# In config file
infura_api_key: "${INFURA_API_KEY}"
redis_password: "${REDIS_PASSWORD}"

# Environment variables take precedence
export INFURA_API_KEY=your_key
export REDIS_PASSWORD=your_password
```

## Configuration Validation

The application validates configuration on startup:

1. **Schema validation**: Ensures all required fields are present
2. **Type validation**: Checks data types and ranges
3. **Dependency validation**: Verifies service configurations are compatible
4. **Environment-specific validation**: Applies different rules per environment

**Example validation errors:**
```
Configuration validation failed:
  - infura_api_key is required for non-local environments
  - redis_url is required when caching is enabled
  - aws_region is required for production
```

## Adding New Configurations

To add a new configuration scenario:

1. **Create YAML file** in `configs/` directory
2. **Follow naming convention**: `{environment}-{purpose}.yaml`
3. **Include all required fields** (see existing files as templates)
4. **Test configuration loading**:
   ```bash
   export CONFIG_FILE=configs/your-new-config.yaml
   python -c "from src.infrastructure.config.settings import create_settings; create_settings(config_file='configs/your-new-config.yaml', validate=True)"
   ```
5. **Update documentation** if needed

## Best Practices

### Security
- **Never commit secrets** to configuration files
- **Use environment variable substitution** for sensitive values
- **Separate public and private configurations**

### Maintainability
- **Use descriptive names** for configuration files
- **Document purpose and prerequisites** in comments
- **Keep configurations DRY** - extract common patterns

### Testing
- **Validate all configurations** in CI/CD
- **Test configuration loading** in automated tests
- **Use mock configurations** for unit tests

### Performance
- **Optimize for environment** (e.g., smaller memory limits for dev)
- **Enable appropriate caching** per environment
- **Configure logging levels** appropriately

## Troubleshooting

### Configuration Not Loading
```bash
# Check file exists and is readable
ls -la configs/your-config.yaml

# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('configs/your-config.yaml'))"

# Test configuration loading
python -c "
from src.infrastructure.config.settings import create_settings
try:
    settings = create_settings(config_file='configs/your-config.yaml', validate=True)
    print('Configuration loaded successfully')
except Exception as e:
    print(f'Error: {e}')
"
```

### Environment Variable Substitution Issues
```bash
# Check environment variables are set
env | grep -E "(INFURA|AWS|REDIS)"

# Test substitution manually
python -c "
import os
import yaml
with open('configs/your-config.yaml') as f:
    content = f.read()
    # Simple variable substitution test
    print(content.replace('${INFURA_API_KEY}', os.getenv('INFURA_API_KEY', 'NOT_SET')))
"
```

### Service Connection Issues
```bash
# Test Redis connection
redis-cli -h localhost -p 6379 ping

# Test DynamoDB Local
curl -f http://localhost:8000/

# Check AWS credentials
aws sts get-caller-identity
```

## Migration Guide

### From Environment Variables Only

If you're currently using only `.env` files:

1. **Create YAML configuration** based on your current `.env`
2. **Set CONFIG_FILE environment variable**
3. **Gradually migrate settings** from `.env` to YAML
4. **Keep sensitive values** in environment variables

### From Hardcoded Settings

If you have hardcoded configuration values:

1. **Identify all hardcoded values** in your codebase
2. **Move them to appropriate YAML files**
3. **Update code** to use settings from configuration
4. **Test each environment** thoroughly

The configuration system provides a flexible, maintainable way to manage application settings across different environments while maintaining security and ease of use.