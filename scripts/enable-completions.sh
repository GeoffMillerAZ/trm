#!/usr/bin/env bash
# enable-completions - Manually enable shell completions for devbox tools
# Usage: source .dev.d/enable-completions

# Function to setup completions
enable_devbox_completions() {
    # Detect shell type
    local shell_type=""
    if [ -n "${ZSH_VERSION:-}" ]; then
        shell_type="zsh"
    elif [ -n "${BASH_VERSION:-}" ]; then
        shell_type="bash"
    else
        echo "⚠️  Unsupported shell. Only bash and zsh are supported."
        return 1
    fi

    echo "Enabling shell completions for devbox tools (${shell_type})..."

    # Initialize completion system for zsh
    if [ "$shell_type" = "zsh" ]; then
        # Initialize completion system if not already done
        if ! type compdef >/dev/null 2>&1; then
            autoload -Uz compinit
            compinit -C
        fi
    fi

    # Lefthook
    if command -v lefthook >/dev/null 2>&1; then
        if lefthook completion "$shell_type" >/dev/null 2>&1; then
            eval "$(lefthook completion "$shell_type" 2>/dev/null)" && echo "✓ lefthook completions enabled"
        else
            echo "⚠️  lefthook completions not available"
        fi
    fi

    # Act
    if command -v act >/dev/null 2>&1; then
        if act completion "$shell_type" >/dev/null 2>&1; then
            eval "$(act completion "$shell_type" 2>/dev/null)" && echo "✓ act completions enabled"
        else
            echo "⚠️  act completions not available"
        fi
    fi

    # Terraform
    if command -v terraform >/dev/null 2>&1; then
        if [ "$shell_type" = "zsh" ]; then
            autoload -U +X bashcompinit && bashcompinit
            complete -o nospace -C terraform terraform && echo "✓ terraform completions enabled"
        elif [ "$shell_type" = "bash" ]; then
            complete -C terraform terraform && echo "✓ terraform completions enabled"
        fi
    fi

    # Python/pip
    if command -v python >/dev/null 2>&1 && python -m pip >/dev/null 2>&1; then
        if python -m pip completion --"$shell_type" >/dev/null 2>&1; then
            eval "$(python -m pip completion --"$shell_type" 2>/dev/null)" && echo "✓ pip completions enabled"
        else
            echo "⚠️  pip completions not available"
        fi
    fi

    # UV
    if command -v uv >/dev/null 2>&1; then
        echo "ℹ️  uv does not provide built-in shell completions"
    fi

    echo
    echo "Completion setup finished!"
    echo "Note: You may need to restart your shell or run 'exec $SHELL' for some completions to take effect."
}

# Run the function
enable_devbox_completions
