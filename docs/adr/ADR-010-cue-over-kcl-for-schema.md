# ADR-010: CUE Over KCL for Schema and Infrastructure Templates

## Status

Superseded by ADR-016 (Pydantic for API Schemas)

**Note**: This ADR has been superseded for API schema validation. CUE may still be considered for infrastructure templating if needed, but Pydantic has been chosen for Python API schema definition.

## Context

Our FastAPI application today will evolve to include Kubernetes deployments and Terraform/Pulumi infrastructure configurations tomorrow. We need a unified schema language that can handle both domain data validation and infrastructure templating effectively.

Key requirements:
- Schema validation for API contracts and domain models
- Infrastructure as Code templating capabilities
- Integration with CI/CD pipelines and developer workflows
- Strong ecosystem support for cloud-native tools
- Maintainable configuration management

## Decision

Adopt **CUE** (Configure, Unify, Execute) as our schema language and access it via the CLI rather than Python bindings.

## Alternatives Considered

1. **KCL with kcl-lib**: CNCF sandbox configuration language
   - Pros: Strong CNCF backing, object-oriented features, static compilation
   - Cons: Newer ecosystem, limited tooling integration, smaller community

2. **Hybrid Approach**: Different tools for different use cases
   - Pros: Best tool for each job
   - Cons: Multiple languages to maintain, inconsistent validation patterns

3. **CUE (chosen)**: Data constraint language with infrastructure focus
   - Pros: Mature ecosystem for infrastructure templating, excellent CLI tooling
   - Cons: Weaker Python SDK, requires extra glue code for runtime validation

## Consequences

### Positive
- **Unified Language**: Single language for domain data and deployment specifications
- **Infrastructure Mature**: Strong ecosystem for Kubernetes, Terraform, and cloud-native tools
- **CLI Integration**: Excellent CLI tools integrate cleanly with GitHub Actions and devbox tasks
- **Validation Power**: Powerful constraint system for complex data validation
- **Tooling Ecosystem**: Rich set of tools for formatting, validation, and generation

### Negative
- **Runtime Integration**: Extra glue code needed for runtime validation in Python tests
- **Learning Curve**: Team needs to learn CUE's unique "types are values" philosophy
- **Python SDK**: Less mature Python integration compared to CLI tools

### Neutral
- **CLI-First Approach**: Use `cue` CLI commands rather than language bindings
- **File Organization**: CUE schemas alongside relevant code for maintainability
- **CI Integration**: CUE validation as part of CI pipeline for contract verification

## Implementation Notes

### File Organization
- Domain schemas: `src/domain/schemas/*.cue`
- API contracts: `src/presentation/schemas/*.cue` 
- Infrastructure: `infra/*.cue` (when added)
- Validation helpers: `tests/schemas/` for runtime validation glue code

### Tooling Integration
- `task cue:format` - Format CUE files
- `task cue:vet` - Validate CUE schemas
- `task cue:export:json` - Generate JSON schemas for OpenAPI
- CI pipeline validation for schema changes

### Runtime Validation Strategy
Since we're using CLI over Python bindings, runtime validation will require:
1. Export CUE schemas to JSON Schema format
2. Use Python JSON Schema libraries for runtime validation
3. Generate validation helpers from CUE definitions
4. Cache generated schemas to minimize CLI overhead

This approach provides the best of both worlds: CUE's powerful constraint system for development and standard JSON Schema for runtime performance.