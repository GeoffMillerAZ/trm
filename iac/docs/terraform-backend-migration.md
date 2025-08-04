# Terraform Backend Migration Guide

This document describes the centralized Terraform state management setup and migration process for the TRM Block Explorer infrastructure.

## Overview

All Terraform deployments in this repository have been configured to use a centralized S3 backend for state management. This provides:

- **State Locking**: Prevents concurrent modifications via DynamoDB
- **Encryption**: State files are encrypted at rest using KMS
- **Versioning**: S3 versioning enables state recovery
- **Access Control**: IAM policies restrict state access
- **Audit Trail**: S3 access logging tracks all state operations

## Backend Infrastructure

The following AWS resources are used for Terraform state management:

| Resource | Value | Purpose |
|----------|-------|---------|
| S3 Bucket | `trm-blockexplorer-terraform-state-754419183698-us-west-2` | Stores all Terraform state files |
| DynamoDB Table | `trm-blockexplorer-terraform-locks` | Provides state locking |
| KMS Key | `65925835-1465-4852-8f5b-f8a5812c159d` | Encrypts state at rest |
| IAM Role | `arn:aws:iam::754419183698:role/TerraformExecutionRole` | Manages state access |

## Backend Configuration Files

Each Terraform deployment has a `backend-config.hcl` file that specifies the backend configuration:

```hcl
bucket         = "trm-blockexplorer-terraform-state-754419183698-us-west-2"
key            = "path/to/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "trm-blockexplorer-terraform-locks"
encrypt        = true
kms_key_id     = "65925835-1465-4852-8f5b-f8a5812c159d"
```

## State File Organization

State files are organized hierarchically in the S3 bucket:

```
trm-blockexplorer-terraform-state-754419183698-us-west-2/
├── account-bootstrap/           # Account-wide security services
│   └── terraform.tfstate
├── environments/
│   ├── dev/
│   │   ├── global/             # Dev global resources
│   │   │   └── terraform.tfstate
│   │   └── us-west-2/          # Dev regional resources
│   │       └── terraform.tfstate
│   └── prod/
│       ├── global/             # Prod global resources
│       │   └── terraform.tfstate
│       ├── us-west-2/          # Prod primary region
│       │   └── terraform.tfstate
│       └── us-east-2/          # Prod secondary region
│           └── terraform.tfstate
└── projects/
    └── account-bootstrap/      # Security project definitions
        └── terraform.tfstate
```

## Migration Process

### Prerequisites

1. AWS credentials configured with access to the state bucket and DynamoDB table
2. Terraform 1.5+ installed
3. Appropriate IAM permissions

### Migration Steps

1. **Using the Migration Script** (Recommended)

   ```bash
   cd /path/to/trm1
   ./iac/scripts/migrate-terraform-state.sh
   ```

   This script will:
   - Process all deployments automatically
   - Create backups of any local state files
   - Initialize each deployment with the S3 backend
   - Verify the migration was successful

2. **Manual Migration** (For Individual Deployments)

   ```bash
   # Navigate to the deployment directory
   cd iac/deploy/[environment]/[region]
   
   # Initialize with backend configuration
   terraform init -backend-config=backend-config.hcl
   
   # If migrating from local state, add -migrate-state flag
   terraform init -backend-config=backend-config.hcl -migrate-state
   
   # Verify the backend is working
   terraform state list
   ```

### Special Case: account-bootstrap

The `account-bootstrap` deployment initially used local state because it creates the S3 bucket and DynamoDB table. After the initial deployment:

1. The backend configuration was updated from `local` to `s3`
2. The existing state was migrated using `terraform init -migrate-state`
3. The local state files were backed up and can be removed

## Working with Backend State

### Initializing a Deployment

When working with any Terraform deployment:

```bash
cd iac/deploy/[environment]/[region]
terraform init -backend-config=backend-config.hcl
```

### Viewing State

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.example

# Pull entire state (be careful with sensitive data)
terraform state pull
```

### State Locking

DynamoDB automatically handles state locking. If a lock is stuck:

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

## Troubleshooting

### Common Issues

1. **Access Denied Errors**
   - Ensure your AWS credentials have access to the S3 bucket and DynamoDB table
   - Check the IAM role permissions

2. **State Lock Timeout**
   - Another operation may be in progress
   - Check DynamoDB table for active locks
   - Use `force-unlock` if necessary (with caution)

3. **Backend Initialization Fails**
   - Verify the backend-config.hcl file exists
   - Check S3 bucket and DynamoDB table exist
   - Ensure KMS key is accessible

### Recovering from Failed Migration

If a migration fails:

1. Check for backup files: `terraform.tfstate.backup.*`
2. Restore from backup if needed
3. Reinitialize with correct configuration
4. Contact team lead if state corruption is suspected

## Best Practices

1. **Always use backend-config.hcl**: Never hardcode backend values in main.tf
2. **Avoid manual state edits**: Use Terraform commands for state manipulation
3. **Regular backups**: S3 versioning provides automatic backups
4. **Lock monitoring**: Check for stuck locks before force-unlocking
5. **State isolation**: Each deployment has its own state file

## Security Considerations

- State files contain sensitive information
- Access is restricted via IAM policies
- Encryption at rest via KMS
- Encryption in transit via TLS
- Access logging enabled for audit trail

## References

- [Terraform S3 Backend Documentation](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)