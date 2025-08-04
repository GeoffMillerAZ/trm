# OPA Security Policies for Terraform

## Policy Summary

This document lists all security policies enforced by OPA.

### S3 Policies
1. **S3 Encryption**: All S3 buckets must have server-side encryption enabled
2. **S3 Versioning**: S3 buckets must have versioning enabled (required in prod, warning in dev)
3. **S3 Public Access**: S3 buckets must block public access
4. **S3 Lifecycle**: S3 buckets should have lifecycle policies (warning)
5. **S3 KMS Encryption**: S3 buckets with sensitive data must use KMS encryption

### Lambda Policies
6. **Lambda VPC**: Lambda functions must be in VPC in production
7. **Lambda Environment**: Lambda functions must not have sensitive data in environment variables
8. **Lambda Resources**: Lambda functions should have appropriate memory/timeout settings
9. **Lambda Tracing**: Lambda functions must have X-Ray tracing in production
10. **Lambda Runtime**: Lambda functions must use supported runtimes

### DynamoDB Policies
11. **DynamoDB Encryption**: Tables must have encryption at rest
12. **DynamoDB Backup**: Tables must have point-in-time recovery (required in prod)
13. **DynamoDB Billing**: Tables should use appropriate billing mode
14. **DynamoDB Replicas**: Global tables must have replicas in production
15. **DynamoDB Tags**: Tables must have required tags

### KMS Policies
16. **KMS Rotation**: Keys must have rotation enabled
17. **KMS Deletion**: Keys must have appropriate deletion window
18. **KMS Alias**: Key aliases must follow naming convention
19. **KMS Multi-Region**: Consider multi-region keys in production

### API Gateway Policies
20. **API Authentication**: Methods must have authentication
21. **API Validation**: Should have request validation
22. **API Throttling**: Must have throttling in production
23. **API SSL**: Custom domains must have valid certificates
24. **API Logging**: Stages must have access logging

### IAM Policies
25. **IAM Wildcards**: No wildcard actions in production
26. **IAM Trust**: Proper trust relationships required
27. **IAM Inline**: No inline policies in production
28. **IAM Keys**: Access keys should be rotated

### Network Policies
29. **Security Group Ingress**: No unrestricted ingress
30. **Security Group Description**: Must have descriptions
31. **VPC Flow Logs**: Required in production
32. **Network ACLs**: Should not be overly permissive

### Tagging Policies
33. **Required Tags**: All resources must have Environment, Project, ManagedBy
34. **Production Tags**: Production resources need additional tags
35. **Tag Values**: Must follow naming conventions
