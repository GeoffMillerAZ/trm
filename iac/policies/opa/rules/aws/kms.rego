package terraform.security.aws.kms

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.lib.helpers as h

# Policy 16: KMS keys must have rotation enabled
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_kms_key")[_]
    
    # Check if key rotation is enabled
    not resource.values.enable_key_rotation == true
    
    msg := h.format_violation(plan, resource, "KMS key must have automatic rotation enabled")
}

# Policy 17: KMS keys must have appropriate deletion window
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_kms_key")[_]
    
    # Check deletion window for production (minimum 30 days)
    resource.values.deletion_window_in_days < 30
    
    msg := h.format_violation(plan, resource, "KMS key deletion window must be at least 30 days in production")
}

warn contains msg if {
    plan := input
    h.is_development(plan)
    resource := h.resources_by_type(plan, "aws_kms_key")[_]
    
    # Warning if deletion window is too short in dev
    resource.values.deletion_window_in_days < 7
    
    msg := h.format_violation(plan, resource, "KMS key deletion window is very short, consider increasing")
}

# Policy 18: KMS keys must have proper alias naming
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_kms_alias")[_]
    
    # Check alias naming convention
    alias_name := resource.values.name
    not startswith(alias_name, "alias/")
    
    msg := h.format_violation(plan, resource, "KMS alias must start with 'alias/'")
}

# Policy 19: Multi-region KMS keys configuration
warn contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_kms_key")[_]
    
    # Check if multi-region is enabled for production
    not resource.values.multi_region == true
    
    msg := h.format_violation(plan, resource, "Consider enabling multi-region for KMS keys in production for disaster recovery")
}