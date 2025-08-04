# Account Bootstrap - Security Services Setup

This Terraform project sets up account-wide AWS security services that are shared across all environments. It provides the foundation for a comprehensive DevSecOps implementation.

## Overview

The Account Bootstrap configures essential security services at the AWS account level:
- **AWS GuardDuty**: Threat detection and continuous monitoring
- **AWS Inspector v2**: Vulnerability scanning for Lambda functions
- **S3 Buckets**: Centralized storage for security findings and SBOMs
- **IAM Roles**: Cross-service permissions for security scanning
- **KMS Keys**: Encryption for security data
- **EventBridge Rules**: Automated response to security events

## Prerequisites

1. **AWS Account**: Administrator access to configure security services
2. **Terraform**: Version 1.5 or later
3. **AWS CLI**: Configured with appropriate credentials
4. **S3 Backend**: Terraform state bucket (see setup instructions below)

## Quick Start

### 1. Create Terraform State Backend

```bash
# Set your AWS account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create S3 bucket for Terraform state
aws s3 mb s3://trm-terraform-state-${AWS_ACCOUNT_ID} --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket trm-terraform-state-${AWS_ACCOUNT_ID} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket trm-terraform-state-${AWS_ACCOUNT_ID} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2
```

### 2. Configure Backend

Create `backend.conf`:
```hcl
bucket         = "trm-terraform-state-{your-account-id}"
key            = "account-bootstrap/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "terraform-state-locks"
encrypt        = true
```

### 3. Create Variables File

Create `terraform.tfvars`:
```hcl
primary_region   = "us-west-2"
secondary_region = "us-east-2"

# Security settings
enable_guardduty              = true
enable_inspector              = true
enable_lambda_scanning        = true
enable_multi_region_guardduty = false  # Set to true for production

# Retention settings
security_findings_retention_days = 90
sbom_retention_days             = 365

# Notifications (optional)
notification_email = "security-alerts@example.com"

# Tags
tags = {
  Owner      = "Security Team"
  CostCenter = "Security"
  Project    = "AccountBootstrap"
}
```

### 4. Deploy

```bash
# Initialize Terraform
terraform init -backend-config=backend.conf

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Account Bootstrap                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │  GuardDuty  │    │ Inspector v2 │    │   S3 Buckets │    │
│  │             │    │              │    │              │    │
│  │ • Threat    │    │ • Lambda     │    │ • Findings   │    │
│  │   Detection │    │   Scanning   │    │ • SBOMs      │    │
│  │ • S3 Logs   │    │ • SBOM Gen   │    │ • Reports    │    │
│  └─────────────┘    └──────────────┘    └──────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                   EventBridge Rules                 │    │
│  │                                                     │    │
│  │  • High Severity Findings → SNS Notifications       │    │
│  │  • Weekly SBOM Exports → Lambda Function            │    │
│  │  • Security Events → S3 Storage                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │  IAM Roles  │    │   KMS Keys   │    │ SNS Topics   │    │
│  │             │    │              │    │              │    │
│  │ • Scanner   │    │ • Security   │    │ • Alerts     │    │
│  │ • GitHub    │    │   Services   │    │ • Critical   │    │
│  │ • Lambda    │    │ • Encryption │    │   Findings   │    │
│  └─────────────┘    └──────────────┘    └──────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Resources Created

### Security Services
- **GuardDuty Detector**: Threat detection with S3 protection enabled
- **Inspector v2**: Lambda vulnerability scanning with automated SBOM generation
- **EventBridge Rules**: Automated response to security findings

### Storage
- **Security Findings Bucket**: `{account-id}-security-findings`
- **SBOM Exports Bucket**: `{account-id}-sbom-exports`
- **Security Reports Bucket**: `{account-id}-security-reports`

### IAM Roles
- **Security Scanner Role**: For CodeGuru and Inspector access
- **Inspector Lambda Role**: For Lambda function scanning
- **GitHub Actions Role**: For CI/CD security integration
- **SBOM Exporter Lambda Role**: For automated SBOM generation

### Lambda Functions
- **SBOM Exporter**: Automatically exports SBOMs weekly

### Monitoring
- **SNS Topic**: Security alerts for high-severity findings
- **CloudWatch Events**: Capture and route security events

## Configuration Options

### Enable/Disable Services

```hcl
# Core security services
enable_guardduty = true
enable_inspector = true

# Future Security Hub integration
enable_security_hub = false  # Set to true when ready

# Multi-region support
enable_multi_region_guardduty = false  # Set to true for production
```

### Scanning Options

```hcl
# Inspector scanning targets
enable_lambda_scanning = true
enable_ec2_scanning    = false  # Not needed for serverless
enable_ecr_scanning    = false  # Enable if using containers
```

### Retention Policies

```hcl
# How long to keep security data
security_findings_retention_days = 90   # 3 months
sbom_retention_days             = 365  # 1 year
```

## Integration with CI/CD

The bootstrap creates IAM roles that can be assumed by GitHub Actions:

```yaml
# In your GitHub Actions workflow
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-security-scanner
    aws-region: us-west-2
```

## Security Hub Integration (Future)

The configuration includes comprehensive comments for enabling AWS Security Hub when ready. To enable:

1. Uncomment the Security Hub section in `main.tf`
2. Set `enable_security_hub = true` in your variables
3. Run `terraform apply`

Security Hub provides:
- Centralized security findings dashboard
- Compliance checking (CIS, AWS Foundational)
- Custom insights for Lambda vulnerabilities
- Multi-region finding aggregation

## Monitoring and Alerts

### Email Notifications
Configure email alerts for critical findings:
```hcl
notification_email = "security-team@example.com"
```

### Finding Severity Levels
- **CRITICAL** (9.0-10.0): Immediate action required
- **HIGH** (7.0-8.9): Address within 24 hours
- **MEDIUM** (4.0-6.9): Address within 7 days
- **LOW** (0.1-3.9): Address in next release

## Cost Considerations

Estimated monthly costs (varies by usage):
- **GuardDuty**: ~$4/month base + usage
- **Inspector v2**: $0.30/Lambda function/month
- **S3 Storage**: ~$0.023/GB/month
- **KMS**: $1/month per key + API calls

## Maintenance

### Regular Tasks
1. **Review Security Findings**: Check GuardDuty and Inspector findings weekly
2. **Update Threat Lists**: Add known bad IPs to GuardDuty threat intel
3. **SBOM Analysis**: Review generated SBOMs for new vulnerabilities
4. **Cost Monitoring**: Track security service costs monthly

### Updating the Bootstrap
```bash
# Pull latest changes
git pull

# Review changes
terraform plan

# Apply updates
terraform apply
```

## Troubleshooting

### Common Issues

1. **GuardDuty Not Finding Threats**
   - Check if S3 protection is enabled
   - Verify finding publishing frequency
   - Review EventBridge rules

2. **Inspector Not Scanning**
   - Ensure Lambda functions have proper tags
   - Check IAM permissions
   - Verify Inspector is enabled in the region

3. **Missing SBOM Exports**
   - Check Lambda function logs
   - Verify S3 bucket permissions
   - Ensure EventBridge rule is active

### Debug Commands

```bash
# Check GuardDuty status
aws guardduty list-detectors
aws guardduty get-detector --detector-id <id>

# Check Inspector status
aws inspector2 list-coverage

# View recent findings
aws inspector2 list-findings --filter-criteria '{"severity": [{"comparison": "EQUALS", "value": "HIGH"}]}'

# Check EventBridge rules
aws events list-rules --name-prefix security
```

## Next Steps

1. **Enable Security Hub**: When ready for centralized findings
2. **Add Custom Threat Lists**: Import known malicious IPs
3. **Configure SIEM Integration**: Export findings to your SIEM
4. **Set Up Automated Remediation**: Lambda functions for auto-response
5. **Enable Config Rules**: For compliance monitoring

## Support

For issues or questions:
1. Check CloudWatch Logs for error messages
2. Review terraform plan output for configuration issues
3. Consult AWS documentation for service-specific details

## Security Best Practices

1. **Least Privilege**: Only grant necessary permissions
2. **Encryption**: All security data is encrypted at rest
3. **Monitoring**: Regular review of security findings
4. **Automation**: Use EventBridge for automated responses
5. **Multi-Region**: Enable for production workloads
