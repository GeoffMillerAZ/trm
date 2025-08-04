# Release Notes - Development Cycle

## Added
- CUE schema validation system for versioning files in .versioning/schema/
- Go-based generators for versioning file creation and validation
- Task integration for version validation (task version:validate-all)
- Comprehensive .guidance/ directory with organizational patterns
- Spec-driven development workflow documentation in .guidance/spec/
- Version management tasks (validate, generate, update) integrated with CUE schemas
- Go 1.21 runtime to devbox configuration for versioning generators
- Environment validation script (.dev.d/env-check.nu) with comprehensive checks
- Smart dependency management in .dev.d/install-deps.nu with Go workspace setup
- Enhanced bootstrap script (.dev.d/bootstrap.nu) with full project validation
- Task system integration with portable .dev.d/ scripts for cross-environment support

## Changed
- Reorganized .versioning/ directory structure for clarity (schemas/, current/, tools/)
- Devbox configuration simplified with portable .dev.d/ scripts instead of complex init_hook
- Task system now uses .dev.d/ scripts for consistent cross-environment behavior
- Development environment setup now portable across devbox, devcontainer, and local development

## Fixed

## Security

## Deprecated

## Removed

---

**Instructions:**

- Add entries under the appropriate category when submitting PRs
- Use present tense ("Add user authentication" not "Added user authentication")
- Include context when necessary for clarity
- At release time, these entries will be moved to changelog.md with proper version and date
