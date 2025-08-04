package terraform.security.aws.dynamodb

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.lib.helpers as h

# Policy 11: DynamoDB tables must have encryption at rest
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_dynamodb_table")[_]
    
    # Check if server-side encryption is enabled
    not resource.values.server_side_encryption[0].enabled == true
    
    msg := h.format_violation(plan, resource, "DynamoDB table must have encryption at rest enabled")
}

# Policy 12: DynamoDB tables must have point-in-time recovery in production
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_dynamodb_table")[_]
    
    # Check for point-in-time recovery
    not resource.values.point_in_time_recovery[0].enabled == true
    
    msg := h.format_violation(plan, resource, "DynamoDB table must have point-in-time recovery enabled in production")
}

# Warning for dev
warn contains msg if {
    plan := input
    h.is_development(plan)
    resource := h.resources_by_type(plan, "aws_dynamodb_table")[_]
    
    not resource.values.point_in_time_recovery[0].enabled == true
    
    msg := h.format_violation(plan, resource, "DynamoDB table should have point-in-time recovery enabled")
}

# Policy 13: DynamoDB tables must use on-demand billing in dev, provisioned in prod
warn contains msg if {
    plan := input
    h.is_development(plan)
    resource := h.resources_by_type(plan, "aws_dynamodb_table")[_]
    
    # Check if using provisioned capacity in dev
    resource.values.billing_mode == "PROVISIONED"
    
    msg := h.format_violation(plan, resource, "Consider using PAY_PER_REQUEST billing mode in development to save costs")
}

# Policy 14: DynamoDB Global Tables must have multi-region replicas in production
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_dynamodb_table")[_]
    
    # Check if it's a global table
    resource.values.stream_enabled == true
    resource.values.stream_view_type == "NEW_AND_OLD_IMAGES"
    
    # Check replica count
    replicas := resource.values.replica
    count(replicas) < 1
    
    msg := h.format_violation(plan, resource, "DynamoDB Global Table must have at least one replica in production")
}

# Policy 15: DynamoDB tables must have appropriate tags
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_dynamodb_table")[_]
    
    required_tags := ["Environment", "Project", "ManagedBy"]
    not h.has_required_tags(resource, required_tags)
    
    msg := h.format_violation(plan, resource, sprintf("DynamoDB table missing required tags: %v", [required_tags]))
}