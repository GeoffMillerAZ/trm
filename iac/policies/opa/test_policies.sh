#!/bin/bash
# Script to test OPA policies against Terraform plans

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    color=$1
    message=$2
    echo -e "${color}${message}${NC}"
}

# Check if required tools are installed
check_tools() {
    for tool in terraform opa conftest jq; do
        if ! command -v $tool &> /dev/null; then
            print_color $RED "Error: $tool is not installed"
            exit 1
        fi
    done
}

# Generate Terraform plan
generate_plan() {
    environment=$1
    region=$2
    deployment_path="iac/deploy/$environment/$region"
    
    if [ ! -d "$deployment_path" ]; then
        print_color $RED "Error: Deployment path $deployment_path does not exist"
        return 1
    fi
    
    print_color $YELLOW "Generating Terraform plan for $environment/$region..."
    cd "$deployment_path"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        terraform init -backend=false
    fi
    
    # Generate plan
    terraform plan -out=tfplan.binary
    terraform show -json tfplan.binary > tfplan.json
    
    # Return to root
    cd - > /dev/null
    
    return 0
}

# Run OPA policies
run_policies() {
    plan_file=$1
    environment=$2
    
    print_color $YELLOW "Running OPA policies..."
    
    # Run with conftest
    if conftest verify --policy iac/policies/opa --data iac/policies/opa/data/environments.json "$plan_file"; then
        print_color $GREEN "✓ All policies passed"
        return 0
    else
        print_color $RED "✗ Policy violations found"
        return 1
    fi
}

# Main execution
main() {
    check_tools
    
    # Default to dev environment if not specified
    ENVIRONMENT=${1:-dev}
    REGION=${2:-global}
    
    print_color $GREEN "=== OPA Policy Testing ==="
    print_color $YELLOW "Environment: $ENVIRONMENT"
    print_color $YELLOW "Region: $REGION"
    echo
    
    # Generate plan
    if generate_plan "$ENVIRONMENT" "$REGION"; then
        plan_path="iac/deploy/$ENVIRONMENT/$REGION/tfplan.json"
        
        # Run policies
        if run_policies "$plan_path" "$ENVIRONMENT"; then
            print_color $GREEN "\n=== All policies passed! ==="
            exit 0
        else
            print_color $RED "\n=== Policy violations detected ==="
            exit 1
        fi
    else
        print_color $RED "Failed to generate Terraform plan"
        exit 1
    fi
}

# Run main function
main "$@"