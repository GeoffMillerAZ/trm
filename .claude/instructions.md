# Claude Code Customization Instructions

## Project Context
This is a Domain-Driven Design (DDD) Python template project that serves as a comprehensive starting point for building scalable, maintainable Python applications using DDD principles.

## .claude/instructions System
- Use `.claude/instructions.md` for project-specific Claude Code guidance and workflow instructions
- Reference specific sections of this file for focused context during development
- Keep instructions up-to-date with actual project patterns and requirements
- This file serves as the authoritative source for development practices and patterns

## Dependency Management
### Development Environment
- **Use devbox** for development environment management (includes Python 3.11 and all tools)
- **No virtual environments needed** - devbox provides isolated development shell
- **Enter development environment**: `devbox shell`

### Python Package Management
- **Use uv** for all Python package management operations
- **Install dependencies**: `uv sync` (installs from pyproject.toml)
- **Add new package**: `uv add package-name`
- **Add dev dependency**: `uv add --dev package-name`
- **Run Python commands**: `uv run python script.py`
- **Update dependencies**: `uv lock --upgrade`

### Package Management Workflow
1. Always work within `devbox shell` environment
2. Use `uv sync` after pulling changes that modify dependencies
3. Use `uv add` instead of pip install for new packages
4. Commit both `pyproject.toml` and `uv.lock` files
5. No need to manage virtual environments manually

## Spec-Driven Development (.guidance/spec/)
### CRITICAL WORKFLOW - Always Follow This Process

**Before making ANY code changes:**

1. **Consult relevant spec files** in `.guidance/spec/` directory
2. **Check for conflicts**: If proposed change contradicts existing spec
   - Discuss with team before proceeding
   - Update spec file first to reflect new requirements
   - Get approval for spec changes before implementation
3. **Check for coverage**: If proposed change is not covered in spec files
   - Create or update relevant spec files FIRST
   - Include detailed requirements and acceptance criteria
   - Review spec changes before proceeding with code
4. **Spec files are authoritative** - they define the intended behavior and architecture

### Spec File Types
- **Feature specs**: Detailed requirements for new features
- **Architecture specs**: System design and integration patterns
- **API specs**: Endpoint definitions and contract specifications
- **Domain specs**: Business logic and domain model requirements

### Spec Validation Process
- Always reference the relevant spec when implementing features
- If implementation reveals spec gaps, update specs immediately
- Specs should be reviewed and approved like code changes
- Use specs as the basis for testing and validation

## Release Management (.versioning/current/release.md)
### PR-Based Release Notes

**Every PR must update `.versioning/current/release.md` with changes made:**

1. **Add entries** under appropriate category when submitting PRs
2. **Use present tense** ("Add user authentication" not "Added user authentication")  
3. **Include context** when necessary for clarity
4. **Categories available**:
   - Added: New features and capabilities
   - Changed: Modifications to existing functionality
   - Fixed: Bug fixes and corrections
   - Security: Security-related improvements
   - Deprecated: Features marked for future removal
   - Removed: Features that have been removed

### Release Process
- During development: All changes go to `current/release.md`
- At release time: Entries move to `current/changelog.md` with proper version and date
- Keep `current/release.md` current with each PR to maintain accurate release notes

### Version Validation and Management
**CUE Schema Validation System** (`.versioning/schemas/`):

1. **Validate versioning files**: `task version:validate-all`
   - Validates VERSION file format (semantic versioning)
   - Validates changelog.md structure and content
   - Validates release.md format and sections

2. **Generate versioning files**: 
   - `task version:generate-release` - Create new release.md template
   - Go generators available in `.versioning/tools/generators/`

3. **Version management tasks**:
   - `task version:update VERSION=1.0.1` - Update VERSION file with validation
   - `task version:bump-patch|minor|major` - Semantic version bumping (planned)

4. **Schema files**:
   - `version.cue` - Semantic version format validation
   - `changelog.cue` - Changelog structure and entry validation
   - `release.cue` - Release notes format validation
   - `validation.cue` - Combined validation functions

## Coding Style & Preferences
- Follow PEP 8 for Python code formatting
- Use type hints consistently for all function signatures
- Prefer composition over inheritance
- Follow DDD principles and patterns throughout the codebase
- Use ruff for code formatting and linting
- Use mypy for static type checking

## Architecture Guidelines
### DDD Layer Organization
- **Domain Layer** (`src/domain/`): Core business logic, independent of external concerns
  - Entities: Objects with identity and business behavior
  - Value Objects: Immutable descriptive objects
  - Domain Services: Business logic that doesn't fit in entities
  - Domain Events: Important business occurrences
- **Application Layer** (`src/application/`): Use cases and workflow coordination
  - Use Cases: Application-specific business workflows
  - DTOs: Data transfer objects for layer boundaries
  - Application Services: Coordinate domain objects for complex workflows
- **Infrastructure Layer** (`src/infrastructure/`): Technical implementation details
  - Repositories: Data persistence implementations
  - Adapters: External system integrations
  - Database: ORM models and connection management
- **Presentation Layer** (`src/presentation/`): HTTP API and external interfaces
  - API routes: FastAPI endpoint definitions
  - Schemas: Request/response validation models
  - Dependencies: Dependency injection configuration

### Design Principles
- Maintain clear separation between layers
- Use dependency injection consistently (dependency-injector)
- Keep business logic in domain entities and services
- Use repository pattern for all data access
- Follow SOLID principles throughout

## Testing Approach
### Testing Strategy
- **Unit Tests** (`tests/unit/`): Fast, isolated tests for domain logic
- **Integration Tests** (`tests/integration/`): Cross-component tests with real dependencies
- **End-to-End Tests** (`tests/e2e/`): Complete API workflow tests

### Testing Standards
- Follow AAA pattern (Arrange, Act, Assert)
- Maintain high test coverage (>90% for domain logic)
- Use pytest fixtures for test setup
- Mock external dependencies in unit tests
- Use real dependencies in integration tests

### Test Execution
- Run all tests: `task test:all`
- Run specific test types: `task test:unit`, `task test:integration`, `task test:e2e`
- Run with coverage: `task test:coverage`

## Documentation Standards
### Code Documentation
- Use docstrings for all public methods and classes (Google style)
- Include type hints for all function signatures
- Document complex business logic and algorithms
- Keep inline comments focused on "why" not "what"

### Project Documentation
- Keep README.md current with setup and usage instructions
- Document architectural decisions in ADRs (`docs/adr/`)
- Update repository structure documentation when adding new components
- Maintain examples system documentation for pattern demonstrations

### Documentation Workflow
- Update relevant documentation with each significant change
- Review documentation changes as part of code review process
- Ensure documentation stays aligned with actual implementation

## Development Workflow
### Task System
- Use Taskfile for all development operations
- Available task categories:
  - `task dev:*` - Development environment and workflow
  - `task test:*` - Testing operations
  - `task build:*` - Build and deployment
  - `task examples:*` - Examples system management
  - `task python:*` - Python-specific tooling

### Code Quality
- Run quality checks: `task check` (linting, formatting, type checking)
- Auto-fix issues: `task fix` (formatting, import sorting)
- Use lefthook for automated git hooks
- Maintain consistent code style across the project

### Git Workflow
- Follow conventional commit format for commit messages
- Update `.versioning/current/release.md` with each PR
- Use meaningful branch names that reflect the feature or fix
- Keep commits focused and atomic

## Custom Instructions
### Examples System Usage
- Use `task examples:list` to see available pattern demonstrations
- Reference examples when implementing similar patterns
- For clean template usage, remove `examples/` directory entirely
- Create new examples following the template in `examples/_template/`

### Workspace Convention
- Use `workspace/` directory for all local development artifacts
- Keep secrets in `workspace/secrets/`
- Use `workspace/tmp/` for temporary files
- Log files go to `workspace/logging/`
- Build artifacts go to `workspace/artifacts/`

### AI-Assisted Development
- Always consult relevant specs before implementation
- Reference ADRs when making architectural decisions
- Use the repository structure guide for navigation
- Follow the established patterns and conventions consistently

