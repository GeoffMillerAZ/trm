package terraform.security.aws.s3

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.lib.helpers as h

# Policy 1: S3 buckets must have encryption enabled
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_s3_bucket")[_]
    
    # Check if server-side encryption is configured
    not resource.values.server_side_encryption_configuration
    
    msg := h.format_violation(plan, resource, "S3 bucket must have server-side encryption enabled")
}

# Policy 2: S3 buckets must have versioning enabled in production
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_s3_bucket")[_]
    
    # Check for versioning configuration
    not resource.values.versioning[0].enabled == true
    
    msg := h.format_violation(plan, resource, "S3 bucket must have versioning enabled in production")
}

# Warning for dev environments
warn contains msg if {
    plan := input
    h.is_development(plan)
    resource := h.resources_by_type(plan, "aws_s3_bucket")[_]
    
    not resource.values.versioning[0].enabled == true
    
    msg := h.format_violation(plan, resource, "S3 bucket should have versioning enabled")
}

# Policy 3: S3 buckets must block public access
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_s3_bucket")[_]
    
    # Check if bucket has public access block configuration
    public_access_blocks := h.resources_by_type(plan, "aws_s3_bucket_public_access_block")
    bucket_has_block := [b | b := public_access_blocks[_]; b.values.bucket == resource.values.id]
    count(bucket_has_block) == 0
    
    msg := h.format_violation(plan, resource, "S3 bucket must have public access block configured")
}

# Policy 4: S3 buckets must have lifecycle policies for cost optimization
warn contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_s3_bucket")[_]
    
    # Check for lifecycle configuration
    lifecycle_configs := h.resources_by_type(plan, "aws_s3_bucket_lifecycle_configuration")
    bucket_has_lifecycle := [l | l := lifecycle_configs[_]; l.values.bucket == resource.values.id]
    count(bucket_has_lifecycle) == 0
    
    msg := h.format_violation(plan, resource, "S3 bucket should have lifecycle policies for cost optimization")
}

# Policy 5: S3 buckets storing sensitive data must use KMS encryption
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_s3_bucket")[_]
    
    # Check if bucket name indicates sensitive data
    h.contains_sensitive_data(resource.values.bucket)
    
    # Check encryption configuration
    enc_config := resource.values.server_side_encryption_configuration[0].rule[0].apply_server_side_encryption_by_default[0]
    enc_config.sse_algorithm != "aws:kms"
    
    msg := h.format_violation(plan, resource, "S3 bucket with sensitive data must use KMS encryption")
}