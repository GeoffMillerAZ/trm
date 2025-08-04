# Current Version State

This directory contains the current version state and release tracking files.

## Files

### 📄 `VERSION` 
**Type**: Generated/Managed  
**Purpose**: Contains the current semantic version (e.g., "1.0.0")  
**Edit**: Use `task version:update VERSION=x.y.z` instead of direct editing

### 📚 `changelog.md`
**Type**: Generated  
**Purpose**: Historical release notes in Keep a Changelog format  
**Edit**: Generated from `release.md` during release process - do not edit directly

### ✏️ `release.md`
**Type**: Hand-Edited  
**Purpose**: Current development cycle release notes  
**Edit**: **YES** - Edit this file for each PR to track changes

## Workflow

### During Development
1. **Add changes to `release.md`** when submitting PRs
2. Use present tense ("Add user authentication", not "Added")
3. Include context when necessary for clarity

### During Release
1. Content from `release.md` moves to `changelog.md` with proper version and date
2. `release.md` is reset to template for next development cycle
3. `VERSION` file is updated with new version number

## Validation

All files in this directory are validated against CUE schemas in `../schemas/`:

```bash
# Validate all current files
task version:validate-all

# Validate individual files
task version:validate           # VERSION file
task version:validate-changelog # changelog.md
task version:validate-release   # release.md
```

## File Relationships

```
release.md → (during release) → changelog.md
    ↓                               ↓
VERSION ← (version bump) ←──── version entry
```

The release process transforms development notes in `release.md` into historical records in `changelog.md` while updating the version number.