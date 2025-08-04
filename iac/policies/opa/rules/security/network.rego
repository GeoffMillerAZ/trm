package terraform.security.network

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.lib.helpers as h

# Policy 29: Security groups must not have unrestricted ingress
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_security_group")[_]
    
    # Check ingress rules
    rule := resource.values.ingress[_]
    cidr := rule.cidr_blocks[_]
    cidr == "0.0.0.0/0"
    rule.from_port != 443  # Allow HTTPS from anywhere
    
    msg := h.format_violation(plan, resource, sprintf("Security group has unrestricted ingress on port %d", [rule.from_port]))
}

# Policy 30: Security groups must have descriptions
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_security_group")[_]
    
    # Check if description is missing or empty
    not resource.values.description
    
    msg := h.format_violation(plan, resource, "Security group must have a description")
}

# Policy 31: VPCs must have flow logs enabled in production
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_vpc")[_]
    
    # Check for flow logs
    flow_logs := h.resources_by_type(plan, "aws_flow_log")
    vpc_has_logs := [log | log := flow_logs[_]; log.values.vpc_id == resource.values.id]
    count(vpc_has_logs) == 0
    
    msg := h.format_violation(plan, resource, "VPC must have flow logs enabled in production")
}

# Policy 32: Network ACLs must not be overly permissive
warn contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_network_acl_rule")[_]
    
    # Check for allow all rules
    resource.values.rule_action == "allow"
    resource.values.cidr_block == "0.0.0.0/0"
    resource.values.protocol == "-1"  # All protocols
    
    msg := h.format_violation(plan, resource, "Network ACL rule is overly permissive, consider restricting")
}