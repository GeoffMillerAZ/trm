---
allowed-tools: Bash(devbox:*), Bash(uv:*), Read, Edit, Write, TodoWrite
description: Pin all devbox and Python dependencies to currently installed versions
---

# Dependencies Pin Versions

Pin all devbox and Python (uv) dependencies to their currently installed versions in the configuration files.

## Process

1. Get current devbox package versions
2. Get current Python package versions  
3. Update configuration files with pinned versions
4. Validate changes

## Commands

### Check Current Versions
- Devbox packages: !`devbox list`
- Python packages: !`uv pip freeze`

### Update Configuration Files
1. Pin any unpinned devbox packages in @devbox.json (e.g., `eza@latest` → `eza@0.23.0`)
2. Verify Python dependencies in @pyproject.toml match installed versions

### Validate Changes
- Devbox: !`devbox install`
- Python: !`uv sync`

## Files
@devbox.json
@pyproject.toml