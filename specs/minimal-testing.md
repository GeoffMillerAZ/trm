# Minimal Testing Requirements

## Overview
This document defines the minimal testing requirements between regional deployments to ensure basic functionality before proceeding with subsequent deployments.

## Testing Philosophy
- **Fast Feedback**: Tests should complete within 2 minutes
- **Basic Validation**: Only test critical infrastructure availability
- **Non-Blocking**: Secondary region failures don't block primary region
- **Progressive**: Each region builds confidence for the next

## Test Scenarios

### 1. Health Check Validation
**Purpose**: Verify the API Gateway and Lambda functions are accessible

**Implementation**:
```bash
curl -f -s "${API_ENDPOINT}/health"
```

**Success Criteria**:
- HTTP 200 OK response
- Response received within 5 seconds
- No requirement on response body content

**Retry Logic**:
- Maximum 6 attempts
- 20-second delay between attempts
- Total timeout: 2 minutes

### 2. API Gateway Availability
**Purpose**: Confirm the API Gateway is routing requests

**What's Tested**:
- API Gateway deployment completed
- Custom domain (if configured) is accessible
- Basic routing is functional

**What's NOT Tested**:
- Authentication/authorization
- Business logic
- Database connectivity
- Cross-region replication

### 3. Lambda Function Status
**Purpose**: Ensure Lambda functions can execute

**Implicit Testing**:
- Health endpoint invokes Lambda function
- Successful response indicates Lambda execution
- Cold start within acceptable limits

## Regional Testing Strategy

### Primary Region (us-west-2)
- **Critical**: Must pass before secondary deployment
- **Failure Action**: Stop deployment, alert team
- **Success Action**: Proceed to secondary region

### Secondary Region (us-east-2)
- **Non-Critical**: Failures logged but don't stop deployment
- **Failure Action**: Mark as degraded, continue deployment
- **Success Action**: Mark deployment as fully successful

## Timing Considerations

### Cold Start Allowance
- First request may take 10-15 seconds (Lambda cold start)
- Subsequent requests should respond within 1-2 seconds
- Total wait time accounts for cold start + stabilization

### Infrastructure Propagation
- API Gateway deployment: 1-2 minutes
- Route53 DNS: Immediate (using direct endpoint)
- Lambda function availability: Immediate after deployment

## Output and Logging

### Success Output
```
✅ Primary region health check passed
```

### Failure Output
```
⏳ Waiting for primary region to be ready... (attempt 3/6)
```

### Skip Conditions
```
⚠️ No API endpoint found, skipping health check
```

## Integration with CI/CD

### GitHub Actions Implementation
- Tests run within the deployment job
- No separate testing job required
- Results influence subsequent steps
- Logs retained for debugging

### Terraform Outputs
- `api_gateway_url`: Used for health check endpoint
- Missing output = skip testing (non-fatal)

## Future Enhancements

### Phase 1: Current Implementation
- Basic health check only
- Manual verification of results
- Simple retry logic

### Phase 2: Enhanced Testing
- Add response time validation
- Check specific Lambda function metrics
- Validate CloudWatch logs generation

### Phase 3: Automated Validation
- Integration tests for critical paths
- Performance baseline comparison
- Automated rollback triggers

## Monitoring During Testing

### CloudWatch Metrics
- API Gateway 4XX/5XX errors
- Lambda invocation errors
- Lambda duration metrics

### Deployment Logs
- All test attempts logged
- Timing information captured
- Failed attempts with error details

## Troubleshooting Guide

### Common Failures

1. **Connection Timeout**
   - Check API Gateway deployment status
   - Verify security groups allow traffic
   - Confirm VPC endpoints configured

2. **503 Service Unavailable**
   - Lambda function not yet available
   - Cold start timeout
   - Wait and retry

3. **No Endpoint Found**
   - Terraform output missing
   - API Gateway not created
   - Check terraform plan/apply logs

### Debug Commands
```bash
# Check API Gateway status
aws apigateway get-rest-apis --region us-west-2

# Check Lambda function status
aws lambda get-function --function-name trm-blockexplorer-main-dev --region us-west-2

# Test endpoint manually
curl -v https://api-dev-us-west-2.trm.geoffmiller.cloud/health
```