# Style Guide

This document defines the coding, commit message, and documentation style rules for the DDD Python Template project.

## Code Style

### Python Code Standards

- **Formatter**: Use `ruff format` for consistent code formatting
- **Linter**: Use `ruff check` for code quality enforcement  
- **Type Checker**: Use `mypy` with strict mode enabled
- **Line Length**: Maximum 88 characters (Black/Ruff standard)
- **Import Organization**: Use `ruff` import sorting (isort-compatible)

### Naming Conventions

- **Files**: Use `snake_case` for Python files
- **Classes**: Use `PascalCase` for class names
- **Functions/Variables**: Use `snake_case` for functions and variables
- **Constants**: Use `UPPER_SNAKE_CASE` for constants
- **Private Members**: Prefix with single underscore `_private_method`

### Domain-Driven Design Patterns

- **Entities**: Named with business domain terms (e.g., `User`, `Order`)
- **Value Objects**: Descriptive names ending context (e.g., `Email`, `Money`)
- **Services**: End with `Service` (e.g., `UserDomainService`)
- **Repositories**: End with `Repository` (e.g., `UserRepository`)
- **Use Cases**: Descriptive action names (e.g., `CreateUserUseCase`)

### Documentation

- **Docstrings**: Use Google-style docstrings for all public methods
- **Type Hints**: Required for all function signatures and class attributes
- **Inline Comments**: Use sparingly, prefer self-documenting code

## Commit Message Style

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

- `feat`: New feature for the user
- `fix`: Bug fix for the user
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to build process, auxiliary tools, libraries

### Scope

Use lowercase, kebab-case scopes that match project structure:
- `domain` - Domain layer changes
- `application` - Application layer changes
- `infrastructure` - Infrastructure layer changes
- `presentation` - Presentation layer changes
- `ci` - CI/CD pipeline changes
- `deps` - Dependency updates

### Examples

```
feat(domain): add user email validation
fix(infrastructure): resolve database connection pooling
docs(adr): update CUE schema decision rationale
chore(deps): update fastapi to 0.104.1
```

## Documentation Style

### Markdown Standards

- **Headers**: Use ATX-style headers (`#`, `##`, `###`)
- **Lists**: Use `-` for unordered lists, `1.` for ordered lists
- **Code Blocks**: Always specify language for syntax highlighting
- **Links**: Use reference-style links for better readability

### Architecture Decision Records (ADRs)

Follow MADR (Markdown Architecture Decision Records) format:

```markdown
# ADR-XXX: Decision Title

## Status

Accepted | Rejected | Deprecated | Superseded

## Context

Brief description of the problem and constraints.

## Decision

What we decided to do and why.

## Consequences

What becomes easier or more difficult as a result.
```

### API Documentation

- **OpenAPI**: Enrich specifications with examples and detailed descriptions
- **Code Examples**: Provide realistic, working examples
- **Error Responses**: Document all possible error scenarios
- **Authentication**: Clearly explain authentication requirements

## File Organization

### Directory Structure

Follow the established DDD layered architecture:

```
src/
├── domain/          # Core business logic
├── application/     # Use cases and DTOs  
├── infrastructure/  # External concerns
└── presentation/    # API layer
```

### Test Organization

```
tests/
├── unit/           # Fast, isolated tests
├── integration/    # Tests with external dependencies  
└── e2e/           # End-to-end API tests
```

## Configuration Files

### pyproject.toml

- Keep dependencies organized by purpose
- Use version ranges conservatively
- Document any version pinning rationale

### Taskfile Structure

- Group related tasks in separate files under `taskfiles/`
- Use descriptive task names with consistent verbs
- Include help text for all tasks

## Enforcement

These style rules are enforced through:

- **Lefthook**: Git hooks for pre-commit validation
- **CI Pipeline**: Automated checks on pull requests
- **Code Reviews**: Manual verification during review process
- **IDE Integration**: EditorConfig and tool-specific configurations

## Exceptions

Style rule exceptions require:

1. **Justification**: Clear explanation of why the exception is needed
2. **Documentation**: Inline comment explaining the deviation
3. **Review**: Approval from code owners during review process