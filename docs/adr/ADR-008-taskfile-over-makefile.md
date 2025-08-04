# ADR-008: Taskfile Over Makefile

## Status

Accepted

## Context

Build automation and task management are essential for developer productivity and CI/CD pipelines. The traditional choice has been Makefiles, but modern alternatives offer better developer experience and cross-platform compatibility.

Key considerations:
- Need for cross-platform compatibility (developers use various OS)
- Complex task dependencies and parallel execution
- Integration with modern development tools (devbox, CI/CD)
- Developer onboarding and documentation
- Task discoverability and help systems

## Decision

Adopt **Taskfile** (go-task) as our task runner instead of traditional Makefiles.

## Alternatives Considered

1. **Makefile**: Traditional choice, universally available
   - Pros: Universal availability, well-known syntax
   - Cons: Platform-specific behaviors, limited built-in help, complex dependency management

2. **npm scripts**: JavaScript ecosystem standard
   - Pros: Good for Node.js projects, simple syntax
   - Cons: Requires Node.js, not ideal for Python projects

3. **Just**: Modern command runner
   - Pros: Simple syntax, good cross-platform support
   - Cons: Less mature ecosystem, smaller community

4. **Taskfile (chosen)**: YAML-based task runner
   - Pros: Cross-platform, excellent documentation, parallel execution, built-in help
   - Cons: Additional dependency (mitigated by devbox)

## Consequences

### Positive
- **Better Developer Experience**: Built-in help system (`task --list`), clear YAML syntax
- **Cross-Platform Compatibility**: Works identically on Linux, macOS, Windows
- **Modular Organization**: Split tasks across multiple files (`taskfiles/` directory)
- **Modern Features**: Parallel execution, dependency management, variable substitution
- **Integration**: Works well with devbox, CI/CD systems, and modern tooling

### Negative
- **Additional Dependency**: Requires task binary (handled by devbox)
- **Learning Curve**: Team needs to learn Taskfile YAML syntax
- **Migration Effort**: Need to convert existing Makefile tasks

### Neutral
- **File Structure**: Organized task files in `taskfiles/` directory for different concerns
- **Naming Convention**: Clear task naming with colons for namespacing (`dev:run`, `test:unit`)

## Implementation Notes

Task organization:
- `Taskfile.yml`: Main orchestration and common tasks
- `taskfiles/Taskfile.dev.yml`: Development workflow tasks
- `taskfiles/Taskfile.test.yml`: Testing and quality assurance
- `taskfiles/Taskfile.build.yml`: Build and deployment tasks
- `taskfiles/Taskfile.cue.yml`: CUE language specific tasks
- `taskfiles/Taskfile.python.yml`: Python tooling tasks

All tasks include descriptive help text and follow consistent naming patterns.