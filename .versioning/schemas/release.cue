package schema

// Release notes for current development cycle
#ReleaseNotes: {
	// File header
	title: "Release Notes - Development Cycle"
	
	// Release sections with entries
	sections: #ReleaseSections
	
	// Instructions section
	instructions: #ReleaseInstructions
}

// Release sections structure
#ReleaseSections: {
	added: [...#ReleaseEntry]
	changed: [...#ReleaseEntry]
	fixed: [...#ReleaseEntry]
	security: [...#ReleaseEntry]
	deprecated: [...#ReleaseEntry]
	removed: [...#ReleaseEntry]
}

// Individual release entry for development cycle
#ReleaseEntry: {
	// Entry description in present tense
	description: string & len(description) > 0
	
	// Optional context for clarity
	context?: string
	
	// Optional PR or issue reference
	reference?: string & =~"^(#\\d+|PR#\\d+|Issue#\\d+)$"
	
	// Entry validation
	// Must use present tense verbs
	description: string & (
		=~"^(Add|Update|Fix|Remove|Deprecate|Improve|Refactor|Enhance)" |
		=~"^[a-z]" // Allow lowercase start for continuation sentences
	)
	
	// Should not end with period unless complete sentence
	description: !~"\\.$" | =~"\\. .+"
}

// Release instructions
#ReleaseInstructions: {
	title: "Instructions:"
	guidelines: [...string]
	
	// Standard guidelines
	guidelines: [
		"Add entries under the appropriate category when submitting PRs",
		"Use present tense (\"Add user authentication\" not \"Added user authentication\")",
		"Include context when necessary for clarity",
		"At release time, these entries will be moved to changelog.md with proper version and date"
	]
}

// Validation for complete release.md file format
#ReleaseFile: {
	// Must contain standard structure
	content: string
	
	// Validate required sections exist
	content: =~"## Added"
	content: =~"## Changed" 
	content: =~"## Fixed"
	content: =~"## Security"
	content: =~"## Deprecated"
	content: =~"## Removed"
	content: =~"\\*\\*Instructions:\\*\\*"
}