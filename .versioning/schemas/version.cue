package schema

import "strings"

// Version represents semantic version information
#Version: {
	// Semantic version string (e.g., "1.0.0")
	version: string & =~"^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9.-]+)?(\\+[a-zA-Z0-9.-]+)?$"
	
	// Release date in ISO format
	date: string & =~"^\\d{4}-\\d{2}-\\d{2}$"
	
	// Release status
	status: "released" | "draft" | "pre-release"
	
	// Optional pre-release identifier
	prerelease?: string
	
	// Optional build metadata
	build?: string
	
	// Validate version components
	let parts = strings.Split(strings.Split(version, "-")[0], ".")
	major: int & >0 | 0
	minor: int & >=0
	patch: int & >=0
	
	// Ensure version string matches parsed components
	version: "\(major).\(minor).\(patch)" + (prerelease != _|_ ? "-\(prerelease)" : "") + (build != _|_ ? "+\(build)" : "")
}

// VERSION file schema - single line version
#VersionFile: {
	content: string & =~"^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9.-]+)?(\\+[a-zA-Z0-9.-]+)?$"
}