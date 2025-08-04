#!/bin/bash
# Script to clean up repository by removing large terraform provider files from history

set -euo pipefail

echo "Creating backup of current state..."
git branch backup-$(date +%Y%m%d-%H%M%S) || true

echo "Removing large files from history..."
# Using git filter-branch to remove terraform providers
git filter-branch --force --index-filter \
  'git rm -r --cached --ignore-unmatch "**/terraform-provider-*" \
   git rm -r --cached --ignore-unmatch "**/.terraform/providers" \
   git rm -r --cached --ignore-unmatch "iac/deploy/account-bootstrap/.terraform"' \
  --prune-empty --tag-name-filter cat -- --all

echo "Cleaning up..."
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "Repository cleaned. Size before and after:"
echo "Before: $(du -sh .git | cut -f1)"
git gc
echo "After: $(du -sh .git | cut -f1)"

echo ""
echo "IMPORTANT: You'll need to force push to update the remote:"
echo "  git push --force --all"
echo "  git push --force --tags"
echo ""
echo "Make sure all team members re-clone the repository after this operation."