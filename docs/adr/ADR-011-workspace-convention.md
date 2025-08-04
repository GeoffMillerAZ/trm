# ADR-011: Workspace Convention for Developer Artifacts

## Status

Accepted

## Context

Development workflows generate various local artifacts that are essential for individual developers but should not be committed to version control. These include build outputs, temporary files, logs, secrets, and coordination files for concurrent development tasks.

Current challenges:
- Developers store local artifacts in inconsistent locations
- Risk of accidentally committing sensitive information
- No standard location for development scripts and utilities
- Cleanup processes are manual and inconsistent

## Decision

Implement a standardized `workspace/` directory convention for all developer-local artifacts, with the directory structure git-ignored but preserved through `.gitkeep` files.

## Directory Structure

```
workspace/
├── artifacts/     # Build outputs and generated files
├── locks/         # Lock files for coordinating concurrent tasks
├── logging/       # Log files from development tools and scripts  
├── secrets/       # Developer-specific secrets (never committed)
└── tmp/           # Short-lived scratch files
```

## Alternatives Considered

1. **No Convention**: Let developers manage their own local files
   - Pros: Maximum flexibility for individual preferences
   - Cons: Inconsistent practices, higher risk of accidental commits

2. **Hidden Directories**: Use dot-prefixed directories (`.artifacts`, `.tmp`, etc.)
   - Pros: Hidden from normal file listings
   - Cons: Less discoverable, harder to document and clean up

3. **Multiple Root Directories**: Separate directories at root level
   - Pros: Clear separation of concerns
   - Cons: Clutters root directory, harder to manage gitignore rules

4. **Workspace Directory (chosen)**: Single root-level directory for all local artifacts
   - Pros: Clear organization, single gitignore rule, easy cleanup
   - Cons: One more directory at root level

## Consequences

### Positive
- **Consistent Organization**: All developers use the same structure for local artifacts
- **Security**: Reduced risk of committing secrets with comprehensive gitignore
- **Easy Cleanup**: Single directory to clean up all development artifacts
- **Discoverable**: Clear location for development utilities and temporary files
- **Documentation**: Can document what goes where for team onboarding

### Negative
- **Enforcement**: Requires discipline to use the convention consistently
- **Migration**: Existing developers need to adapt their workflows
- **Directory Proliferation**: Adds another top-level directory

### Neutral
- **Git Handling**: `workspace/**` ignored but directory structure preserved with `.gitkeep`
- **Tool Integration**: Scripts and tools updated to use workspace directories
- **Cleanup Tasks**: Automated cleanup tasks for workspace subdirectories

## Implementation Notes

### Git Configuration
- `.gitignore` includes `workspace/**` to ignore all contents
- Each subdirectory contains `.gitkeep` to preserve directory structure
- Workspace directory survives git operations (clone, clean, etc.)

### Tool Integration
- Build tools output to `workspace/artifacts/`
- Development scripts log to `workspace/logging/`
- Concurrent tasks coordinate via `workspace/locks/`
- Local secrets stored in `workspace/secrets/`
- Temporary files use `workspace/tmp/`

### Cleanup Strategy
- `task clean` command cleans workspace subdirectories
- Automated cleanup of old logs and temporary files
- Secrets directory preserved during cleanup operations
- Lock files cleaned when safe (no active processes)

This convention provides a clean separation between project code and developer-local artifacts while maintaining a consistent development experience across the team.