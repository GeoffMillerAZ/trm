# Versioning System

This directory contains the complete versioning system for the DDD Python template, organized by purpose and editability.

## Directory Structure

```
.versioning/
├── current/                   # Current version state (managed/generated files)
├── schemas/                   # CUE schemas (hand-edited)
└── tools/                     # Generation and validation tools
```

## Directory Purposes

### 📝 `current/` - Version State Files
**Purpose**: Contains the current version state and release tracking files
**Editability**: Mixed - some files are hand-edited during development, others are generated

- `VERSION` - Current semantic version (generated/managed)
- `changelog.md` - Historical release notes (generated from release.md)
- `release.md` - **HAND-EDITED** - Current development cycle release notes

### ⚙️ `schemas/` - CUE Schema Definitions
**Purpose**: Contains CUE schema files that define validation rules for versioning files
**Editability**: **HAND-EDITED** - These are the source definitions you should modify

- `version.cue` - Semantic version format validation
- `changelog.cue` - Changelog structure and entry validation  
- `release.cue` - Release notes format validation
- `validation.cue` - Combined validation functions
- `README.md` - Schema system documentation

### 🔧 `tools/` - Generation and Validation Tools
**Purpose**: Contains tools for generating, validating, and managing versioning files
**Editability**: **HAND-EDITED** - Modify these tools as needed

- `generators/` - Go-based generators and validators
- `scripts/` - Shell scripts and other utilities (future)

## Common Workflows

### Daily Development
1. **Edit release notes**: Modify `.versioning/current/release.md` for each PR
2. **Validate changes**: Run `task version:validate-all` before committing
3. **Generate new release template**: Use `task version:generate-release` when needed

### Schema Modification
1. **Edit CUE schemas**: Modify files in `.versioning/schemas/`
2. **Test validation**: Run validation tasks to ensure schemas work correctly
3. **Update generators**: Modify Go code in `.versioning/tools/generators/` if needed

### Release Management
1. **Version bumping**: Use `task version:update VERSION=x.y.z`
2. **Changelog generation**: Tools move `release.md` content to `changelog.md`
3. **Validation**: All generated files are validated against CUE schemas

## Key Principles

### 🎯 Clear Separation of Concerns
- **schemas/** = What the files should look like (validation rules)
- **current/** = What the files currently contain (actual data)
- **tools/** = How to create and validate files (automation)

### ✏️ Edit vs Generate Clarity
- **Edit these**: `schemas/*.cue`, `tools/generators/*.go`, `current/release.md`
- **Don't edit these**: `current/VERSION`, `current/changelog.md` (generated)
- **Validate everything**: Use `task version:validate-all` to ensure consistency

### 🔄 Workflow Integration
- Tasks in `taskfiles/Taskfile.cue.yml` use this structure
- Claude Code instructions reference this organization
- All tools respect the separation of editable vs generated files

This organization makes it immediately clear which files are meant to be edited versus generated, while keeping related functionality grouped together.