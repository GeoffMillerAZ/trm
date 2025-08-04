package schema

import "encoding/json"
import "encoding/yaml"

// Validation functions for versioning files

// Validate VERSION file
#ValidateVersion: {
	input: string
	
	// Parse and validate version string
	let version_data = #VersionFile & {content: input}
	
	valid: version_data != _|_
	error?: string
	
	if valid == false {
		error: "Invalid version format. Must be semantic version (e.g., 1.0.0)"
	}
}

// Validate changelog.md file
#ValidateChangelog: {
	input: string
	
	// For now, basic validation - full markdown parsing would need external tool
	valid: input =~ "# Changelog" && input =~ "## \\[\\d+\\.\\d+\\.\\d+\\]"
	error?: string
	
	if valid == false {
		error: "Invalid changelog format. Must contain '# Changelog' header and version entries"
	}
}

// Validate release.md file  
#ValidateRelease: {
	input: string
	
	// Parse release file structure
	let release_data = #ReleaseFile & {content: input}
	
	valid: release_data != _|_
	error?: string
	
	if valid == false {
		error: "Invalid release format. Must contain all required sections (Added, Changed, Fixed, etc.)"
	}
}

// Combined validation result
#ValidationResult: {
	file_type: "version" | "changelog" | "release"
	valid: bool
	error?: string
	warnings?: [...string]
}