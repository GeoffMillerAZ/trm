# Setting up geoffmiller.cloud Domain with Namecheap and AWS Route53

This guide walks you through configuring the `geoffmiller.cloud` domain purchased from Namecheap to work with our AWS infrastructure using Route53.

## Prerequisites

- Domain `geoffmiller.cloud` registered with Namecheap
- AWS account with appropriate IAM permissions for Route53
- Terraform infrastructure deployed in AWS

## Architecture Overview

```
[Namecheap] --> [AWS Route53 Hosted Zone] --> [API Gateway Custom Domain]
                                           --> [CloudFront Distribution]
                                           --> [Other AWS Services]
```

## Step 1: Create Route53 Hosted Zone

The Terraform configuration will create a Route53 hosted zone when you set these variables:

### For Development Environment

Edit `iac/deploy/dev/global/terraform.tfvars`:
```hcl
domain_name        = "geoffmiller.cloud"
create_hosted_zone = true
hosted_zone_id     = null  # Will be created
```

### For Production Environment

Edit `iac/deploy/prod/global/terraform.tfvars`:
```hcl
domain_name        = "geoffmiller.cloud"
create_hosted_zone = true
hosted_zone_id     = null  # Will be created
```

### Deploy the Global Infrastructure

```bash
# Development
cd iac/deploy/dev/global
terraform init
terraform plan
terraform apply

# Production
cd iac/deploy/prod/global
terraform init
terraform plan
terraform apply
```

## Step 2: Get Route53 Name Servers

After deploying, get the name servers from Route53:

```bash
# Using AWS CLI
aws route53 get-hosted-zone --id <hosted-zone-id> --query 'DelegationSet.NameServers'

# Or from Terraform output
cd iac/deploy/dev/global
terraform output nameservers
```

You'll get 4 name servers like:
- ns-1234.awsdns-12.org
- ns-5678.awsdns-34.co.uk
- ns-9012.awsdns-56.com
- ns-3456.awsdns-78.net

## Step 3: Configure Namecheap

1. **Log in to Namecheap** at https://www.namecheap.com

2. **Navigate to Domain List**
   - Click on "Domain List" in your account dashboard
   - Find `geoffmiller.cloud` and click "Manage"

3. **Change Name Servers**
   - In the "Domain" tab, find "NAMESERVERS" section
   - Select "Custom DNS" from the dropdown
   - Remove existing nameservers
   - Add the 4 AWS Route53 nameservers from Step 2
   - Click the checkmark to save

4. **Verify Changes**
   - Changes typically take 24-48 hours to propagate
   - You can verify using: `dig NS geoffmiller.cloud`

## Step 4: Create SSL Certificate

For HTTPS, create an ACM certificate in each region:

### Update Terraform Variables

Edit `iac/deploy/dev/us-west-2/terraform.tfvars`:
```hcl
# API Gateway custom domain
custom_domain_name = "api.geoffmiller.cloud"  # or "dev-api.geoffmiller.cloud"
certificate_arn    = null  # Will be created by ACM
```

### Request Certificate via AWS Console

1. Go to AWS Certificate Manager in `us-west-2`
2. Click "Request a certificate"
3. Choose "Request a public certificate"
4. Add domain names:
   - `geoffmiller.cloud`
   - `*.geoffmiller.cloud`
5. Choose "DNS validation"
6. Complete the request

### Validate Certificate

1. In ACM, click on the certificate
2. Under "Domains", click "Create records in Route53"
3. AWS will automatically create the validation records
4. Wait for certificate status to change to "Issued" (usually 5-30 minutes)

## Step 5: Deploy Regional Infrastructure

Once the certificate is issued, update your Terraform:

```bash
# Get the certificate ARN
aws acm list-certificates --region us-west-2

# Update terraform.tfvars with the ARN
certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/..."

# Deploy
cd iac/deploy/dev/us-west-2
terraform init
terraform plan
terraform apply
```

## Step 6: Configure Subdomains

The Terraform creates these DNS records automatically:

### API Gateway Endpoints
- `api.geoffmiller.cloud` - Production API
- `dev-api.geoffmiller.cloud` - Development API
- `api-us-west-2.geoffmiller.cloud` - Region-specific endpoint
- `api-us-east-2.geoffmiller.cloud` - Region-specific endpoint

### Multi-Region Setup (If Enabled)
The infrastructure supports failover between regions:
- Primary: us-west-2
- Secondary: us-east-2

Health checks monitor endpoint availability and automatically failover if needed.

## Step 7: Testing

### DNS Resolution
```bash
# Test nameserver configuration
dig NS geoffmiller.cloud

# Test A record resolution
dig A api.geoffmiller.cloud

# Test from multiple locations
nslookup api.geoffmiller.cloud 8.8.8.8
```

### HTTPS Connectivity
```bash
# Test API endpoint
curl -v https://api.geoffmiller.cloud/health

# Test certificate
openssl s_client -connect api.geoffmiller.cloud:443 -servername api.geoffmiller.cloud
```

## Common Issues and Solutions

### DNS Not Resolving
- **Issue**: Domain doesn't resolve after 48 hours
- **Solution**: 
  - Verify nameservers in Namecheap match Route53
  - Check Route53 hosted zone exists and has records
  - Use `whois geoffmiller.cloud` to verify nameserver changes

### Certificate Validation Failed
- **Issue**: ACM certificate stuck in "Pending validation"
- **Solution**:
  - Ensure Route53 has the CNAME validation records
  - Wait up to 72 hours for DNS propagation
  - Try manual validation if automatic fails

### API Gateway Custom Domain Error
- **Issue**: "The certificate must be in the same region"
- **Solution**:
  - Ensure certificate is created in the same region as API Gateway
  - For edge-optimized APIs, certificate must be in us-east-1
  - For regional APIs, certificate must be in the same region

### 403 Forbidden on API Access
- **Issue**: Getting 403 when accessing custom domain
- **Solution**:
  - Verify base path mapping in API Gateway
  - Check API Gateway stage is deployed
  - Ensure DNS record points to correct API Gateway domain

## Terraform Configuration Reference

### Global Configuration
```hcl
# iac/projects/trm-blockexplorer/global/main.tf
resource "aws_route53_zone" "main" {
  count = var.create_hosted_zone ? 1 : 0
  name  = var.domain_name
  
  tags = {
    Name        = var.domain_name
    Environment = var.environment
    Project     = var.project_name
  }
}
```

### Regional Configuration
```hcl
# iac/modules/api-gateway/custom_domain.tf
resource "aws_api_gateway_domain_name" "custom" {
  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.certificate_arn
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
```

## Security Considerations

1. **DNSSEC**: Consider enabling DNSSEC in Route53 for additional security
2. **CAA Records**: Add CAA records to specify which CAs can issue certificates
3. **API Keys**: Use API Gateway API keys for additional security
4. **WAF**: Consider adding AWS WAF to protect your API endpoints

## Cost Considerations

- **Route53 Hosted Zone**: $0.50/month per hosted zone
- **DNS Queries**: $0.40 per million queries
- **Health Checks**: $0.50/month per health check
- **ACM Certificates**: Free for AWS resources

## Next Steps

1. **Monitor DNS**: Set up Route53 query logging
2. **Configure Alarms**: Create CloudWatch alarms for health check failures
3. **Add More Records**: Configure additional subdomains as needed
4. **Enable DNSSEC**: For enhanced security

## Useful Commands

```bash
# Check current nameservers
dig NS geoffmiller.cloud +short

# Check specific record
dig A api.geoffmiller.cloud +short

# Check DNS propagation
host api.geoffmiller.cloud 8.8.8.8

# Test SSL certificate
curl -vI https://api.geoffmiller.cloud

# View Route53 hosted zones
aws route53 list-hosted-zones

# View Route53 records
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>
```