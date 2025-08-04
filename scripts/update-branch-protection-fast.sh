#!/bin/bash
# Update branch protection to use fast PR tests

echo "Updating branch protection rules to use fast PR tests..."

# Update main branch protection
gh api -X PUT /repos/geoffmilleraz/trm/branches/main/protection \
  --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "PR Status Check",
      "Docker Build Validation"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

# Update dev branch protection
gh api -X PUT /repos/geoffmilleraz/trm/branches/dev/protection \
  --input - <<EOF
{
  "required_status_checks": {
    "strict": false,
    "contexts": [
      "PR Status Check",
      "Docker Build Validation"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

echo "✅ Branch protection updated to use fast PR tests"
