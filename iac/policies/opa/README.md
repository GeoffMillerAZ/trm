# OPA Policies for Terraform

This directory contains Open Policy Agent (OPA) policies for validating Terraform configurations to ensure security best practices and compliance.

## Directory Structure

```
opa/
├── README.md           # This file
├── lib/               # Shared helper functions and utilities
├── rules/             # Policy rules organized by category
│   ├── aws/          # AWS-specific policies
│   ├── security/     # General security policies
│   └── tags/         # Tagging policies
├── tests/            # Policy tests
└── data/             # Policy data (allowed values, etc.)
```

## Usage

### Running Policies with Conftest

```bash
# Run all policies against a Terraform plan
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
conftest verify --policy iac/policies/opa tfplan.json

# Run specific policy categories
conftest verify --policy iac/policies/opa/rules/aws tfplan.json

# Test policies with different environments
conftest verify --policy iac/policies/opa --data iac/policies/opa/data/dev.json tfplan.json
```

### Running OPA Server

```bash
# Start OPA server with policies loaded
opa run --server --bundle iac/policies/opa

# Query the server
curl -X POST localhost:8181/v1/data/terraform/analysis/deny -d @tfplan.json
```

## Policy Categories

### 1. AWS Resource Policies (`rules/aws/`)
- S3 bucket security (encryption, versioning, public access)
- KMS key rotation and deletion window
- Lambda security (VPC attachment, environment variables)
- API Gateway security (TLS, authentication)
- DynamoDB encryption and backup settings
- IAM policies and roles restrictions

### 2. Security Policies (`rules/security/`)
- Encryption requirements
- Network security (security groups, NACLs)
- Secret management
- SSL/TLS enforcement
- Access control

### 3. Tagging Policies (`rules/tags/`)
- Required tags
- Tag naming conventions
- Environment-specific tag requirements

## Environment-Specific Rules

Policies can behave differently based on environment:
- **Development**: Warnings for best practices
- **Production**: Hard failures for security violations

## Writing New Policies

1. Create a new `.rego` file in the appropriate category directory
2. Use the shared utilities from `lib/`
3. Write tests in `tests/`
4. Update this README with the new policy

## Testing Policies

```bash
# Run all policy tests
opa test iac/policies/opa -v

# Run specific test file
opa test iac/policies/opa/tests/aws_test.rego -v
```

## Integration with CI/CD

Add to your CI/CD pipeline:

```yaml
- name: Terraform Plan
  run: |
    terraform plan -out=tfplan.binary
    terraform show -json tfplan.binary > tfplan.json

- name: OPA Policy Check
  run: |
    conftest verify --policy iac/policies/opa tfplan.json
    # Exit code 0 = pass, 1 = fail
```