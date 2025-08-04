# Infrastructure as Code (IaC)

This directory contains all infrastructure definitions using Terraform.

## Structure

```
iac/
├── cloudformation/         # CloudFormation templates (legacy/prerequisites)
├── deploy/                # Deployment configurations per environment
│   ├── account-bootstrap/ # Account-wide security and DNS setup
│   ├── dev/              # Development environment deployments
│   └── prod/             # Production environment deployments
├── docs/                 # Infrastructure documentation
├── modules/              # Reusable Terraform modules
├── projects/             # Project-specific infrastructure
│   ├── account-bootstrap/
│   ├── core-infrastructure/
│   └── serverless-application/
└── shared-plugins/       # Shared terraform providers and plugins
```

## Quick Start

### 1. Account Bootstrap (One-time setup)
```bash
cd deploy/account-bootstrap
terraform init
terraform plan
terraform apply
```

### 2. Deploy to Development
```bash
cd deploy/dev/us-east-2
terraform init
terraform plan
terraform apply
```

### 3. Deploy to Production
```bash
cd deploy/prod/us-west-2
terraform init
terraform plan
terraform apply
```

## Modules

- **account-bootstrap**: Security services, DNS zones, and account-wide resources
- **core-infrastructure**: VPC, networking, and shared infrastructure
- **serverless-application**: Lambda functions, API Gateway, and DynamoDB

## Best Practices

1. Always run `terraform plan` before `apply`
2. Use workspaces for environment separation when appropriate
3. Store state files in S3 with DynamoDB locking
4. Tag all resources appropriately
5. Follow the module structure for reusability

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured with appropriate credentials
- S3 bucket for Terraform state (created by CloudFormation)

## Environment Variables

Required for deployments:
```bash
export AWS_REGION=us-east-2
export AWS_PROFILE=your-profile  # Optional
```

## Taskfile Commands

Use the task commands for consistent operations:
```bash
# Validate all configurations
task terraform:validate

# Format all files
task terraform:fmt

# Check formatting
task terraform:fmt:check

# Security scan
task terraform:security:scan
```