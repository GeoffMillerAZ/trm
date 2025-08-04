# DNS Architecture

## Overview

This document describes the DNS architecture for the TRM project, which uses subdomain delegation from Namecheap to AWS Route53 for managing project-specific DNS records.

## Architecture Design

### Domain Hierarchy

```
geoffmiller.cloud (Root Domain - Managed in Namecheap)
└── trm.geoffmiller.cloud (Subdomain - Delegated to Route53)
    ├── trm.geoffmiller.cloud (Production)
    ├── dev.trm.geoffmiller.cloud (Development)
    └── staging.trm.geoffmiller.cloud (Staging - Optional)
```

### Key Design Decisions

1. **Root Domain Control**: The root domain `geoffmiller.cloud` remains fully managed in Namecheap, preserving existing DNS records and configurations.

2. **Subdomain Delegation**: Only the `trm` subdomain is delegated to AWS Route53, providing:
   - Complete control over project-specific DNS records
   - AWS service integration (CloudFront, ALB, etc.)
   - Infrastructure as Code management via Terraform
   - Environment isolation

3. **Clean Production URLs**: Production uses `trm.geoffmiller.cloud` without environment indicators for better user experience.

## Implementation

### 1. AWS Route53 Setup (Automated via Terraform)

The account bootstrap layer creates the following hosted zones:

- **Production Zone**: `trm.geoffmiller.cloud`
- **Development Zone**: `dev.trm.geoffmiller.cloud`
- **Staging Zone**: `staging.trm.geoffmiller.cloud` (optional)

### 2. Namecheap Configuration (Manual One-Time Setup)

Add NS records in Namecheap to delegate the subdomain:

1. Log in to Namecheap Dashboard
2. Navigate to Domain List → Manage → Advanced DNS
3. Add NS records for the subdomain:

```
Host: trm
Type: NS
Value: [AWS Route53 Nameservers]
TTL: 30 min
```

You'll need to add 4 separate NS records, one for each nameserver provided by AWS.

### 3. DNS Record Management

Once delegation is complete, all DNS records under `trm.geoffmiller.cloud` are managed in Route53:

#### Production Records (in trm.geoffmiller.cloud zone)
- `trm.geoffmiller.cloud` → CloudFront distribution
- `api.trm.geoffmiller.cloud` → API Gateway or ALB
- `*.trm.geoffmiller.cloud` → Wildcard for services

#### Development Records (in dev.trm.geoffmiller.cloud zone)
- `dev.trm.geoffmiller.cloud` → Dev CloudFront
- `api.dev.trm.geoffmiller.cloud` → Dev API
- `*.dev.trm.geoffmiller.cloud` → Dev services

## Benefits

1. **Separation of Concerns**: Root domain remains in Namecheap for non-project use
2. **AWS Integration**: Direct integration with AWS services (ACM, CloudFront, etc.)
3. **Environment Isolation**: Clear separation between dev/staging/prod
4. **Infrastructure as Code**: All project DNS managed via Terraform
5. **Cost Efficiency**: Only pay for Route53 zones actually used

## DNS Propagation

After configuring NS records in Namecheap:
- Initial propagation: 15-30 minutes
- Full global propagation: 24-48 hours
- TTL for NS records: 48 hours (for stability)

## Verification

Test DNS delegation after setup:

```bash
# Check NS records for subdomain
dig NS trm.geoffmiller.cloud

# Verify nameservers match AWS Route53
dig NS trm.geoffmiller.cloud @8.8.8.8

# Test specific records (after adding them in Route53)
dig A trm.geoffmiller.cloud
dig A dev.trm.geoffmiller.cloud
```

## Security Considerations

1. **CAA Records**: Automatically configured to restrict certificate issuance to AWS
2. **DNSSEC**: Not enabled by default (can be added if required)
3. **SPF Records**: Set to deny all email (`v=spf1 -all`) as these domains don't send email

## Cost Analysis

- **Namecheap**: No additional cost (included with domain)
- **Route53**: $0.50/month per hosted zone
  - Production zone: $0.50/month
  - Development zone: $0.50/month
  - Total: ~$1.00/month for DNS infrastructure

## Troubleshooting

### Common Issues

1. **NS Records Not Propagating**
   - Verify NS records are correctly entered in Namecheap
   - Check TTL settings (lower for faster propagation during setup)
   - Use multiple DNS checkers to verify

2. **Certificate Validation Failing**
   - Ensure CAA records allow AWS certificate authorities
   - Verify DNS records are accessible from multiple regions
   - Check Route53 zone is properly configured

3. **Subdomain Not Resolving**
   - Confirm nameservers from Route53 match those in Namecheap
   - Verify no conflicting records exist in Namecheap
   - Check Route53 zone status is active

## Future Enhancements

1. **DNSSEC**: Enable DNSSEC for additional security
2. **Route53 Resolver**: For hybrid cloud DNS resolution
3. **DNS Failover**: Configure health checks and failover routing
4. **GeoDNS**: Route traffic based on geographic location

The architecture uses a public Network Load Balancer (NLB) to expose the service. The NLB routes traffic to the ECS service, which runs in a private subnet. This provides a secure and scalable way to expose the service to the internet.
