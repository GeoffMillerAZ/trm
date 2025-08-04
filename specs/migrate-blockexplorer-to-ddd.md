# Migrate TRM Block Explorer to DDD Architecture

## Goal
Migrate the existing Flask-based block explorer application to the established DDD FastAPI architecture while preserving functionality and improving maintainability.

## Context
We have a simple Flask application (`workspace/tmp/trm-blockexplorer-code`) that provides Ethereum address balance checking via Infura. This needs to be migrated to our established DDD template to serve as the foundation for enhanced TRM compliance features.

**Current Application Features:**
- `GET /address/balance/{eth_address}` - Retrieves ETH balance via Infura API
- Flask health checks at `/healthz` 
- Ethereum address validation using regex
- Structured logging with configurable log levels
- Docker containerization

**Existing DDD Template:**
- FastAPI with domain-driven architecture
- PostgreSQL with SQLAlchemy (to be replaced with DynamoDB)
- User entity example (to be replaced with blockchain entities)
- Structured logging with correlation IDs
- Health check endpoints

## Requirements

### Functional Requirements
- **Preserve API compatibility**: Existing balance endpoint must continue working
- **Domain modeling**: Convert address validation and balance concepts to DDD entities/value objects
- **Infrastructure migration**: Replace Infura direct calls with repository pattern
- **Health checks**: Maintain health check functionality with FastAPI format
- **Logging preservation**: Keep existing structured logging approach
- **Environment config**: Support Infura API key and debug mode configuration

### Non-Functional Requirements
- **Performance**: Response times must not degrade from current Flask implementation
- **Error handling**: Maintain current error responses (invalid address syntax)
- **Docker compatibility**: Must work with existing containerization approach
- **Configuration**: Environment-based configuration (DEBUG, INFURA_API_KEY)

### DDD Architecture Requirements
- **Value Objects**: `EthereumAddress` with validation logic
- **Entities**: `AddressBalance` representing the balance state
- **Domain Services**: `BlockchainService` for balance retrieval business logic
- **Infrastructure**: `InfuraBlockchainRepository` implementing repository pattern
- **Application Layer**: `GetAddressBalanceUseCase` orchestrating the flow
- **Presentation**: FastAPI router with proper validation and error handling

## Acceptance Tests

### API Compatibility Tests
- `GET /address/balance/0xc94770007dda54cF92009BFF0dE90c06F603a09f` returns balance in original format
- Invalid address `GET /address/balance/invalid` returns 400 with "invalid address syntax" message
- Health check endpoint returns 200 with service status

### DDD Architecture Tests
- `EthereumAddress` value object validates hex format with 0x prefix and 40 characters
- `EthereumAddress` raises validation error for invalid formats
- `InfuraBlockchainRepository` handles API failures gracefully
- `GetAddressBalanceUseCase` returns None for invalid addresses
- All domain entities are properly tested in isolation

### Integration Tests
- End-to-end test validates complete flow from API request to Infura response
- Error scenarios (network failures, invalid API responses) are handled appropriately
- Logging correlation IDs are maintained throughout request lifecycle

### Performance Tests
- Balance lookup completes within 2 seconds under normal conditions
- Memory usage does not exceed Flask implementation baseline
- Docker container starts within 10 seconds

## Out of Scope
- **New features**: No new functionality beyond current block explorer capabilities
- **Database persistence**: Balance data is not stored, only retrieved on-demand
- **Authentication**: No authentication or authorization required for this migration
- **Multi-region**: Single region deployment sufficient for migration
- **Caching**: No caching layer required for initial migration

## Implementation Hints

### Domain Layer Structure
```python
# src/domain/value_objects/ethereum_address.py
@dataclass(frozen=True)
class EthereumAddress:
    value: str
    
    def __post_init__(self):
        # Validate 0x + 40 hex characters pattern
        if not re.match(r'^0x[0-9A-Fa-f]{40}$', self.value):
            raise ValueError("Invalid Ethereum address format")

# src/domain/entities/address_balance.py  
@dataclass
class AddressBalance:
    address: EthereumAddress  
    balance_eth: Decimal
    retrieved_at: datetime
```

### Infrastructure Layer
```python
# src/infrastructure/repositories/blockchain_repository.py
class InfuraBlockchainRepository:
    def __init__(self, api_key: str, logger: Logger):
        self.api_key = api_key
        self.logger = logger
    
    async def get_balance(self, address: EthereumAddress) -> Decimal:
        # Implement Infura API call with error handling
        # Convert hex wei to ETH decimal
        # Log request/response for debugging
```

### Migration Strategy
1. **Start with value objects**: Implement `EthereumAddress` with validation
2. **Add domain entities**: Create `AddressBalance` for balance representation  
3. **Infrastructure layer**: Implement `InfuraBlockchainRepository`
4. **Application services**: Create `GetAddressBalanceUseCase`
5. **Presentation layer**: FastAPI router with endpoint migration
6. **Integration**: Wire dependencies and test end-to-end
7. **Docker migration**: Update Dockerfile for FastAPI/uvicorn

### Dependencies to Add
- `web3` or `requests` for Infura API calls (keep existing `requests` approach)
- `decimal` for precise ETH amount handling
- Environment configuration for `INFURA_API_KEY`

### File Structure
```
src/
├── domain/
│   ├── entities/address_balance.py
│   ├── value_objects/ethereum_address.py
│   └── services/blockchain_service.py
├── application/
│   ├── use_cases/get_address_balance.py
│   └── dtos/balance_dtos.py
├── infrastructure/
│   └── repositories/blockchain_repository.py
├── presentation/
│   └── api/blockchain.py
```

### Environment Variables
- `INFURA_API_KEY`: Required for blockchain API access
- `DEBUG`: Optional boolean for enhanced logging (default: false)
- `LOG_LEVEL`: Optional log level configuration (default: INFO)

This migration establishes the foundation for enhanced TRM compliance features while maintaining backward compatibility and improving code organization through DDD principles.