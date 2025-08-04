# Modular Examples System Implementation

## Goal
Implement a modular examples system that provides self-contained DDD pattern demonstrations without polluting the core template.

## Context
The DDD Python template needs to balance being a learning resource with being a practical starting point for new projects. Current approach has examples integrated into the core template, making cleanup complex.

Decision made in ADR-013 to use modular examples in `examples/` directory that can be completely removed for clean template usage.

## Requirements

### Core Structure
- `examples/` directory at repository root containing all example modules
- Each module is completely self-contained with src, tests, and documentation
- Module template (`examples/_template/`) for creating new examples
- Clear separation between template code and example code
- Easy removal: delete `examples/` directory leaves clean template

### Module Standards
- Each module demonstrates 1-3 related DDD patterns
- Follow same architectural layers as main template (domain, application, infrastructure, presentation)
- Include comprehensive tests demonstrating testing patterns
- Self-documenting with clear README and inline documentation
- Independent: can be understood and run without other modules

### Task Integration
- `task examples:list` - Show available example modules
- `task examples:info MODULE` - Display module information and usage
- Support for future `task examples:install` and `task examples:remove` commands
- Integration with existing task system and documentation

### Documentation Integration
- Examples system documented in main README
- Each module has comprehensive README with learning objectives
- Integration with CONTRIBUTING.md for example contributions
- Links to relevant ADRs and architectural decisions

## Acceptance Tests

- [ ] `ls examples/` shows clean directory structure with README and _template
- [ ] `examples/_template/` contains complete template for new modules
- [ ] `task examples:list` returns available modules (initially just template)
- [ ] `task examples:info _template` shows template information
- [ ] Module metadata format defined and documented
- [ ] `rm -rf examples/` leaves template completely clean and functional
- [ ] All existing tests continue to pass
- [ ] Documentation updated in CLAUDE.md and CONTRIBUTING.md

## Out of Scope

- Implementation of specific example modules (user-management, file-handling, etc.)
- Automated installation/removal of individual modules
- Module dependency management
- Module versioning or compatibility tracking
- Integration with package managers or external repositories

## Implementation Hints

### Directory Structure
```
examples/
├── README.md                    # System overview and usage guide
├── _template/                   # Template for new modules
│   ├── README.md               # Module template documentation
│   ├── .example-module.yml     # Metadata format specification
│   ├── src/                    # Example source code structure
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── presentation/
│   ├── tests/                  # Example test structure
│   │   ├── unit/
│   │   ├── integration/
│   │   └── e2e/
│   └── docs/                   # Additional documentation
└── .gitkeep                    # Preserve directory if empty
```

### Metadata Format (.example-module.yml)
```yaml
name: "Template Module"
description: "Template for creating new example modules"
complexity: "beginner"  # beginner, intermediate, advanced
patterns:
  - "Module Structure"
  - "Documentation Standards"
dependencies: []
learning_objectives:
  - "Understand module organization"
  - "Follow template conventions"
estimated_time: "30 minutes"
```

### Task Implementation
- Add `examples:` namespace to main Taskfile.yml
- Create dedicated taskfile for examples management
- Use file system operations to discover available modules
- Parse metadata files to provide rich information display

### Integration Points
- Link from main README to examples system
- Reference in CONTRIBUTING.md for adding new examples
- Update CLAUDE.md with examples usage patterns
- Consider future integration with spec-driven development workflow