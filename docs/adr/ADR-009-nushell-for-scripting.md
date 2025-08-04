# ADR-009: Nushell for Scripting

## Status

Accepted

## Context

Development workflows require various shell scripts for automation, setup, and maintenance tasks. Traditional shell scripting (bash/zsh) has limitations in terms of error handling, data manipulation, and cross-platform compatibility.

Requirements:
- Cross-platform scripting for development tasks
- Better error handling than traditional shells
- Structured data processing capabilities
- Integration with modern development tools
- Developer-friendly syntax and debugging

## Decision

Use **Nushell** as the primary scripting language for development automation scripts in the `.dev.d/` directory.

## Alternatives Considered

1. **Bash/Zsh**: Traditional Unix shells
   - Pros: Universal availability, well-known syntax
   - Cons: Poor error handling, platform-specific behaviors, limited data manipulation

2. **PowerShell**: Cross-platform shell from Microsoft
   - Pros: Excellent object-oriented pipeline, cross-platform
   - Cons: Verbose syntax, .NET dependency, less familiar to Unix developers

3. **Python scripts**: Using Python for automation
   - Pros: Excellent data handling, familiar to team
   - Cons: Overhead for simple tasks, dependency management complexity

4. **Nushell (chosen)**: Modern shell with structured data
   - Pros: Structured data pipeline, excellent error handling, cross-platform, modern syntax
   - Cons: Newer tool, smaller community, additional dependency

## Consequences

### Positive
- **Better Error Handling**: Explicit error handling and propagation
- **Structured Data**: Native handling of JSON, YAML, CSV without external tools
- **Cross-Platform**: Consistent behavior across Linux, macOS, Windows
- **Type Safety**: Built-in type system reduces runtime errors
- **Modern Syntax**: Clean, readable syntax for complex data transformations
- **Integration**: Works well with modern tools (JSON APIs, structured configs)

### Negative
- **Learning Curve**: Team needs to learn Nushell syntax and concepts
- **Tool Availability**: Less common than bash, requires installation
- **Community**: Smaller ecosystem compared to traditional shells
- **Documentation**: Less Stack Overflow content and examples

### Neutral
- **Script Location**: All Nushell scripts in `.dev.d/` directory for organization
- **File Extension**: Use `.nu` extension for clarity
- **Fallback**: Critical scripts may need bash alternatives for CI environments

## Implementation Notes

Script organization in `.dev.d/`:
- `bootstrap.nu`: Initial project setup and dependencies
- `install-deps.nu`: Dependency management and verification  
- `run-dev.nu`: Development server startup with configuration
- `run-tests.nu`: Test execution with various options

All scripts include:
- Proper error handling with try/catch blocks
- Help documentation and parameter descriptions
- Structured output with clear status messages
- Integration with existing toolchain (uv, task, etc.)

Scripts are designed to be self-documenting and include usage examples in comments.