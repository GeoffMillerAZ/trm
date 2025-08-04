# Versioning Schema

This directory contains CUE schemas for validating and generating versioning files in this repository.

## Schema Files

### `version.cue`
- Defines semantic version format validation
- Validates VERSION file format (single line version string)
- Ensures proper semantic versioning compliance

### `changelog.cue` 
- Defines complete changelog structure
- Validates changelog entries and format
- Ensures chronological ordering of releases
- Validates change entry descriptions and formatting

### `release.cue`
- Defines release notes structure for development cycle
- Validates release.md file format and sections
- Ensures proper entry formatting and present tense usage

### `validation.cue`
- Provides validation functions for all file types
- Defines validation results and error reporting
- Combines individual schemas for complete validation

## Usage

### Validate VERSION file
```bash
cue eval -c ./schema/validation.cue -e "#ValidateVersion" --arg input "$(cat ../VERSION)"
```

### Validate changelog.md
```bash
cue eval -c ./schema/validation.cue -e "#ValidateChangelog" --arg input "$(cat ../changelog.md)"
```

### Validate release.md
```bash
cue eval -c ./schema/validation.cue -e "#ValidateRelease" --arg input "$(cat ../release.md)"
```

### Generate new release template
```bash
# Future: Generate new release.md with proper structure
cue export ./schema/release.cue -e "#ReleaseNotes" --out yaml > ../release.md.template
```

## Integration with Tasks

These schemas are integrated with the task system:

- `task version:validate` - Validate all versioning files
- `task version:generate` - Generate new version files from templates
- `task release:validate` - Validate release notes format
- `task changelog:validate` - Validate changelog format

## Future Enhancements

- Go code generators for creating new versioning files
- Automated changelog generation from release notes
- Git hook integration for validation
- CI/CD pipeline integration for release automation