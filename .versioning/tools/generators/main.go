package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"
)

type Generator struct {
	ctx cue.Context
}

func NewGenerator() *Generator {
	return &Generator{
		ctx: *cuecontext.New(),
	}
}

// ValidateVersionFile validates a VERSION file content
func (g *Generator) ValidateVersionFile(content string) error {
	// Load CUE schema
	instances := load.Instances([]string{"../version.cue"}, nil)
	if len(instances) == 0 {
		return fmt.Errorf("no CUE instances found")
	}

	v := g.ctx.BuildInstance(instances[0])
	if v.Err() != nil {
		return fmt.Errorf("failed to build CUE instance: %w", v.Err())
	}

	// Validate VERSION file format
	versionFile := v.LookupPath(cue.ParsePath("#VersionFile"))
	validation := versionFile.Fill(map[string]interface{}{
		"content": content,
	})

	if validation.Err() != nil {
		return fmt.Errorf("version validation failed: %w", validation.Err())
	}

	return nil
}

// GenerateReleaseFile generates a new release.md file
func (g *Generator) GenerateReleaseFile(outputPath string) error {
	content := `# Release Notes - Development Cycle

## Added

## Changed

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
`

	if err := os.WriteFile(outputPath, []byte(content), 0644); err != nil {
		return fmt.Errorf("failed to write release file: %w", err)
	}

	return nil
}

// GenerateChangelogEntry generates a new changelog entry
func (g *Generator) GenerateChangelogEntry(version, releaseContent string) (string, error) {
	date := time.Now().Format("2006-01-02")
	
	entry := fmt.Sprintf(`
## [%s] - %s

%s

[%s]: https://github.com/yourusername/ddd-python-template/releases/tag/v%s
`, version, date, releaseContent, version, version)

	return entry, nil
}

// UpdateVersionFile updates the VERSION file with a new version
func (g *Generator) UpdateVersionFile(version, filePath string) error {
	// Validate version format first
	if err := g.ValidateVersionFile(version); err != nil {
		return fmt.Errorf("invalid version format: %w", err)
	}

	if err := os.WriteFile(filePath, []byte(version), 0644); err != nil {
		return fmt.Errorf("failed to write version file: %w", err)
	}

	return nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: generator <command> [args...]")
		fmt.Println("Commands:")
		fmt.Println("  validate-version <version>")
		fmt.Println("  generate-release <output-path>")
		fmt.Println("  update-version <version> <file-path>")
		fmt.Println("  generate-changelog-entry <version> <release-content>")
		os.Exit(1)
	}

	generator := NewGenerator()
	command := os.Args[1]

	switch command {
	case "validate-version":
		if len(os.Args) != 3 {
			fmt.Println("Usage: generator validate-version <version>")
			os.Exit(1)
		}
		version := os.Args[2]
		if err := generator.ValidateVersionFile(version); err != nil {
			fmt.Printf("Validation failed: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Version is valid")

	case "generate-release":
		if len(os.Args) != 3 {
			fmt.Println("Usage: generator generate-release <output-path>")
			os.Exit(1)
		}
		outputPath := os.Args[2]
		if err := generator.GenerateReleaseFile(outputPath); err != nil {
			fmt.Printf("Generation failed: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Release file generated at %s\n", outputPath)

	case "update-version":
		if len(os.Args) != 4 {
			fmt.Println("Usage: generator update-version <version> <file-path>")
			os.Exit(1)
		}
		version := os.Args[2]
		filePath := os.Args[3]
		if err := generator.UpdateVersionFile(version, filePath); err != nil {
			fmt.Printf("Update failed: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Version file updated with %s\n", version)

	case "generate-changelog-entry":
		if len(os.Args) != 4 {
			fmt.Println("Usage: generator generate-changelog-entry <version> <release-content>")
			os.Exit(1)
		}
		version := os.Args[2]
		releaseContent := os.Args[3]
		entry, err := generator.GenerateChangelogEntry(version, releaseContent)
		if err != nil {
			fmt.Printf("Generation failed: %v\n", err)
			os.Exit(1)
		}
		fmt.Print(entry)

	default:
		fmt.Printf("Unknown command: %s\n", command)
		os.Exit(1)
	}
}