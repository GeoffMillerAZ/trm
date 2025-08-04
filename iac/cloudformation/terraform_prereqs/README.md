# TRM Block Explorer - Terraform Prerequisites

This document outlines the CloudFormation StackSet that creates all prerequisite resources needed for Terraform state management and deployment across multiple regions.

## Overview

Before deploying the TRM Block Explorer infrastructure with Terraform, we need to bootstrap the following resources using CloudFormation:
- **S3 Buckets**: Terraform state storage with cross-region backup
- **DynamoDB Table**: Terraform state locking
- **IAM Resources**: Terraform execution role and policies
- **KMS Keys**: Encryption for state files

---

## CloudFormation StackSet: `terraform-prerequisites.yaml`

### Stack Components

#### S3 State Management
- **Primary State Bucket**: `trm-blockexplorer-terraform-state-<account-id>-<primary-region>`
  - **Region**: `us-west-2` (primary)
  - **Versioning**: Enabled with 90-day retention
  - **Encryption**: AES-256 server-side encryption
  - **Cross-Region Replication**: Automatic replication to backup bucket
  - **Public Access**: Blocked (security best practice)
  - **Access Logging**: Enabled for audit trails

- **Backup State Bucket**: `trm-blockexplorer-terraform-state-backup-<account-id>-<secondary-region>`
  - **Region**: `us-east-2` (secondary)
  - **Purpose**: Disaster recovery for Terraform state files
  - **Versioning**: Enabled
  - **Encryption**: AES-256 server-side encryption
  - **Public Access**: Blocked

#### DynamoDB State Locking
- **Table Name**: `trm-blockexplorer-terraform-locks`
- **Primary Key**: `LockID` (String)
- **Billing Mode**: On-demand (cost-optimized for infrequent Terraform operations)
- **Region**: `us-west-2` (primary region only - Terraform locking doesn't require multi-region)
- **Encryption**: Server-side encryption with AWS managed keys
- **Point-in-Time Recovery**: Enabled for data protection

#### IAM Terraform Execution Role
- **Role Name**: `TerraformExecutionRole`
- **Trust Policy**: Allows assumption by:
  - EC2 instances (for CI/CD pipelines)
  - Current AWS account users (for manual execution)
  - CodeBuild service (for automated deployments)

- **Attached Policies**:
  - `AdministratorAccess` (managed policy - for full infrastructure management)
  - `TerraformStateAccess` (custom policy - see below)

#### Custom IAM Policy: `TerraformStateAccess`
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::trm-blockexplorer-terraform-state-*",
        "arn:aws:s3:::trm-blockexplorer-terraform-state-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-west-2:*:table/trm-blockexplorer-terraform-locks"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ],
      "Resource": "arn:aws:kms:*:*:key/*",
      "Condition": {
        "StringEquals": {
          "kms:via": ["s3", "dynamodb"]
        }
      }
    }
  ]
}
```

#### KMS Encryption Keys
- **Key Alias**: `alias/trm-terraform-state-key`
- **Purpose**: Encrypt Terraform state files and DynamoDB table
- **Key Policy**: Grants access to:
  - AWS account root user
  - `TerraformExecutionRole`
  - S3 and DynamoDB services for encryption operations
- **Multi-Region**: No (regional key is sufficient for state encryption)

### StackSet Configuration

```yaml
# cloudformation/terraform-prerequisites.yaml
Parameters:
  Environment:
    Type: String
    AllowedValues: [dev, prod]
    Description: Environment name for resource naming

  ProjectName:
    Type: String
    Default: trm-blockexplorer
    Description: Project name for resource naming

  PrimaryRegion:
    Type: String
    Default: us-west-2
    Description: Primary region for state storage

  SecondaryRegion:
    Type: String
    Default: us-east-2
    Description: Secondary region for backup storage

  DeploymentType:
    Type: String
    AllowedValues: [primary, backup]
    Description: Type of deployment (primary = full stack, backup = bucket only)
```

---

## Deployment Instructions

### Step 1: Create the StackSet
```bash
aws cloudformation create-stack-set \
  --stack-set-name trm-blockexplorer-terraform-prerequisites \
  --template-body file://cloudformation/terraform-prerequisites.yaml \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=Environment,ParameterValue=dev \
               ParameterKey=ProjectName,ParameterValue=trm-blockexplorer
```

### Step 2: Deploy to Primary Region (Full Stack)
```bash
aws cloudformation create-stack-instances \
  --stack-set-name trm-blockexplorer-terraform-prerequisites \
  --regions us-west-2 \
  --parameter-overrides ParameterKey=DeploymentType,ParameterValue=primary \
                        ParameterKey=PrimaryRegion,ParameterValue=us-west-2 \
                        ParameterKey=SecondaryRegion,ParameterValue=us-east-2
```

### Step 3: Deploy to Secondary Region (Backup Bucket Only)
```bash
aws cloudformation create-stack-instances \
  --stack-set-name trm-blockexplorer-terraform-prerequisites \
  --regions us-east-2 \
  --parameter-overrides ParameterKey=DeploymentType,ParameterValue=backup \
                        ParameterKey=PrimaryRegion,ParameterValue=us-west-2 \
                        ParameterKey=SecondaryRegion,ParameterValue=us-east-2
```

---

## Terraform Backend Configuration

After CloudFormation deployment, configure Terraform to use these resources:

### Backend Configuration Files

**`terraform/bootstrap/backend-config/dev.tfvars`**
```hcl
bucket         = "trm-blockexplorer-terraform-state-123456789012-us-west-2"
key            = "environments/dev/global/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "trm-blockexplorer-terraform-locks"
encrypt        = true
role_arn       = "arn:aws:iam::123456789012:role/TerraformExecutionRole"
```

**`terraform/bootstrap/backend-config/prod.tfvars`**
```hcl
bucket         = "trm-blockexplorer-terraform-state-123456789012-us-west-2"
key            = "environments/prod/global/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "trm-blockexplorer-terraform-locks"
encrypt        = true
role_arn       = "arn:aws:iam::123456789012:role/TerraformExecutionRole"
```

### Usage in Terraform
```hcl
# In each Terraform configuration
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    # Configuration loaded from backend-config files
  }
}
```

---

## Validation

After deployment, verify the following:

### S3 Buckets
- [ ] Primary state bucket created in us-west-2
- [ ] Backup state bucket created in us-east-2
- [ ] Cross-region replication configured and working
- [ ] Versioning enabled on both buckets
- [ ] Public access blocked on both buckets

### DynamoDB Table
- [ ] Terraform locks table created in us-west-2
- [ ] Table has `LockID` string attribute as primary key
- [ ] On-demand billing mode configured
- [ ] Encryption enabled with AWS managed keys

### IAM Resources
- [ ] `TerraformExecutionRole` created with correct trust policy
- [ ] Role has `AdministratorAccess` and `TerraformStateAccess` policies
- [ ] Custom policy allows S3, DynamoDB, and KMS operations

### KMS Key
- [ ] Terraform state encryption key created
- [ ] Key policy allows access by Terraform role
- [ ] Key alias `alias/trm-terraform-state-key` configured

---

## Cleanup Instructions

When tearing down the infrastructure:

### Step 1: Remove Stack Instances
```bash
aws cloudformation delete-stack-instances \
  --stack-set-name trm-blockexplorer-terraform-prerequisites \
  --regions us-west-2,us-east-2 \
  --retain-stacks false
```

### Step 2: Delete the StackSet
```bash
aws cloudformation delete-stack-set \
  --stack-set-name trm-blockexplorer-terraform-prerequisites
```

**Note**: Ensure all Terraform-managed resources are destroyed before removing the prerequisites, as Terraform state files will become inaccessible.

---

## Security Considerations

- **Principle of Least Access**: Only grant minimum required permissions
- **State File Encryption**: All state files encrypted at rest and in transit
- **Cross-Region Backup**: Protects against regional disasters
- **Access Logging**: S3 access logs provide audit trails
- **Versioning**: Enables recovery from corrupted state files
- **Public Access Blocked**: Prevents accidental exposure of state files
