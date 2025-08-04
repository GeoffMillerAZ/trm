# Versioning Tools

This directory contains tools for generating, validating, and managing versioning files.

## Directory Structure

```
tools/
├── generators/                # Go-based generators and validators
│   ├── main.go               # Main generator program
│   ├── go.mod               # Go module dependencies
│   └── README.md            # Generator documentation
└── scripts/                 # Shell scripts and utilities (future)
```

## Tools Available

### 🚀 `generators/` - Go-Based Tools
**Purpose**: Generate, validate, and update versioning files using CUE schemas  
**Language**: Go with CUE integration  
**Editability**: **HAND-EDITED** - Modify these tools as needed

#### Available Commands
```bash
# From .versioning/tools/generators/ directory
go run main.go validate-version "1.0.0"
go run main.go generate-release "../../current/release.md"
go run main.go update-version "1.0.1" "../../current/VERSION"
go run main.go generate-changelog-entry "1.0.0" "$(cat ../../current/release.md)"
```

#### Task Integration
```bash
# Use via task system (recommended)
task version:validate-all        # Validate all files
task version:generate-release    # Generate new release.md
task version:update VERSION=1.0.1  # Update VERSION file
```

### 📝 `scripts/` - Shell Scripts (Future)
**Purpose**: Additional utilities and automation scripts  
**Status**: Directory prepared for future shell scripts, automation tools, etc.

## Development

### Modifying Generators
1. **Edit Go code**: Modify `generators/main.go` and related files
2. **Test changes**: Run commands directly or via tasks
3. **Update dependencies**: Use `go mod tidy` in generators directory
4. **Update documentation**: Keep READMEs current with functionality

### Adding New Tools
1. **Go tools**: Add to `generators/` directory
2. **Scripts**: Add to `scripts/` directory  
3. **Integration**: Update tasks in `taskfiles/Taskfile.cue.yml`
4. **Documentation**: Update relevant README files

## Integration Points

### With CUE Schemas
- Generators use schemas from `../schemas/` for validation
- Schema changes automatically affect generator behavior
- Validation functions are centralized in schemas

### With Task System
- All tools integrated with Taskfile automation
- Consistent interface via `task version:*` commands
- Cross-platform compatibility through Go and tasks

### With Development Workflow
- Tools validate files before commits (via git hooks)
- Generate templated files for consistent formatting
- Automate version bumping and changelog generation

## Best Practices

### 🎯 Tool Design
- **Validate first**: Always validate input before generating output
- **Use schemas**: Leverage CUE schemas for consistency
- **Error clearly**: Provide clear error messages for validation failures
- **Stay atomic**: Tools should succeed completely or fail cleanly

### 🔧 Maintenance
- **Keep dependencies current**: Regular `go mod tidy` and updates
- **Test thoroughly**: Test with various inputs and edge cases
- **Document changes**: Update READMEs when adding functionality
- **Version tools**: Consider versioning tools if they become complex

This tools directory provides the automation needed to maintain consistent, validated versioning files while keeping the implementation details separate from the schemas and current state.