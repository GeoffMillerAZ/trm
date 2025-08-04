# Terraform State Lock Handling

## Issue Description

Terraform uses state locking to prevent concurrent modifications to infrastructure. When a terraform operation is interrupted or a local operation doesn't complete properly, the state can remain locked, causing subsequent operations to fail with:

```
Error: Error acquiring the state lock
ConditionalCheckFailedException: The conditional request failed
```

## Current Lock Information

From the latest workflow run, we observed:
- **Lock ID**: c7b510a5-aac5-f4a8-f92f-734d0f9bda62
- **State Path**: trm-blockexplorer-terraform-state-754419183698-us-west-2/environments/dev/us-west-2/terraform.tfstate
- **Locked By**: geoff@mac-mini-workstation.miller
- **Operation**: OperationTypeApply

## Manual Resolution

### Option 1: Force Unlock (Recommended for stuck locks)
```bash
cd iac/deploy/dev/us-west-2
terraform force-unlock c7b510a5-aac5-f4a8-f92f-734d0f9bda62
```

### Option 2: Remove Lock from DynamoDB
```bash
aws dynamodb delete-item \
  --table-name trm-blockexplorer-terraform-locks \
  --key '{"LockID":{"S":"trm-blockexplorer-terraform-state-754419183698-us-west-2/environments/dev/us-west-2/terraform.tfstate"}}'
```

## Automated Handling in CI/CD

The deploy workflow now includes automatic retry logic for state lock issues:

1. **Initial Attempt**: Try to acquire lock normally
2. **Retry Logic**: If lock acquisition fails, wait 30 seconds and retry
3. **Maximum Retries**: 3 attempts before failing
4. **Total Wait Time**: Up to 90 seconds for lock release

## Prevention Strategies

### 1. Always Use Timeout in Local Operations
```bash
terraform apply -lock-timeout=5m
```

### 2. Ensure Clean Exit
- Always let terraform operations complete
- Use Ctrl+C gracefully (once) to trigger proper cleanup
- Avoid force-killing terraform processes

### 3. Use Remote Operations
Consider using Terraform Cloud or AWS Systems Manager for remote operations to avoid local lock issues.

## Lock Timeout Configuration

In the workflow, we've added:
```bash
terraform plan -out=tfplan -lock-timeout=30s
```

This allows terraform to wait up to 30 seconds to acquire a lock before failing.

## Monitoring

### Check for Active Locks
```bash
aws dynamodb scan \
  --table-name trm-blockexplorer-terraform-locks \
  --filter-expression "attribute_exists(LockID)"
```

### CloudWatch Alarms
Consider setting up CloudWatch alarms for:
- DynamoDB table with items older than 30 minutes
- Failed terraform operations in CI/CD

## Emergency Procedures

If locks are consistently problematic:

1. **Check for Stuck CI/CD Jobs**: Ensure no other workflow runs are active
2. **Verify Local Operations**: Check with team members for active terraform operations
3. **Force Unlock if Necessary**: Use the force-unlock command after confirming no active operations
4. **Document the Incident**: Log who held the lock and why it was stuck

## Best Practices

1. **CI/CD Only Deployments**: Minimize local terraform apply operations
2. **Lock Timeouts**: Always use -lock-timeout flag
3. **Clean Workspace**: Ensure local terraform operations complete cleanly
4. **Communication**: Notify team when running long terraform operations locally