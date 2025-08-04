# Testing ECR Image Locally with Mock Data

## Quick Start

1. **Login to ECR** (to pull the image):
   ```bash
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 754419183698.dkr.ecr.us-west-2.amazonaws.com
   ```

2. **Start the services**:
   ```bash
   docker-compose -f docker/compose/docker-compose.ecr-test.yml up
   ```

3. **Wait for initialization** - The `dynamodb-init` container will create tables and insert test data.

## Available Services

Once running, you'll have access to:

- **API**: http://localhost:8080 (changed from 8000 to avoid conflicts)
- **DynamoDB Admin**: http://localhost:8012 (changed from 8002)
- **Redis Commander**: http://localhost:8013 (changed from 8003)

## Testing Endpoints

### Health Check
```bash
curl http://localhost:8080/health
```

### Get Address Balance (using mock data)
```bash
# Test with the mock address that has data
curl http://localhost:8080/address/balance/0x742d35Cc6634C0532925a3b844Bc9e7595f62b0e
```

### Watchlist Operations
```bash
# Get all watchlist addresses
curl http://localhost:8080/watchlist/addresses

# Add address to watchlist
curl -X POST http://localhost:8080/watchlist/addresses \
  -H "Content-Type: application/json" \
  -d '{
    "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    "label": "Test Address 2",
    "risk_score": 50
  }'
```

## Mock Data Structure

The mock blockchain data is stored in `test-data/mock-blockchain/`:

```
test-data/mock-blockchain/
├── addresses/
│   ├── 0x742d35Cc6634C0532925a3b844Bc9e7595f62b0e.json
│   └── 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48.json
└── transactions/
    └── (transaction files if needed)
```

## Adding More Mock Data

To add more test addresses, create JSON files in `test-data/mock-blockchain/addresses/` with this format:

```json
{
  "address": "0x...",
  "balance": "1000000000000000000",
  "transactionCount": 10,
  "lastActivity": "2024-01-15T10:30:00Z",
  "transactions": [...]
}
```

## Viewing Data

1. **DynamoDB Admin** (http://localhost:8012):
   - View all tables
   - Query and scan data
   - Add/edit/delete items

2. **Redis Commander** (http://localhost:8013):
   - View cached data
   - Monitor cache hits/misses

## Debugging

1. **View API logs**:
   ```bash
   docker-compose -f docker/compose/docker-compose.ecr-test.yml logs -f trm-api
   ```

2. **Access API container**:
   ```bash
   docker-compose -f docker/compose/docker-compose.ecr-test.yml exec trm-api sh
   ```

3. **Check environment variables**:
   ```bash
   docker-compose -f docker/compose/docker-compose.ecr-test.yml exec trm-api env | grep -E "(TABLE|MOCK|BLOCKCHAIN)"
   ```

## Cleanup

```bash
# Stop and remove containers
docker-compose -f docker/compose/docker-compose.ecr-test.yml down

# Remove volumes too
docker-compose -f docker/compose/docker-compose.ecr-test.yml down -v
```

## Troubleshooting

1. **ECR Pull Issues**: Make sure you're logged in to ECR
2. **Port Conflicts**: Check if ports 8080, 8011, 8012, 8013, 6380 are free
3. **Table Creation Errors**: The `|| true` in the init script ignores errors if tables already exist
4. **Mock Data Not Found**: Verify the volume mount and file paths are correct