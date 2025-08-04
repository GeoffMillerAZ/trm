# ADR-016: Pydantic for API Schema Definition and Validation

## Status

Accepted

## Context

Our FastAPI application requires comprehensive schema definition for API request/response validation, automatic OpenAPI documentation generation, and type safety. We previously considered CUE (Configure, Unify, Execute) in ADR-010 but have reconsidered this decision based on practical development experience and team needs.

**Current Requirements:**
- Schema validation for API contracts (request/response)
- Automatic OpenAPI/Swagger documentation generation
- Type safety with full IDE support and autocompletion
- Integration with Python ecosystem and FastAPI framework
- Simple development workflow without external tooling dependencies
- Clear error messages and validation feedback

**API Context:**
- FastAPI-based REST API with blockchain balance checking functionality
- Need for structured error responses with detailed validation messages
- Request/response models with comprehensive field documentation
- Support for future API endpoint expansion (watchlists, investigations, etc.)

## Decision

Adopt **Pydantic** as our primary schema definition and validation library, replacing the previously planned CUE implementation.

## Rationale

### Why Pydantic Over CUE

**Native Python Integration:**
- Pydantic is designed specifically for Python and integrates seamlessly with FastAPI
- No external CLI tools or build steps required
- Full Python type hints provide immediate IDE support and autocompletion
- Runtime validation happens naturally within Python execution context

**FastAPI Ecosystem Benefits:**
- Automatic OpenAPI schema generation from Pydantic models
- Built-in request/response validation with detailed error messages
- Native support for complex data types (Decimal, datetime, enums)
- Seamless integration with dependency injection and middleware

**Developer Experience:**
- Immediate validation feedback during development
- No context switching between schema language and implementation
- Standard Python debugging and testing tools work naturally
- Familiar Python patterns and conventions

**Maintenance and Learning Curve:**
- Team already familiar with Python and Pydantic patterns
- No additional language or tooling to learn and maintain
- Extensive documentation and community support
- Mature ecosystem with proven production usage

### Technical Comparison

| Aspect | Pydantic | CUE |
|--------|----------|-----|
| **Integration** | Native Python, zero setup | Requires CLI tools, JSON Schema generation |
| **Type Safety** | Full Python type hints | Requires export to JSON Schema |
| **IDE Support** | Complete autocompletion | Limited Python IDE integration |
| **Validation** | Runtime Python validation | CLI validation + runtime glue code |
| **Documentation** | Automatic OpenAPI generation | Manual OpenAPI integration |
| **Debugging** | Native Python debugging | Multi-tool debugging complexity |
| **Team Familiarity** | High (Python developers) | Low (new language to learn) |

## Alternatives Considered

### 1. CUE with CLI Integration (Previously Chosen)
- **Pros**: Powerful constraint language, infrastructure templating capabilities
- **Cons**: Additional tooling complexity, learning curve, Python integration overhead
- **Verdict**: Over-engineered for Python API schema needs

### 2. JSON Schema with Python Libraries
- **Pros**: Standard format, tool ecosystem support
- **Cons**: Verbose schema definition, limited Python integration, manual code generation
- **Verdict**: More complex than Pydantic without additional benefits

### 3. Plain Python Dataclasses
- **Pros**: Simple, no dependencies, native Python
- **Cons**: No automatic validation, manual OpenAPI integration, limited type coercion
- **Verdict**: Insufficient for comprehensive API validation needs

### 4. Pydantic (Chosen)
- **Pros**: Native FastAPI integration, automatic validation, excellent developer experience
- **Cons**: Python-specific solution (not reusable for infrastructure)
- **Verdict**: Perfect fit for Python API development

## Implementation

### Schema Organization
```python
# src/application/dtos/blockchain_dtos.py
class BalanceRequest(BaseModel):
    address: str = Field(
        ...,
        description="Ethereum address to check balance for",
        example="0xc94770007dda54cF92009BFF0dE90c06F603a09f",
        regex=r"^0x[0-9A-Fa-f]{40}$"
    )

class BalanceResponse(BaseModel):
    address: str
    balance_eth: Decimal = Field(..., ge=0)
    retrieved_at: datetime
    source: str = Field(..., enum=["cache", "blockchain"])
    
    class Config:
        json_encoders = {Decimal: lambda v: float(v)}
```

### Error Handling
```python
class ErrorResponse(BaseModel):
    error: str
    error_code: str
    details: Optional[list[ErrorDetail]] = None
    request_id: Optional[str] = None
```

### FastAPI Integration
```python
@router.get(
    "/address/{eth_address}/balance",
    response_model=BalanceResponse,
    responses={
        400: {"model": ErrorResponse},
        503: {"model": ErrorResponse}
    }
)
async def get_balance(eth_address: str = Path(..., regex=r"^0x[0-9A-Fa-f]{40}$")):
    # Automatic validation and OpenAPI generation
```

## Consequences

### Positive
- **Rapid Development**: Immediate productivity with familiar Python patterns
- **Type Safety**: Full IDE support with comprehensive type checking
- **Automatic Documentation**: OpenAPI schemas generated automatically from models
- **Error Handling**: Rich validation errors with field-level detail
- **Testing**: Standard Python testing patterns apply naturally
- **Maintenance**: Single language and toolchain reduces complexity

### Negative
- **Infrastructure Limitation**: Pydantic schemas not reusable for Kubernetes/Terraform
- **Python-Specific**: Cannot share schemas with non-Python services
- **Runtime Validation**: Validation happens at runtime rather than compile-time

### Neutral
- **Ecosystem Lock-in**: Tied to Python/FastAPI ecosystem (acceptable for this project)
- **Future Migration**: Can export to JSON Schema if needed for cross-language compatibility

## Migration from CUE

Since CUE implementation was not yet started, this ADR represents a course correction rather than a migration:

1. **Remove CUE specifications**: Delete planned CUE schema specifications
2. **Remove CUE tooling**: Clean up Taskfile and development environment configuration
3. **Enhance Pydantic models**: Implement comprehensive validation and documentation
4. **Update ADR-010**: Mark as superseded by this decision

## Success Metrics

- **Development Velocity**: API schema changes can be implemented and tested within minutes
- **Documentation Quality**: Comprehensive OpenAPI documentation auto-generated
- **Error Clarity**: Validation errors provide clear, actionable feedback
- **Type Safety**: Zero schema-related runtime errors in production
- **Team Productivity**: New team members can contribute to API schemas immediately

This decision prioritizes practical development efficiency and team productivity over theoretical schema language capabilities, aligning with our goal of building maintainable Python APIs efficiently.