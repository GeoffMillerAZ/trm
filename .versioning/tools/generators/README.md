# Versioning Generators

Go-based generators for creating and validating versioning files using CUE schemas.

## Setup

```bash
cd .versioning/schema/generators
go mod tidy
go build -o generator main.go
```

## Commands

### Validate Version
```bash
./generator validate-version "1.0.0"
```

### Generate Release File
```bash
./generator generate-release "../release.md"
```

### Update Version File
```bash
./generator update-version "1.0.1" "../VERSION"
```

### Generate Changelog Entry
```bash
./generator generate-changelog-entry "1.0.0" "$(cat ../release.md)"
```

## Integration

These generators are integrated with the task system:

```bash
# Validate current version
task version:validate

# Generate new release file
task version:generate-release

# Update version
task version:bump-patch  # or bump-minor, bump-major

# Generate changelog from release notes
task version:generate-changelog
```

## Future Enhancements

- [ ] Full CUE schema validation integration
- [ ] Automated changelog formatting from release notes
- [ ] Git tag integration
- [ ] CI/CD pipeline integration
- [ ] Semantic version bumping logic
- [ ] Release note templates based on change types