# ADR-013: Modular Examples Over Integrated Examples

## Status

Accepted

## Context

Template repositories face a fundamental tension between being comprehensive learning resources and practical starting points for new projects. Users need to see real implementations of Domain-Driven Design patterns, but they also need a clean slate when starting their own projects.

Key challenges:
- **Learning vs. Template Usage**: Rich examples help understanding but clutter new projects
- **Cleanup Complexity**: Removing integrated examples requires careful extraction from core code
- **Maintenance Overhead**: Examples mixed with template code create maintenance burden
- **Flexibility**: Different projects need different example patterns

Traditional approaches:
1. **Minimal Templates**: Clean but provide little guidance on implementation patterns
2. **Rich Integrated Examples**: Great for learning but difficult to remove cleanly
3. **Separate Repositories**: Clean separation but fragmented learning experience
4. **Branch-Based**: Multiple branches for different needs but complex to maintain

## Decision

Implement a **modular examples system** using a dedicated `examples/` directory containing self-contained, independent example modules that demonstrate specific DDD patterns.

## Architecture

### Directory Structure
```
examples/
├── README.md                    # Examples system overview
├── _template/                   # Template for creating new example modules
│   ├── README.md
│   ├── .example-module.yml      # Module metadata
│   ├── src/                     # Example source code
│   ├── tests/                   # Example tests
│   └── docs/                    # Example documentation
└── [future-modules]/            # Individual example modules
    ├── user-management/         # Complete CRUD with auth
    ├── file-handling/           # Upload/download patterns
    ├── notification-system/     # Event-driven architecture
    └── reporting/               # Data aggregation patterns
```

### Module Principles
- **Self-Contained**: Each module includes everything needed to understand and run the example
- **Independent**: Modules can be used individually or in combination
- **Layered**: Examples follow the same DDD architecture as the template
- **Testable**: Full test coverage demonstrating testing patterns
- **Documented**: Clear explanation of patterns and decisions

## Alternatives Considered

1. **Integrated Examples**: Examples mixed with template code
   - Pros: Single coherent codebase, realistic relationships
   - Cons: Difficult to remove cleanly, pollutes template, maintenance complexity

2. **Branch-Based Strategy**: Different branches for different example levels
   - Pros: Clean separation, GitHub template supports multiple branches
   - Cons: Fragmented maintenance, complex branch management, user confusion

3. **Separate Repository**: Examples in completely separate repository
   - Pros: Complete separation, independent versioning
   - Cons: Fragmented learning experience, synchronization challenges

4. **Modular System (chosen)**: Self-contained modules in `examples/` directory
   - Pros: Easy removal, flexible learning, maintainable, clear separation
   - Cons: Some code duplication, slightly more complex organization

## Consequences

### Positive
- **Clean Template Usage**: Delete `examples/` directory for clean template
- **Flexible Learning**: Users can explore relevant patterns incrementally
- **Easy Maintenance**: Examples are independent and testable in isolation
- **Clear Boundaries**: No confusion between template and example code
- **Scalable**: Can add new examples without affecting existing template or examples

### Negative
- **Code Duplication**: Some infrastructure code duplicated across modules
- **Coordination Overhead**: Need to keep examples aligned with template architecture
- **Initial Setup Cost**: More upfront work to create modular structure

### Neutral
- **Module Discovery**: Task-based system for listing and managing examples
- **Documentation Strategy**: Each module self-documents its patterns and usage
- **Testing Strategy**: Examples include comprehensive tests as learning aids

## Implementation Strategy

### Phase 1: Foundation
- Create `examples/` directory structure
- Develop module template and guidelines
- Add basic task integration for module management
- Document the system in core template documentation

### Phase 2: Core Examples (Future)
- `user-management`: Complete CRUD with authentication
- `file-handling`: Upload/download with validation
- `notification-system`: Domain events and messaging
- `reporting`: Data aggregation and complex queries

### Phase 3: Advanced Examples (Future)
- `multi-tenant`: Tenant isolation patterns
- `audit-logging`: Event sourcing and audit trails
- `integration-patterns`: External API integration
- `performance-optimization`: Caching and optimization patterns

## Usage Patterns

### For Learning DDD
1. Explore examples directory
2. Choose relevant patterns for your domain
3. Study implementation and tests
4. Adapt patterns to your specific needs

### For New Projects
1. Use GitHub template to create new repository
2. Delete `examples/` directory entirely
3. Template remains clean and ready for development
4. Reference archived examples if needed later

### For Specific Patterns
1. Browse available modules with `task examples:list`
2. Study specific pattern implementation
3. Copy and adapt relevant code to your domain
4. Remove examples when no longer needed

This modular approach provides the best of both worlds: rich learning resources that don't interfere with practical template usage, and a clear path for both learning and production development.