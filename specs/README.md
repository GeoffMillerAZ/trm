# Specifications Directory

This directory contains specification files for agent-driven development workflows.

## What is a Spec File?

A spec file is a Markdown document that serves as the authoritative requirements document for AI-driven coding tasks. It follows a structured format to ensure clear communication between humans and AI agents.

## When to Create a Spec File

Create a spec file when:

- **Cross-file change**: The task touches more than one file/module
- **New feature**: End-to-end behavior not yet in code
- **Non-trivial refactor**: Affects public API or architecture
- **External contract**: Other teams or agents consume the output
- **AI loop**: Planning to run autonomous or batch agent workflows

## Spec File Format

Each spec file should include these sections:

### 1. Title/Goal
One-sentence summary of what needs to be accomplished.

### 2. Context
- Why this matters
- Existing constraints
- Links to design docs or related issues

### 3. Requirements
Bullet list of must-haves (functional and non-functional).

### 4. Acceptance Tests
How success is measured:
- CLI commands to verify
- Unit test outlines
- Screenshot descriptions
- Performance criteria

### 5. Out of Scope
Anything the agent must not change or implement.

### 6. Implementation Hints (Optional)
- Suggested libraries
- Naming conventions
- File paths
- Architecture guidance

## Example Spec File

```markdown
# Add User Authentication

## Goal
Implement JWT-based user authentication for the FastAPI application.

## Context
Currently the API has no authentication. We need to secure endpoints and provide user session management for the upcoming admin features.

## Requirements
- JWT token generation and validation
- User login/logout endpoints
- Protected route decorator
- Token refresh mechanism
- Password hashing with bcrypt

## Acceptance Tests
- POST /auth/login returns valid JWT token
- Protected endpoints return 401 without valid token
- Token refresh works before expiration
- All existing tests continue to pass

## Out of Scope
- User registration (separate feature)
- OAuth integration
- Password reset functionality

## Implementation Hints
- Use python-jose for JWT handling
- Store tokens in HTTP-only cookies
- Follow existing DDD architecture patterns
```

## Best Practices

1. **Keep it focused**: One concern per spec file
2. **Be specific**: Use clear, measurable acceptance criteria
3. **Stay current**: Update specs based on implementation learnings
4. **Archive old specs**: Move completed specs to `specs/archive/` directory
5. **Version specs**: Use `_v2`, `_v3` suffixes for evolving requirements

## Workflow

1. Create spec file: `specs/feature-name.md`
2. Review and approve spec before implementation
3. Reference spec in pull requests
4. Update spec if requirements change during development
5. Archive spec after successful implementation

## File Naming

Use descriptive, lowercase names with hyphens:
- `add-user-authentication.md`
- `implement-rate-limiting.md`
- `refactor-domain-events.md`
- `api-versioning-strategy.md`