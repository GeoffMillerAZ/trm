# Claude Code Agent Definitions

This directory contains specialized agent definitions that Claude Code can delegate to for specific tasks. Each agent is optimized for particular workflows and has access to appropriate tools and project context.

## Color Categorization Schema

Agents are organized into functional categories with color coding for easy identification:

### 📘 Documentation & Knowledge Management (Blue Family)
- **`adr-manager`** - `#1E40AF` (Deep Blue) - Manages Architecture Decision Records
- **`docs-maintainer`** - `#1E40AF` (Deep Blue) - Maintains comprehensive project documentation
- **`documentation-consistency-checker`** - `#3B82F6` (Blue) - Ensures documentation accuracy after changes
- **`spec-file-reviewer`** - `#06B6D4` (Cyan) - Reviews and standardizes specification files

### 🟢 Infrastructure & DevOps (Green Family)
- **`infrastructure-spec-writer`** - `#059669` (Emerald) - Creates infrastructure specifications
- **`devbox-environment-manager`** - `#16A34A` (Green) - Manages development environments
- **`cicd-workflow-optimizer`** - `#22C55E` (Light Green) - Optimizes CI/CD workflows

### 🟣 Development Workflow (Purple Family)
- **`gitflow-workflow-enforcer`** - `#7C3AED` (Violet) - Enforces GitFlow standards
- **`version-release-manager`** - `#A855F7` (Purple) - Manages versioning and releases
