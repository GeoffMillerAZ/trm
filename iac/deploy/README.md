# TRM Block Explorer - Terraform Deployment Configurations

This directory contains environment-specific Terraform deployment configurations for the TRM Block Explorer infrastructure. The configurations are organized by environment and region to support both single-region development and multi-region production deployments.

## Directory Structure

```
iac/deploy/
├── README.md                    # This file
├── dev/                         # Development environment (single region)
│   ├── global/                  # Global resources (Route 53, KMS, IAM)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── us-west-2/              # Regional resources (VPC, Lambda, API Gateway)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── prod/                       # Production environment (multi-region)
    ├── global/                 # Global resources with multi-region support
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── us-west-2/             # Primary region
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── us-east-2/             # Secondary region for disaster recovery
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Environment Overview

### Development Environment
- **Purpose**: Development, testing, and feature validation
- **Regions**: Single region (us-west-2)
- **Cost Optimization**: Enabled (smaller instances, shorter retention, single NAT Gateway)
- **Features**: Debug logging, API caching disabled, development API keys
- **Multi-region**: Disabled
- **Backup retention**: 7 days

### Production Environment
- **Purpose**: Live production workloads
- **Regions**: Multi-region (us-west-2 primary, us-east-2 secondary)
- **High Availability**: Active-active deployment with Route 53 failover
- **Features**: Enhanced monitoring, X-Ray tracing, API caching enabled
- **Multi-region**: Enabled with DynamoDB Global Tables
- **Backup retention**: 30 days
- **Disaster Recovery**: < 5 minutes RTO, < 1 minute RPO

## Deployment Prerequisites

### 1. Terraform State Backend

Before deploying, create an S3 bucket and DynamoDB table for Terraform state management:

```bash
# Create state bucket (replace {account-id} with your AWS account ID)
aws s3 mb s3://trm-blockexplorer-terraform-state-{account-id}-us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket trm-blockexplorer-terraform-state-{account-id}-us-west-2 \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket trm-blockexplorer-terraform-state-{account-id}-us-west-2 \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name trm-blockexplorer-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2
```

### 2. Backend Configuration Files

Create backend configuration files for each deployment:

```bash
# Example: dev-global-backend.conf
bucket         = "trm-blockexplorer-terraform-state-{account-id}-us-west-2"
key            = "environments/dev/global/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "trm-blockexplorer-terraform-locks"
encrypt        = true
```

### 3. Lambda Deployment Package

For development environments, ensure the Lambda deployment package exists:

```bash
# Create deployment package (from project root)
cd src/
zip -r ../iac/deploy/lambda_package.zip . -x "__pycache__/*" "*.pyc" "tests/*"
```

For production, the deployment package should be managed through CI/CD pipelines using S3.

## Deployment Order

### Development Environment

1. **Deploy Global Resources**:
   ```bash
   cd iac/deploy/dev/global/
   terraform init -backend-config=dev-global-backend.conf
   terraform plan -var-file=dev-global.tfvars
   terraform apply -var-file=dev-global.tfvars
   ```

2. **Deploy Regional Resources**:
   ```bash
   cd ../us-west-2/
   terraform init -backend-config=dev-usw2-backend.conf
   terraform plan -var-file=dev-usw2.tfvars
   terraform apply -var-file=dev-usw2.tfvars
   ```

### Production Environment

1. **Deploy Global Resources**:
   ```bash
   cd iac/deploy/prod/global/
   terraform init -backend-config=prod-global-backend.conf
   terraform plan -var-file=prod-global.tfvars
   terraform apply -var-file=prod-global.tfvars
   ```

2. **Deploy Primary Region (us-west-2)**:
   ```bash
   cd ../us-west-2/
   terraform init -backend-config=prod-usw2-backend.conf
   terraform plan -var-file=prod-usw2.tfvars
   terraform apply -var-file=prod-usw2.tfvars
   ```

3. **Deploy Secondary Region (us-east-2)**:
   ```bash
   cd ../us-east-2/
   terraform init -backend-config=prod-use2-backend.conf
   terraform plan -var-file=prod-use2.tfvars
   terraform apply -var-file=prod-use2.tfvars
   ```

## Required Variables

### Global Variables (All Environments)
- `domain_name`: Domain name for the application
- `alarm_email_endpoints`: Email addresses for monitoring alerts

### Regional Variables
- `terraform_state_bucket`: S3 bucket for Terraform state
- `lambda_deployment_package`: Lambda deployment configuration
- `alarm_email_endpoints`: Email addresses for regional alerts

### Production-Specific Variables
- `api_keys`: Production API key configurations
- `hosted_zone_id`: Route 53 hosted zone ID (if existing)

## Example Variable Files

### Development Global (`dev-global.tfvars`)
```hcl
project_name = "trm-blockexplorer"
environment = "dev"
primary_region = "us-west-2"
domain_name = "dev-api.example.com"
enable_multi_region = false
create_hosted_zone = true
alarm_email_endpoints = ["dev-alerts@example.com"]
```

### Production Global (`prod-global.tfvars`)
```hcl
project_name = "trm-blockexplorer"
environment = "prod"
primary_region = "us-west-2"
secondary_region = "us-east-2"
domain_name = "api.example.com"
enable_multi_region = true
hosted_zone_id = "Z1234567890ABC"
alarm_email_endpoints = ["prod-alerts@example.com", "oncall@example.com"]
```

## Monitoring and Operations

### Development Environment
- **Dashboard**: CloudWatch dashboard with basic metrics
- **Logging**: DEBUG level with 7-day retention
- **API Keys**: Single development key with generous limits
- **Caching**: Disabled for testing flexibility

### Production Environment
- **Dashboard**: Comprehensive CloudWatch dashboards for both regions
- **Logging**: INFO level with 30-day retention
- **X-Ray Tracing**: Enabled for performance monitoring
- **API Keys**: Tiered keys (basic, standard, premium) with appropriate limits
- **Caching**: Enabled with 5-minute TTL
- **Health Checks**: Route 53 health checks with automatic failover

## Disaster Recovery

The production environment implements an active-active multi-region architecture:

- **Primary Region**: us-west-2 handles majority of traffic
- **Secondary Region**: us-east-2 provides failover capability
- **Data Replication**: DynamoDB Global Tables with near real-time sync
- **Traffic Routing**: Route 53 latency-based routing with health checks
- **Failover Time**: < 5 minutes RTO, < 1 minute RPO

## Cost Management

### Development Optimizations
- Single NAT Gateway instead of multi-AZ
- Smaller Lambda memory allocation (512MB vs 1024MB)
- Shorter log retention (7 days vs 30 days)
- API caching disabled
- Lower API throttling limits

### Production Considerations
- Multi-AZ NAT Gateways for high availability
- Full Lambda memory allocation for performance
- Extended log retention for compliance
- API caching enabled for cost reduction
- Multiple usage tiers for revenue optimization

## Security Considerations

- All data encrypted at rest using KMS
- Lambda functions run in private subnets
- VPC endpoints for AWS service communication
- IAM roles follow least privilege principle
- API Gateway with usage plans and API keys
- CloudWatch logs encrypted with KMS

## Troubleshooting

### Common Issues

1. **Terraform State Conflicts**:
   - Ensure proper backend configuration
   - Check DynamoDB lock table permissions
   - Verify S3 bucket access

2. **Lambda Deployment Failures**:
   - Verify deployment package exists and is accessible
   - Check IAM role permissions
   - Ensure VPC configuration allows internet access

3. **DynamoDB Global Tables**:
   - Tables must exist in both regions before enabling Global Tables
   - Ensure consistent table schemas across regions
   - Monitor replication lag metrics

4. **Route 53 Health Checks**:
   - Verify health check endpoints are accessible
   - Check security group rules for health check IPs
   - Monitor health check CloudWatch metrics

### Useful Commands

```bash
# Check deployment status
terraform output

# View sensitive outputs (API keys)
terraform output -raw api_keys

# Refresh state
terraform refresh

# Plan changes
terraform plan -var-file=environment.tfvars

# Apply specific resource
terraform apply -target=module.regional.aws_lambda_function.main

# Destroy environment (be careful!)
terraform destroy -var-file=environment.tfvars
```

## Next Steps

1. Create backend configuration files for your AWS account
2. Update variable files with your specific values
3. Deploy development environment first for testing
4. Validate functionality before deploying production
5. Set up CI/CD pipelines for automated deployments
6. Configure monitoring and alerting
7. Document runbooks for operations team

For more information, refer to the module documentation in `iac/modules/` and project documentation in `iac/projects/`.