package terraform.security.aws.apigateway

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.lib.helpers as h

# Policy 20: API Gateway must have authentication enabled
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_api_gateway_method")[_]
    
    # Check if authorization is set
    resource.values.authorization == "NONE"
    not resource.values.api_key_required == true
    
    msg := h.format_violation(plan, resource, "API Gateway method must have authentication enabled (authorization or API key)")
}

# Policy 21: API Gateway must have request validation enabled
warn contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_api_gateway_request_validator")[_]
    
    # Check if both body and parameters validation are disabled
    not resource.values.validate_request_body == true
    not resource.values.validate_request_parameters == true
    
    msg := h.format_violation(plan, resource, "API Gateway should have request validation enabled")
}

# Policy 22: API Gateway must have throttling configured
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_api_gateway_usage_plan")[_]
    
    # Check throttle settings
    not resource.values.throttle_settings
    
    msg := h.format_violation(plan, resource, "API Gateway usage plan must have throttling configured in production")
}

# Policy 23: API Gateway must use custom domain with valid certificate
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_api_gateway_domain_name")[_]
    
    # Check if using edge certificate (should use regional for better control)
    resource.values.certificate_arn == null
    resource.values.regional_certificate_arn == null
    
    msg := h.format_violation(plan, resource, "API Gateway custom domain must have a valid SSL certificate in production")
}

# Policy 24: API Gateway stages must have access logging enabled
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_api_gateway_stage")[_]
    
    # Check access log settings
    not resource.values.access_log_settings
    
    msg := h.format_violation(plan, resource, "API Gateway stage must have access logging enabled in production")
}

# Warning for dev
warn contains msg if {
    plan := input
    h.is_development(plan)
    resource := h.resources_by_type(plan, "aws_api_gateway_stage")[_]
    
    not resource.values.access_log_settings
    
    msg := h.format_violation(plan, resource, "API Gateway stage should have access logging enabled")
}