# Account Bootstrap Deployment

This deployment creates the foundational AWS resources required before any other infrastructure can be deployed. It must be deployed manually by an administrator with appropriate AWS permissions.

## Prerequisites

- AWS CLI configured with administrative credentials
- Terraform >= 1.5
- Access to create IAM roles, S3 buckets, and security services

## What This Creates

- **Security Services**:
  - AWS GuardDuty for threat detection (with optional multi-region support)
  - AWS Inspector v2 for vulnerability scanning (Lambda, EC2, and ECR)
  - AWS Security Hub for centralized findings (optional)
  
- **Security Storage**:
  - S3 bucket for security findings
  - S3 bucket for SBOM (Software Bill of Materials) exports
  - S3 bucket for security reports
  
- **IAM Roles**:
  - Security scanner role for cross-service access
  - Inspector Lambda integration role
  
- **KMS Encryption**:
  - Dedicated KMS key for encrypting security data
  
- **Notifications**:
  - SNS topic for security alerts (if email provided)

## Deployment Steps

### 1. Prerequisites

Ensure you have the Terraform backend infrastructure already set up. If not, you'll need to create:
- S3 bucket for Terraform state
- DynamoDB table for state locking

### 2. Deploy Account Bootstrap

```bash
# Copy and update the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your settings
vim terraform.tfvars

# Initialize Terraform
# If using S3 backend, provide backend config:
terraform init \
  -backend-config="bucket=your-terraform-state-bucket" \
  -backend-config="key=account-bootstrap/terraform.tfstate" \
  -backend-config="region=us-west-2" \
  -backend-config="dynamodb_table=your-terraform-locks-table"

# Or for local backend during initial setup:
terraform init

# Review the planned changes
terraform plan

# Apply the configuration
terraform apply
```

### 3. Enable Additional Services (Optional)

To enable additional services after initial deployment:

```bash
# Enable Security Hub
terraform apply -var="enable_security_hub=true"

# Enable multi-region GuardDuty
terraform apply -var="enable_multi_region_guardduty=true"

# Enable container scanning
terraform apply -var="enable_ecr_scanning=true"
```

## Important Notes

- This deployment should only be run once per AWS account
- The resources created are shared across all environments
- Do not delete these resources as they are required by all other deployments
- The terraform state for this deployment is critical - ensure it's backed up

## Outputs

After successful deployment, you'll receive:

- GuardDuty detector ID and status
- Inspector enablement status
- Security bucket names and ARNs (findings, SBOM, reports)
- IAM role ARNs for security services
- KMS key ARN and alias for encryption
- SNS topic ARN for alerts (if configured)
- Account and region information
- Complete security services configuration summary

These outputs can be referenced by other Terraform deployments or used for integration with external security tools.

## Troubleshooting

If you encounter permission errors:
1. Ensure your AWS credentials have administrative access
2. Check that your account doesn't have SCPs blocking required services
3. Verify the AWS region is correct and available

For state migration issues:
1. Ensure the S3 bucket was created successfully
2. Verify your credentials have access to the bucket
3. Check the bucket name matches exactly in the backend configuration