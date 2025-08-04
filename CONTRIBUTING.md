# Contributing Guide

Thank you for your interest in contributing to the DDD Python Template! This guide outlines our development workflow, standards, and processes.

## Development Setup

### Prerequisites

- [Devbox](https://www.jetify.com/devbox) for development environment
- Git with LFS support
- Access to repository (appropriate permissions)

### Getting Started

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/ddd-python-template.git
   cd ddd-python-template
   ```

2. **Enter Development Environment**
   ```bash
   devbox shell
   ```

3. **Install Dependencies**
   ```bash
   uv sync
   ```

4. **Install Git Hooks**
   ```bash
   task hooks:install
   ```

5. **Verify Setup**
   ```bash
   task test
   task lint
   ```

## Development Workflow

### Branching Strategy

We use **GitHub Flow** with the following conventions:

- **`main`**: Production-ready code, always deployable
- **Feature branches**: `feature/short-description` or `feat/short-description`
- **Bug fixes**: `fix/short-description` or `bugfix/short-description`
- **Documentation**: `docs/short-description`
- **Chores**: `chore/short-description`

### Making Changes

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/add-user-authentication
   ```

2. **Make Changes**
   - Follow the [Style Guide](./STYLE_GUIDE.md)
   - Write tests for new functionality
   - Update documentation as needed

3. **Test Your Changes**
   ```bash
   task test:all
   task lint:check
   task type:check
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat(domain): add user authentication"
   ```

5. **Push and Create PR**
   ```bash
   git push origin feature/add-user-authentication
   ```

### Pull Request Process

1. **Create Pull Request**
   - Use descriptive title following commit message format
   - Fill out the PR template completely
   - Link to relevant issues or specs

2. **PR Requirements**
   - [ ] All tests pass
   - [ ] Code coverage maintained or improved
   - [ ] Documentation updated
   - [ ] CHANGELOG entry added (if applicable)
   - [ ] Approved by code owners

3. **Review Process**
   - Address reviewer feedback promptly
   - Keep discussions focused and professional
   - Update PR based on feedback

4. **Merge**
   - Squash and merge for feature branches
   - Use meaningful commit message for merge

## Code Standards

### Quality Requirements

- **Test Coverage**: Maintain >90% code coverage
- **Type Safety**: All code must pass `mypy --strict`
- **Linting**: All code must pass `ruff check`
- **Formatting**: All code must be formatted with `ruff format`

### Domain-Driven Design

Follow DDD principles:

- **Domain Layer**: Pure business logic, no external dependencies
- **Application Layer**: Orchestrates domain objects, defines use cases  
- **Infrastructure Layer**: External concerns (database, APIs, etc.)
- **Presentation Layer**: HTTP API, serialization, input validation

### Testing Strategy

- **Unit Tests**: Fast, isolated tests for domain logic
- **Integration Tests**: Test layer interactions with real dependencies
- **End-to-End Tests**: Full API workflow tests
- **Contract Tests**: API contract validation

## Versioning and Releases

### Semantic Versioning

We follow [SemVer](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Release Process

1. **Update Version**
   ```bash
   echo "1.2.0" > .versioning/current/VERSION
   ```

2. **Update Changelog**
   - Move entries from `.versioning/current/release.md` to `.versioning/current/changelog.md`
   - Clear `release.md` for next development cycle

3. **Create Release PR**
   ```bash
   git checkout -b chore/release-1.2.0
   git commit -m "chore: prepare release 1.2.0"
   ```

4. **Tag Release**
   ```bash
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin v1.2.0
   ```

### Changelog Entries

Every PR should add an entry to `.versioning/current/release.md`:

```markdown
### Added
- New user authentication system

### Changed  
- Improved error handling in API responses

### Fixed
- Database connection timeout issue

### Security
- Updated dependencies to address CVE-2023-12345
```

## Issue and Feature Management

### Issue Templates

Use appropriate issue templates:

- **Bug Report**: For reporting bugs
- **Feature Request**: For suggesting new features
- **Question**: For asking questions
- **Documentation**: For documentation improvements

### Spec-Driven Development

For complex features:

1. **Create Spec File**
   ```bash
   touch specs/add-user-authentication.md
   ```

2. **Define Requirements**
   - Title/Goal
   - Context
   - Requirements
   - Acceptance Tests
   - Out of Scope
   - Implementation Hints

3. **Review Spec**
   - Get feedback before implementation
   - Ensure alignment with architecture

4. **Implement According to Spec**
   - Reference spec in PR
   - Validate against acceptance criteria

## Code of Conduct

### Our Standards

- **Be Respectful**: Treat all contributors with respect
- **Be Constructive**: Focus on helping improve the project
- **Be Inclusive**: Welcome contributors from all backgrounds
- **Be Professional**: Maintain professional communication

### Unacceptable Behavior

- Harassment, discrimination, or hate speech
- Personal attacks or inflammatory comments
- Publishing private information without consent
- Any behavior inappropriate in a professional setting

### Enforcement

Code of conduct violations will be handled by project maintainers. Consequences may include warnings, temporary bans, or permanent bans from the project.

## Contributing Examples

The project includes a modular examples system for demonstrating DDD patterns. Examples are self-contained modules in the `examples/` directory.

### Creating New Example Modules

1. **Plan the Example**
   - Create a specification in `specs/` for complex examples
   - Document which DDD patterns will be demonstrated
   - Define learning objectives and target complexity level

2. **Create the Module**
   ```bash
   task examples:scaffold -- your-example-name
   ```

3. **Implement the Example**
   - Follow the DDD architecture layers (domain, application, infrastructure, presentation)
   - Include comprehensive tests demonstrating testing patterns
   - Add clear documentation explaining the patterns used

4. **Validate and Test**
   ```bash
   task examples:validate -- your-example-name
   task test:all  # Ensure all tests pass
   ```

### Example Module Standards

- **Self-Contained**: No dependencies on other examples
- **Well-Documented**: Clear README with learning objectives
- **Comprehensive Tests**: Unit, integration, and e2e tests
- **Realistic Scenarios**: Business scenarios that justify the patterns
- **Focused Scope**: 1-3 related DDD patterns per module

### Example Module Structure
Follow the template in `examples/_template/` for consistent organization and documentation standards.

## Getting Help

### Resources

- **Documentation**: Check `CLAUDE.md` and project docs
- **Examples**: Explore `examples/` directory for DDD pattern demonstrations  
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Use GitHub Discussions for questions
- **Code Review**: Learn from feedback on your PRs

### Contact

- **Maintainers**: See `CODEOWNERS` file
- **Questions**: Open a GitHub Discussion
- **Security Issues**: See `SECURITY.md` for responsible disclosure

## License and Copyright

### Contributor License Agreement

By contributing to this project, you agree that:

- Your contributions are your original work
- You grant the project rights to use your contributions
- Your contributions are provided under the project's license terms

### Copyright Notice

All contributions become part of the project under the MIT License. Ensure any new files include appropriate copyright notices.

---

Thank you for contributing to the DDD Python Template! Your efforts help make this project better for everyone.