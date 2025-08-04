#!/bin/bash
# One-time GitFlow setup script for GitHub repository
# Configures branch protection, environments, and CI/CD settings

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get repository info
REPO_OWNER=$(gh repo view --json owner -q .owner.login)
REPO_NAME=$(gh repo view --json name -q .name)

echo -e "${BLUE}Setting up GitFlow for ${REPO_OWNER}/${REPO_NAME}...${NC}"

# 1. Create dev branch if it doesn't exist
echo -e "\n${GREEN}Step 1: Creating dev branch...${NC}"
if ! git show-ref --verify --quiet refs/heads/dev; then
    git checkout -b dev
    git push -u origin dev
    echo "✓ Dev branch created and pushed"
else
    echo "✓ Dev branch already exists"
fi

# 2. Set default branch to main
echo -e "\n${GREEN}Step 2: Setting default branch to main...${NC}"
gh repo edit --default-branch main
echo "✓ Default branch set to main"

# 3. Create repository environments
echo -e "\n${GREEN}Step 3: Creating deployment environments...${NC}"

# Create development environment
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${REPO_OWNER}/${REPO_NAME}/environments/development" \
  -f deployment_branch_policy='{"protected_branches":false,"custom_branch_policies":true}' \
  -F 'deployment_branch_policy[custom_branch_policies][][name]=dev' || true

echo "✓ Development environment created"

# Create production environment with protection
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${REPO_OWNER}/${REPO_NAME}/environments/production" \
  -f deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}' || true

echo "✓ Production environment created"

# 4. Configure branch protection for main
echo -e "\n${GREEN}Step 4: Configuring branch protection for main...${NC}"

# For solo developer: No review requirements, but enforce quality checks
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${REPO_OWNER}/${REPO_NAME}/branches/main/protection" \
  -F 'required_status_checks[strict]=true' \
  -F 'required_status_checks[contexts][]=lint-and-validate' \
  -F 'required_status_checks[contexts][]=test' \
  -F 'required_status_checks[contexts][]=security-scan' \
  -F 'enforce_admins=false' \
  -F 'required_pull_request_reviews=null' \
  -F 'restrictions=null' \
  -F 'allow_force_pushes=false' \
  -F 'allow_deletions=false' \
  -F 'block_creations=false' \
  -F 'required_conversation_resolution=true' \
  -F 'lock_branch=false' \
  -F 'allow_fork_syncing=true' || true

echo "✓ Main branch protection configured"

# 5. Configure branch protection for dev
echo -e "\n${GREEN}Step 5: Configuring branch protection for dev...${NC}"

# Dev branch: More relaxed, but still require tests to pass
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${REPO_OWNER}/${REPO_NAME}/branches/dev/protection" \
  -F 'required_status_checks[strict]=false' \
  -F 'required_status_checks[contexts][]=lint-and-validate' \
  -F 'required_status_checks[contexts][]=test' \
  -F 'enforce_admins=false' \
  -F 'required_pull_request_reviews=null' \
  -F 'restrictions=null' \
  -F 'allow_force_pushes=true' \
  -F 'allow_deletions=false' \
  -F 'block_creations=false' \
  -F 'required_conversation_resolution=false' \
  -F 'lock_branch=false' \
  -F 'allow_fork_syncing=true' || true

echo "✓ Dev branch protection configured"

# 6. Create PR template
echo -e "\n${GREEN}Step 6: Creating PR template...${NC}"
mkdir -p .github
cat > .github/pull_request_template.md << 'EOF'
## Description
Brief description of changes

## Type of Change
- [ ] 🐛 Bug fix
- [ ] ✨ New feature
- [ ] 📝 Documentation update
- [ ] 🧹 Code refactoring
- [ ] 🔧 Configuration change
- [ ] 🚀 Performance improvement

## Self-Review Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated if needed
- [ ] Tests added/updated
- [ ] All tests passing locally
- [ ] No security vulnerabilities introduced
- [ ] Breaking changes documented

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Deployment Notes
Any special deployment considerations?

## Related Issues
Closes #(issue number)
EOF

echo "✓ PR template created"

# 7. Create issue templates
echo -e "\n${GREEN}Step 7: Creating issue templates...${NC}"
mkdir -p .github/ISSUE_TEMPLATE

cat > .github/ISSUE_TEMPLATE/bug_report.yml << 'EOF'
name: Bug Report
description: Report a bug or unexpected behavior
labels: ["bug"]
body:
  - type: textarea
    id: description
    attributes:
      label: Bug Description
      description: Clear and concise description of the bug
    validations:
      required: true
  
  - type: textarea
    id: steps
    attributes:
      label: Steps to Reproduce
      description: Steps to reproduce the behavior
      placeholder: |
        1. Go to '...'
        2. Click on '....'
        3. See error
    validations:
      required: true
  
  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
      description: What you expected to happen
    validations:
      required: true
  
  - type: textarea
    id: environment
    attributes:
      label: Environment
      description: |
        - OS: [e.g. macOS, Linux]
        - Python Version:
        - Browser (if applicable):
    validations:
      required: false
EOF

cat > .github/ISSUE_TEMPLATE/feature_request.yml << 'EOF'
name: Feature Request
description: Suggest a new feature or enhancement
labels: ["enhancement"]
body:
  - type: textarea
    id: description
    attributes:
      label: Feature Description
      description: Clear description of the feature
    validations:
      required: true
  
  - type: textarea
    id: problem
    attributes:
      label: Problem it Solves
      description: What problem does this feature solve?
    validations:
      required: true
  
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
      description: Any alternative solutions you've considered
    validations:
      required: false
EOF

echo "✓ Issue templates created"

# 8. Configure repository settings
echo -e "\n${GREEN}Step 8: Configuring repository settings...${NC}"

# Enable features
gh repo edit \
  --enable-issues \
  --enable-wiki=false \
  --enable-projects=false \
  --enable-discussions=false \
  --enable-merge-commit \
  --enable-squash-merge \
  --enable-rebase-merge \
  --delete-branch-on-merge

echo "✓ Repository settings configured"

# 9. Create initial labels
echo -e "\n${GREEN}Step 9: Creating labels...${NC}"

# Define labels
labels=(
  "bug:Something isn't working:d73a4a"
  "enhancement:New feature or request:a2eeef"
  "documentation:Improvements or additions to documentation:0075ca"
  "good first issue:Good for newcomers:7057ff"
  "help wanted:Extra attention is needed:008672"
  "invalid:This doesn't seem right:e4e669"
  "question:Further information is requested:d876e3"
  "wontfix:This will not be worked on:ffffff"
  "dependencies:Pull requests that update a dependency file:0366d6"
  "infrastructure:Infrastructure and deployment:c5def5"
  "security:Security related:ee0000"
  "performance:Performance improvements:ffcc00"
  "testing:Testing improvements:bfd4f2"
)

for label in "${labels[@]}"; do
  IFS=':' read -r name description color <<< "$label"
  gh label create "$name" --description "$description" --color "$color" --force || true
done

echo "✓ Labels created"

# 10. Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✓ GitFlow setup complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Commit and push the new templates: git add .github && git commit -m 'Add PR and issue templates'"
echo "2. Create your first feature branch: git checkout -b feature/your-feature dev"
echo "3. Make changes and push: git push -u origin feature/your-feature"
echo "4. Create PR to dev branch: gh pr create --base dev"
echo -e "\n${YELLOW}GitFlow process:${NC}"
echo "• feature/* → dev (for development)"
echo "• dev → main (for production releases)"
echo "• hotfix/* → main & dev (for emergency fixes)"
echo -e "\n${GREEN}Happy coding! 🚀${NC}"