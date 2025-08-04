# Repository Structure Guide

This document provides a comprehensive overview of the DDD Python Template repository structure, explaining the purpose and organization of every major file and directory.

## Complete Repository Structure

```
ddd-python-template/
├── README.md                           # Main project overview and quick start
├── CLAUDE.md                          # Claude Code AI assistant instructions
├── CONTRIBUTING.md                    # Contribution guidelines and workflow
├── STYLE_GUIDE.md                     # Code, commit, and documentation standards
├── Dockerfile                         # Container image for production deployment
├── docker-compose.yml                 # Multi-service development environment
├── devbox.json                        # Development environment with nix packages
├── lefthook.yml                       # Git hooks configuration (replaces pre-commit)
├── pyproject.toml                     # Python project configuration and dependencies
├── Taskfile.yml                       # Main task runner configuration
├── brainstorm.md                      # Development notes and ideas
├── .editorconfig                      # Cross-editor formatting consistency
├── .gitignore                         # Git ignore patterns
├── .devcontainer/                     # VS Code development container
│   ├── Dockerfile                     # Container image for development
│   └── devcontainer.json              # VS Code dev container configuration
├── .dev.d/                           # Development automation scripts (nushell)
│   ├── bootstrap.nu                   # Initial project setup and dependencies
│   ├── install-deps.nu                # Dependency installation and verification
│   ├── run-dev.nu                     # Development server with configuration
│   └── run-tests.nu                   # Test execution with various options
├── .github/                          # GitHub-specific configuration
│   └── CODEOWNERS                     # Automated code review assignments
├── .versioning/                      # Semantic versioning and release management
│   ├── VERSION                        # Current version (single line)
│   ├── changelog.md                   # Historical release notes
│   └── release.md                     # Draft notes for current development cycle
├── workspace/                        # Developer-local artifacts (git-ignored)
│   ├── artifacts/                     # Build outputs and generated files
│   ├── locks/                         # Coordination files for concurrent tasks
│   ├── logging/                       # Development logs and tool output
│   ├── secrets/                       # Local secrets and environment files
│   └── tmp/                           # Temporary files and scratch space
├── docs/                             # Project documentation
│   ├── adr/                          # Architectural Decision Records
│   │   ├── ADR-008-taskfile-over-makefile.md
│   │   ├── ADR-009-nushell-for-scripting.md
│   │   ├── ADR-010-cue-over-kcl-for-schema.md
│   │   ├── ADR-011-workspace-convention.md
│   │   ├── ADR-012-spec-driven-development.md
│   │   └── ADR-013-modular-examples-strategy.md
│   ├── integration-points.md          # Future modularization planning
│   └── repository-structure.md        # This document
├── examples/                         # Modular DDD pattern demonstrations
│   ├── README.md                      # Examples system overview and usage
│   └── _template/                     # Template for creating new example modules
│       ├── .example-module.yml        # Module metadata and information
│       ├── README.md                  # Module documentation template
│       ├── src/                       # DDD architecture layers template
│       │   ├── domain/                # Domain layer template
│       │   ├── application/           # Application layer template
│       │   ├── infrastructure/        # Infrastructure layer template
│       │   └── presentation/          # Presentation layer template
│       ├── tests/                     # Testing structure template
│       │   ├── unit/                  # Unit tests template
│       │   ├── integration/           # Integration tests template
│       │   └── e2e/                   # End-to-end tests template
│       └── docs/                      # Pattern and architecture documentation
│           ├── patterns.md            # DDD patterns documentation template
│           └── architecture.md        # Architecture decisions template
├── specs/                            # Spec-driven development documents
│   ├── README.md                      # Specification system overview
│   └── modular-examples-system.md     # Examples system implementation spec
├── src/                              # Main application source code
│   ├── main.py                        # FastAPI application entry point
│   ├── domain/                        # Domain-Driven Design core business logic
│   │   ├── entities/                  # Business entities with identity and behavior
│   │   │   └── user.py                # Example: User entity
│   │   ├── value_objects/             # Immutable descriptive objects
│   │   │   └── email.py               # Example: Email value object
│   │   ├── services/                  # Domain services for complex business logic
│   │   │   └── user_service.py        # Example: User domain service
│   │   └── events/                    # Domain events for business occurrences
│   │       └── user_events.py         # Example: User domain events
│   ├── application/                   # Use cases and application logic
│   │   ├── use_cases/                 # Application-specific business workflows
│   │   │   └── create_user.py         # Example: Create user use case
│   │   ├── dtos/                      # Data transfer objects for layer boundaries
│   │   │   └── user_dtos.py           # Example: User DTOs
│   │   └── services/                  # Application services for coordination
│   ├── infrastructure/                # External system integrations
│   │   ├── repositories/              # Data persistence implementations
│   │   │   └── user_repository.py     # Example: User repository
│   │   ├── adapters/                  # External service integrations
│   │   └── database/                  # Database configuration and models
│   │       ├── connection.py          # Database connection management
│   │       └── models.py              # SQLAlchemy base models
│   └── presentation/                  # HTTP API and external interfaces
│       ├── api/                       # FastAPI routes and endpoints
│       │   └── health.py              # Example: Health check endpoint
│       ├── schemas/                   # Request/response validation models
│       └── dependencies/              # Dependency injection configuration
│           ├── container.py           # DI container setup
│           └── database.py            # Database dependency provider
├── taskfiles/                        # Modular task definitions
│   ├── Taskfile.build.yml             # Build, packaging, and deployment tasks
│   ├── Taskfile.dev.yml               # Development environment and workflow
│   ├── Taskfile.test.yml              # Testing and quality assurance
│   ├── Taskfile.cue.yml               # CUE schema language operations
│   ├── Taskfile.python.yml            # Python-specific tooling
│   └── Taskfile.examples.yml          # Examples system management
└── tests/                            # Comprehensive test suite
    ├── conftest.py                    # Pytest configuration and shared fixtures
    ├── unit/                          # Fast, isolated component tests
    │   └── domain/                    # Domain layer unit tests
    │       ├── test_user.py           # User entity tests
    │       └── test_email.py          # Email value object tests
    ├── integration/                   # Cross-component tests with real dependencies
    └── e2e/                          # End-to-end API workflow tests
        └── test_health.py             # Health check API test
```

## Directory Breakdown

### Root Level Files

#### Configuration Files
- **`pyproject.toml`** - Python project configuration including dependencies, build settings, and tool configurations (ruff, mypy, pytest)
- **`devbox.json`** - Development environment specification using Nix packages for reproducible development setup
- **`Taskfile.yml`** - Main task runner configuration that orchestrates all development workflows
- **`lefthook.yml`** - Git hooks configuration for automated code quality checks (replaces pre-commit)
- **`docker-compose.yml`** - Multi-service development environment with database and application services
- **`Dockerfile`** - Container image definition for production deployment
- **`.editorconfig`** - Cross-editor formatting consistency configuration
- **`.gitignore`** - Git ignore patterns to exclude build artifacts and local files

#### Documentation Files
- **`README.md`** - Main project overview, quick start guide, and navigation hub
- **`CLAUDE.md`** - Instructions specifically for Claude Code AI assistant interactions
- **`CONTRIBUTING.md`** - Comprehensive contributor guidelines including workflow, standards, and examples system
- **`STYLE_GUIDE.md`** - Code formatting, commit message, and documentation style standards

#### Development Files
- **`brainstorm.md`** - Development notes and ideas (can be safely removed when using as template)

### Core Application Structure

#### Source Code (`src/`)
Follows Domain-Driven Design (DDD) layered architecture:

- **`main.py`** - FastAPI application entry point with ASGI server configuration
- **`domain/`** - Core business logic layer, independent of external concerns
  - **`entities/`** - Objects with identity that encapsulate business behavior
  - **`value_objects/`** - Immutable objects representing descriptive concepts
  - **`services/`** - Domain services for business logic that doesn't fit in entities
  - **`events/`** - Domain events representing important business occurrences
- **`application/`** - Use cases and application logic coordination
  - **`use_cases/`** - Application-specific business workflows
  - **`dtos/`** - Data transfer objects for crossing layer boundaries
  - **`services/`** - Application services for coordinating domain objects
- **`infrastructure/`** - Technical implementation details and external integrations
  - **`repositories/`** - Concrete implementations of domain repository interfaces
  - **`adapters/`** - Integrations with external systems and services
  - **`database/`** - Database configuration, connections, and ORM models
- **`presentation/`** - HTTP API and external communication interfaces
  - **`api/`** - FastAPI routers and endpoint definitions
  - **`schemas/`** - Pydantic models for request/response validation
  - **`dependencies/`** - Dependency injection configuration and providers

*See [ADR-001 through ADR-007] for detailed architectural decisions.*

#### Testing (`tests/`)
Comprehensive testing strategy with multiple test types:

- **`conftest.py`** - Pytest configuration and shared test fixtures
- **`unit/`** - Fast, isolated tests focusing on individual components
- **`integration/`** - Tests verifying component interactions with real dependencies
- **`e2e/`** - End-to-end tests validating complete user workflows through the API

*Testing strategy follows the Test Pyramid approach with emphasis on fast unit tests.*

### Development Tooling

#### Task System (`taskfiles/`)
Modular task definitions organized by concern ([ADR-008: Taskfile Over Makefile](docs/adr/ADR-008-taskfile-over-makefile.md)):

- **`Taskfile.build.yml`** - Build, packaging, Docker, and deployment tasks
- **`Taskfile.dev.yml`** - Development environment setup and workflow tasks
- **`Taskfile.test.yml`** - Testing execution with various options and coverage
- **`Taskfile.cue.yml`** - CUE schema language operations and validation
- **`Taskfile.python.yml`** - Python-specific tooling (lint, format, type-check)
- **`Taskfile.examples.yml`** - Examples system management and operations

#### Development Scripts (`.dev.d/`)
Nushell scripts for development automation ([ADR-009: Nushell for Scripting](docs/adr/ADR-009-nushell-for-scripting.md)):

- **`bootstrap.nu`** - Complete project setup including dependencies and git hooks
- **`install-deps.nu`** - Dependency installation with verification and conflict checking
- **`run-dev.nu`** - Development server startup with configuration options
- **`run-tests.nu`** - Test execution wrapper with multiple options and reporting

### Developer Workspace

#### Workspace Convention (`workspace/`)
Standardized local development artifacts ([ADR-011: Workspace Convention](docs/adr/ADR-011-workspace-convention.md)):

- **`artifacts/`** - Build outputs, generated files, and compilation results
- **`locks/`** - Lock files for coordinating concurrent development tasks
- **`logging/`** - Log files from development tools, scripts, and applications
- **`secrets/`** - Developer-specific secrets and environment configuration
- **`tmp/`** - Temporary files and scratch space for development work

*The entire `workspace/` directory is git-ignored but structure is preserved with `.gitkeep` files.*

### Documentation System

#### Project Documentation (`docs/`)
- **`adr/`** - Architectural Decision Records documenting key design choices
- **`integration-points.md`** - Planning document for future modularization efforts
- **`repository-structure.md`** - This comprehensive structure guide

#### Architectural Decision Records (`docs/adr/`)
- **ADR-008** - Taskfile Over Makefile for cross-platform task management
- **ADR-009** - Nushell for Scripting for modern shell automation
- **ADR-010** - CUE Over KCL for schema and infrastructure templates
- **ADR-011** - Workspace Convention for developer artifact management
- **ADR-012** - Spec-Driven Development with agent workflows
- **ADR-013** - Modular Examples Strategy for pattern demonstrations

### Examples System

#### Modular Examples (`examples/`)
Self-contained modules demonstrating DDD patterns ([ADR-013: Modular Examples Strategy](docs/adr/ADR-013-modular-examples-strategy.md)):

- **`README.md`** - Comprehensive examples system documentation and usage guide
- **`_template/`** - Template structure for creating new example modules
  - Complete DDD layer structure matching main application
  - Comprehensive documentation templates
  - Testing structure and patterns
  - Metadata format specification

*Examples can be completely removed (`rm -rf examples/`) for clean template usage.*

### Specification System

#### Spec-Driven Development (`specs/`)
Structured requirements for AI-assisted and human development ([ADR-012: Spec-Driven Development](docs/adr/ADR-012-spec-driven-development.md)):

- **`README.md`** - Specification system overview and workflow
- **Individual spec files** - Feature specifications with acceptance criteria

### Development Environment

#### Container Development (`.devcontainer/`)
VS Code development container for consistent environment:

- **`Dockerfile`** - Development container image with all tools pre-installed
- **`devcontainer.json`** - VS Code configuration and extensions

#### GitHub Integration (`.github/`)
- **`CODEOWNERS`** - Automated code review assignment based on file ownership

#### Version Management (`.versioning/`)
Semantic versioning and release management:

- **`VERSION`** - Current version string (single line)
- **`changelog.md`** - Historical release notes and version history
- **`release.md`** - Draft release notes for current development cycle

## Quick Navigation Index

### "I want to..." Scenarios

| Goal | Location | Commands |
|------|----------|----------|
| **Start developing** | `src/` | `task dev:run`, `task setup` |
| **Add a new feature** | `specs/` → `src/` | `task examples:scaffold`, create spec |
| **Run tests** | `tests/` | `task test:all`, `task test:unit` |
| **Check code quality** | Root | `task check`, `task fix` |
| **Learn DDD patterns** | `examples/` | `task examples:list`, `task examples:info` |
| **Understand architecture** | `docs/adr/` | Read ADRs, review layer structure |
| **Contribute code** | `CONTRIBUTING.md` | Follow contribution workflow |
| **Deploy application** | `Dockerfile`, `taskfiles/Taskfile.build.yml` | `task build:docker`, `task compose:up` |
| **Customize development environment** | `devbox.json`, `taskfiles/` | Modify packages, add tasks |
| **Debug issues** | `workspace/logging/`, `STYLE_GUIDE.md` | Check logs, review troubleshooting |

### Common Development Workflows

1. **Initial Setup**: `devbox shell` → `task setup` → `task dev:run`
2. **Feature Development**: Create spec → Implement in layers → Add tests → Run quality checks
3. **Code Quality**: `task check` → Fix issues → `task fix` → Commit
4. **Learning DDD**: Explore `examples/` → Study `docs/adr/` → Practice with template code
5. **Contributing**: Read `CONTRIBUTING.md` → Follow branching strategy → Submit PR

### File Relationships

- **Configuration files** → Development environment and tooling behavior
- **`src/` layers** → Business logic organization following DDD principles
- **`tests/` structure** → Mirrors `src/` organization for clear test location
- **`taskfiles/`** → Automation for all development workflows
- **`docs/adr/`** → Rationale behind all major architectural decisions
- **`examples/`** → Practical demonstrations of patterns used in `src/`

This structure provides a comprehensive foundation for Domain-Driven Design development with modern tooling, comprehensive documentation, and clear separation of concerns.