package terraform.security.tags

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.lib.helpers as h

# Define resources that must have tags
tagged_resource_types := [
    "aws_s3_bucket",
    "aws_dynamodb_table",
    "aws_lambda_function",
    "aws_kms_key",
    "aws_vpc",
    "aws_security_group",
    "aws_api_gateway_rest_api",
    "aws_sns_topic",
    "aws_cloudwatch_dashboard"
]

# Policy 33: All resources must have required tags
deny contains msg if {
    plan := input
    resource_type := tagged_resource_types[_]
    resource := h.resources_by_type(plan, resource_type)[_]
    
    # Required tags for all resources
    required_tags := ["Environment", "Project", "ManagedBy"]
    not h.has_required_tags(resource, required_tags)
    
    msg := h.format_violation(plan, resource, sprintf("Resource missing required tags: %v", [required_tags]))
}

# Policy 34: Production resources must have additional tags
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource_type := tagged_resource_types[_]
    resource := h.resources_by_type(plan, resource_type)[_]
    
    # Additional required tags for production
    prod_tags := ["Owner", "CostCenter", "BackupSchedule"]
    not h.has_required_tags(resource, prod_tags)
    
    msg := h.format_violation(plan, resource, sprintf("Production resource missing required tags: %v", [prod_tags]))
}

# Policy 35: Tag values must follow naming conventions
deny contains msg if {
    plan := input
    resource_type := tagged_resource_types[_]
    resource := h.resources_by_type(plan, resource_type)[_]
    
    # Check Environment tag values
    env_tag := resource.values.tags.Environment
    valid_envs := ["dev", "staging", "prod", "test"]
    not env_tag in valid_envs
    
    msg := h.format_violation(plan, resource, sprintf("Invalid Environment tag value '%s'. Must be one of: %v", [env_tag, valid_envs]))
}