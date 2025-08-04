# ADR-015: API Migration Strategy from Flask to FastAPI

## Status

Accepted

## Context

The TRM Block Explorer currently uses a simple Flask application with basic Ethereum address balance checking functionality. We need to migrate this to our established Domain-Driven Design (DDD) FastAPI architecture while preserving existing functionality and enabling future compliance features.

**Current Flask Application:**
- Single endpoint: `GET /address/balance/{eth_address}`
- Direct Infura API integration via requests
- Basic Ethereum address validation using regex
- Flask-healthz for health checks
- Structured logging with configurable levels

**Target FastAPI Architecture:**
- Domain-driven design with clean architecture boundaries
- Repository pattern for external service integration
- Comprehensive validation using Pydantic schemas
- Dependency injection for testability
- Integration with DynamoDB for compliance features

**Migration Constraints:**
- Must maintain backward compatibility for existing clients
- Cannot break existing API contracts during transition
- Need to support both Flask and FastAPI during migration period
- Must preserve performance characteristics
- Maintain existing Docker containerization approach

## Decision

Implement a **gradual migration strategy** that preserves API compatibility while transitioning to the DDD FastAPI architecture in phases.

**Migration Approach:**
1. **Parallel Implementation**: Build FastAPI endpoints alongside existing Flask app
2. **Backward Compatibility**: Maintain exact API response formats and error codes
3. **Progressive Cutover**: Migrate endpoints one at a time with feature flags
4. **Domain Integration**: Gradually introduce DDD patterns and domain modeling
5. **Infrastructure Transition**: Move from direct Infura calls to repository pattern

## Alternatives Considered

### 1. Big Bang Migration
- **Pros**: Clean transition, immediate benefits of new architecture
- **Cons**: High risk, potential downtime, difficult rollback, extensive testing required
- **Verdict**: Too risky for production compliance system

### 2. API Gateway Routing
- **Pros**: External routing between Flask and FastAPI, independent deployments
- **Cons**: Additional infrastructure complexity, network latency, split deployment concerns
- **Verdict**: Over-engineered for single application migration

### 3. Flask to FastAPI with Breaking Changes
- **Pros**: Opportunity to improve API design, modern standards
- **Cons**: Breaks existing clients, requires client updates, violates compatibility requirement
- **Verdict**: Unacceptable due to compatibility constraints

### 4. Gradual Migration with Compatibility (Chosen)
- **Pros**: Low risk, maintains compatibility, allows testing in production, easy rollback
- **Cons**: Temporary code duplication, longer migration timeline, complexity during transition
- **Verdict**: Best balance of safety and progress

### 5. Maintain Flask, Add FastAPI for New Features
- **Pros**: Zero migration risk, quick new feature development
- **Cons**: Permanent technical debt, dual framework maintenance, architectural inconsistency
- **Verdict**: Acceptable fallback but not preferred long-term solution

## Migration Strategy

### Phase 1: Infrastructure Foundation (Week 1-2)
**Objectives:**
- Set up FastAPI application structure within existing project
- Implement domain entities and value objects for blockchain concepts
- Create repository interfaces and infrastructure adapters
- Establish dependency injection container

**Implementation:**
```python
# Parallel FastAPI app setup
app_fastapi = FastAPI(title="TRM Block Explorer API v2")
app_flask = Flask(__name__)  # Existing Flask app remains

# Domain entities
@dataclass
class EthereumAddress:
    value: str
    # Validation logic

@dataclass  
class AddressBalance:
    address: EthereumAddress
    balance_eth: Decimal
    retrieved_at: datetime

# Repository pattern
class BlockchainRepository(ABC):
    @abstractmethod
    async def get_balance(self, address: EthereumAddress) -> Decimal: ...

class InfuraBlockchainRepository(BlockchainRepository):
    # Implementation maintains existing Infura integration
```

**Acceptance Criteria:**
- FastAPI application starts successfully alongside Flask
- Domain entities validate Ethereum addresses correctly
- Repository pattern abstracts Infura API calls
- All existing functionality continues working via Flask

### Phase 2: API Compatibility Layer (Week 3-4)
**Objectives:**
- Implement FastAPI endpoint with identical response format
- Create compatibility middleware for consistent error handling
- Add feature flag mechanism for A/B testing
- Establish monitoring for both endpoints

**Implementation:**
```python
# FastAPI endpoint with Flask compatibility
@router.get("/address/balance/{eth_address}")
async def get_balance_fastapi(
    eth_address: str,
    use_case: GetAddressBalanceUseCase = Depends()
) -> Dict[str, Any]:  # Exact same response format as Flask
    try:
        result = await use_case.execute(eth_address)
        return {"balance": result.balance_eth}  # Match Flask format exactly
    except ValueError:
        # Match Flask error response exactly
        raise HTTPException(400, {"error": "invalid address syntax"})

# Feature flag routing
@app.middleware("http")
async def route_by_feature_flag(request: Request, call_next):
    if should_use_fastapi(request):
        # Route to FastAPI handler
        return await fastapi_handler(request)
    else:
        # Route to Flask handler  
        return await flask_handler(request)
```

**Acceptance Criteria:**
- FastAPI endpoint returns identical JSON structure as Flask
- Error messages and HTTP status codes match exactly
- Feature flag allows gradual traffic migration
- Response times within 5% of Flask baseline

### Phase 3: Domain Logic Migration (Week 5-6)
**Objectives:**
- Migrate business logic to domain services and use cases
- Replace direct Infura calls with repository pattern
- Add comprehensive logging and error handling
- Implement domain events for future extensibility

**Implementation:**
```python
# Use case orchestration
class GetAddressBalanceUseCase:
    def __init__(self, blockchain_repo: BlockchainRepository):
        self._blockchain_repo = blockchain_repo
    
    async def execute(self, address_str: str) -> AddressBalanceResult:
        # Domain validation
        address = EthereumAddress(address_str)  # Validates format
        
        # Repository call
        balance = await self._blockchain_repo.get_balance(address)
        
        # Create domain entity
        return AddressBalance(
            address=address,
            balance_eth=balance,
            retrieved_at=datetime.utcnow()
        )

# Preserve exact Flask error handling
class AddressValidationError(ValueError):
    """Matches Flask validation error behavior exactly"""
    pass
```

**Acceptance Criteria:**
- All business logic migrated to domain layer
- Repository pattern completely abstracts Infura integration
- Error handling preserves Flask behavior exactly
- Domain events prepared for compliance features

### Phase 4: Traffic Migration (Week 7-8)
**Objectives:**
- Gradually shift traffic from Flask to FastAPI using feature flags
- Monitor performance and error rates during migration
- Implement rollback procedures for each migration step
- Validate end-to-end functionality under production load

**Implementation:**
```python
# Progressive traffic migration
def should_use_fastapi(request: Request) -> bool:
    # Start with 10% traffic, increase gradually
    traffic_percentage = get_feature_flag("fastapi_traffic_percentage", 10)
    user_hash = hash(request.client.host) % 100
    return user_hash < traffic_percentage

# Monitoring and alerting
@app.middleware("http")
async def migration_metrics(request: Request, call_next):
    endpoint_version = "fastapi" if should_use_fastapi(request) else "flask"
    
    with metrics.timer(f"request_duration_{endpoint_version}"):
        response = await call_next(request)
    
    metrics.increment(f"requests_total_{endpoint_version}")
    return response
```

**Acceptance Criteria:**
- Traffic successfully migrated in 25%, 50%, 75%, 100% increments
- No degradation in response times or error rates
- Rollback procedures tested and functional
- All monitoring dashboards show consistent metrics

### Phase 5: Flask Removal (Week 9-10)
**Objectives:**
- Remove Flask application code and dependencies
- Clean up temporary migration infrastructure
- Update deployment and monitoring configurations
- Document final architecture and lessons learned

**Implementation:**
```python
# Remove Flask app and routes
# app_flask = Flask(__name__)  # DELETE

# Clean up feature flag middleware
# @app.middleware("http")
# async def route_by_feature_flag(...):  # DELETE

# Finalize FastAPI as primary application
app = FastAPI(
    title="TRM Block Explorer API",
    description="Ethereum address analysis for compliance operations",
    version="2.0.0"
)
```

**Acceptance Criteria:**
- Flask code completely removed from codebase
- All dependencies updated to FastAPI requirements only
- Performance meets or exceeds original Flask baseline
- Documentation updated for new architecture

## Consequences

### Positive
- **Zero Downtime**: Gradual migration ensures continuous service availability
- **Risk Mitigation**: Easy rollback at each phase reduces deployment risk
- **Performance Validation**: Can compare Flask vs FastAPI performance during migration
- **Client Compatibility**: Existing clients continue working without changes
- **Architecture Benefits**: Gain DDD benefits while preserving functionality
- **Future Ready**: Foundation established for compliance feature development

### Negative
- **Temporary Complexity**: Dual application support increases code complexity
- **Extended Timeline**: Gradual approach takes longer than big bang migration
- **Resource Overhead**: Running both Flask and FastAPI temporarily increases resource usage
- **Testing Burden**: Must test both implementations during migration period
- **Feature Flag Management**: Additional operational complexity for traffic routing

### Neutral
- **Code Duplication**: Temporary duplication of endpoint logic during migration
- **Monitoring Complexity**: Need separate metrics for Flask and FastAPI during transition
- **Deployment Coordination**: Must coordinate between old and new application components
- **Documentation**: Need to maintain documentation for both versions temporarily

## Implementation Guidelines

### API Compatibility Requirements
```python
# REQUIRED: Exact response format preservation
# Flask response
{"balance": 1000.5}

# FastAPI response (MUST match exactly)
{"balance": 1000.5}

# REQUIRED: Exact error format preservation  
# Flask error
{"error": "invalid address syntax"}

# FastAPI error (MUST match exactly)
{"error": "invalid address syntax"}
```

### Feature Flag Configuration
```python
# Environment-based feature flags
FASTAPI_TRAFFIC_PERCENTAGE=10  # Start with 10%
FASTAPI_ENABLED=true
FLASK_FALLBACK_ENABLED=true
```

### Monitoring and Alerting
- Separate dashboards for Flask and FastAPI during migration
- Alert on response time degradation > 20%
- Alert on error rate increase > 5%
- Monitor memory and CPU usage for both applications

### Rollback Procedures
- **Phase 1-2**: Disable FastAPI feature flag, route all traffic to Flask
- **Phase 3-4**: Reduce traffic percentage, monitor for stability
- **Phase 5**: Restore from backup if critical issues discovered

This migration strategy ensures zero-downtime transition to the modern FastAPI architecture while maintaining backward compatibility and enabling future compliance feature development.