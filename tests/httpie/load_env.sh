#!/bin/bash
# Environment loader for HTTPie tests
# Usage: source load_env.sh [env_file]

# Function to load environment variables from file
load_env() {
    local env_file="${1:-local.env}"
    local env_path=""

    # Check if it's a full path
    if [[ "$env_file" == /* ]]; then
        env_path="$env_file"
    else
        # Check if it's just a name (add .env if missing)
        if [[ "$env_file" != *.env ]]; then
            env_file="${env_file}.env"
        fi

        # Look for the file in the envs directory
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        env_path="${script_dir}/envs/${env_file}"
    fi

    # Check if file exists
    if [[ ! -f "$env_path" ]]; then
        echo "ERROR: Environment file not found: $env_path" >&2
        echo "Available environments:" >&2
        ls "${script_dir}/envs/"*.env 2>/dev/null | xargs -n1 basename | sed 's/.env$//' >&2
        return 1
    fi

    # Load the environment file
    echo "Loading environment from: $env_path"
    set -a  # Automatically export variables
    source "$env_path"
    set +a  # Stop auto-exporting

    # Set derived variables for backward compatibility
    export HOST="$API_HOST"
    export TIMEOUT="$API_TIMEOUT"

    # Show loaded configuration
    echo "Configuration loaded:"
    echo "  API Host: $API_HOST"
    echo "  Timeout: $API_TIMEOUT"
    echo "  Concurrent Requests: $CONCURRENT_REQUESTS"
    echo "  Verbose: $VERBOSE_OUTPUT"
    echo
}

# Load environment if script is called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly."
    echo "Usage: source load_env.sh [env_file]"
    exit 1
fi

# Auto-load if ENV_FILE is provided
if [[ -n "${ENV_FILE:-}" ]]; then
    load_env "$ENV_FILE"
elif [[ $# -gt 0 ]]; then
    load_env "$1"
fi
