package terraform.security.iam

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.lib.helpers as h

# Policy 25: IAM policies must not use wildcard actions in production
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_iam_policy")[_]
    
    # Parse policy document
    policy := json.unmarshal(resource.values.policy)
    statement := policy.Statement[_]
    action := statement.Action[_]
    contains(action, "*")
    
    msg := h.format_violation(plan, resource, "IAM policy must not use wildcard actions in production")
}

# Policy 26: IAM roles must have proper trust relationships
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_iam_role")[_]
    
    # Parse assume role policy
    policy := json.unmarshal(resource.values.assume_role_policy)
    statement := policy.Statement[_]
    principal := statement.Principal
    
    # Check for overly permissive principals
    principal.AWS == "*"
    
    msg := h.format_violation(plan, resource, "IAM role must not have wildcard principal in trust policy")
}

# Policy 27: IAM users must not have inline policies in production
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_iam_user_policy")[_]
    
    msg := h.format_violation(plan, resource, "IAM users must not have inline policies in production, use managed policies instead")
}

# Policy 28: IAM access keys must be rotated (check age in metadata)
warn contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_iam_access_key")[_]
    
    # This is a warning since we can't check age in plan
    msg := h.format_violation(plan, resource, "Ensure IAM access keys are rotated every 90 days")
}