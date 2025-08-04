package schema

import "time"

// Changelog represents the complete changelog file structure
#Changelog: {
	// File header
	title: "Changelog"
	description: string & =~"^All notable changes.*based on.*Keep a Changelog.*Semantic Versioning.*$"
	
	// Collection of version releases
	releases: [...#Release]
	
	// Ensure releases are in descending chronological order
	// Most recent first
	releases: [ for i, r in releases {
		if i > 0 {
			// Current release date must be >= previous release date
			date: >=releases[i-1].date
		}
		r
	}]
}

// Individual release entry
#Release: {
	// Version information
	version: string & =~"^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9.-]+)?(\\+[a-zA-Z0-9.-]+)?$"
	date: string & =~"^\\d{4}-\\d{2}-\\d{2}$"
	
	// Optional release URL
	url?: string & =~"^https?://.*"
	
	// Release sections
	added?: [...#ChangeEntry]
	changed?: [...#ChangeEntry]
	deprecated?: [...#ChangeEntry]
	removed?: [...#ChangeEntry]
	fixed?: [...#ChangeEntry]
	security?: [...#ChangeEntry]
	
	// At least one section must have content
	added != _|_ | changed != _|_ | deprecated != _|_ | removed != _|_ | fixed != _|_ | security != _|_: true
	
	// Validate date format
	let parsed_date = time.Parse("2006-01-02", date)
	date: time.Format("2006-01-02", parsed_date)
}

// Individual change entry
#ChangeEntry: {
	// Change description in present tense
	description: string & len(description) > 0
	
	// Optional context or additional details
	context?: string
	
	// Optional reference (PR, issue, commit)
	reference?: string & =~"^(#\\d+|[a-f0-9]{7,40}|https?://.*)$"
	
	// Validate description format
	// Should not start with capital letter (except proper nouns)
	// Should not end with period unless it's a complete sentence
	description: string & !~"^[A-Z]" | =~"^[A-Z][a-z]+ " // Allow proper nouns
}