# Deployment Strategy Specification

## Overview
This document defines the deployment strategy for the TRM Block Explorer containerized infrastructure using Amazon ECS across multiple environments and regions.

## Deployment Order

### Sequential Deployment Flow
Deployments must follow a strict sequential order to ensure dependencies are met and issues can be isolated:

1. **Account Bootstrap** (one-time setup)
   - Security services (GuardDuty, Inspector)
   - IAM roles for cross-account access
   - S3 buckets for security logs
   - DNS zone setup
   - ECS clusters per environment per region
   - ECR repositories for container images

2. **Global Infrastructure** (per environment)
   - DynamoDB global tables
   - KMS multi-region keys
   - IAM roles and policies
   - Route53 health checks
   - Global CloudWatch alarms

3. **Primary Region** (us-west-2 for dev/staging, us-west-2 for prod)
   - VPC and networking
   - Application Load Balancer
   - ECS services and task definitions
   - API Gateway with VPC Link
   - Regional monitoring
   - **Minimal Testing**: ALB health check validation

4. **Secondary Region** (us-east-2)
   - Same components as primary
   - Configured as replica/failover
   - **Minimal Testing**: Health check endpoint validation

## Minimal Testing Requirements

### Between Regional Deployments
After each regional deployment, perform minimal testing before proceeding:

1. **Health Check Validation**
   - Verify `/health` endpoint returns 200 OK
   - Confirm deployment version in response
   - Maximum wait time: 2 minutes

2. **Basic Connectivity Test**
   - Verify API Gateway is accessible
   - Confirm ECS tasks are healthy via ALB
   - Validate container health checks passing
   - No functional testing required at this stage

### Failure Handling
- If primary region fails testing: STOP deployment
- If secondary region fails testing: Mark as degraded but don't rollback primary
- Log all test results for debugging

## Environment-Specific Considerations

### Development
- Deploy all regions to test multi-region functionality
- Shorter health check intervals (30s)
- Single NAT gateway per region (cost optimization)
- Minimum 2 ECS tasks for high availability
- Use Fargate Spot for cost savings

### Staging
- Mirror production configuration
- Full multi-region deployment
- Standard health check intervals (60s)

### Production
- Requires manual approval before deployment
- Extended health check validation (5 minutes)
- Automated rollback on critical failures
- Minimum 2 ECS tasks on standard Fargate
- Container Insights enabled for deep monitoring

## Rollback Strategy

### Automatic Rollback Triggers
1. Terraform plan shows destructive changes to critical resources
2. Primary region ALB health checks fail after deployment
3. ECS deployment circuit breaker triggers
4. Container image pull failures from ECR

### Manual Rollback Process
1. Revert to previous Terraform state
2. Re-run previous successful deployment
3. Investigate and fix issues before retry

## Implementation Notes

### GitHub Actions Workflow
- Each deployment stage is a separate job
- Regional deployments depend on global deployment success
- Minimal testing implemented as workflow steps
- Artifacts passed between jobs for plan validation

### Terraform State Management
- Separate state files per deployment unit
- S3 backend with DynamoDB locking
- State isolation between regions

### Monitoring During Deployment
- CloudWatch dashboard for deployment metrics
- SNS notifications for deployment failures
- Deployment logs retained for 30 days

## Future Enhancements

1. **Blue/Green Deployment**
   - ECS native blue/green deployments
   - ALB target group switching
   - Container version validation
   - Keep previous task definition for rollback

2. **Canary Deployments**
   - Deploy new ECS tasks alongside existing
   - ALB weighted target groups
   - Monitor container metrics before full deployment
   - Gradual traffic shifting via Route53

3. **Automated Functional Testing**
   - Run integration test suite after deployment
   - Validate critical user journeys
   - Performance baseline comparison