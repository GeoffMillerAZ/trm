package terraform.security.aws.lambda

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.lib.helpers as h

# Policy 6: Lambda functions must be in VPC for production
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_lambda_function")[_]
    
    # Check if VPC configuration exists
    not resource.values.vpc_config
    
    msg := h.format_violation(plan, resource, "Lambda function must be deployed in VPC in production")
}

# Policy 7: Lambda functions must not have sensitive data in environment variables
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_lambda_function")[_]
    
    # Check environment variables
    env_vars := resource.values.environment[0].variables
    var_name := env_vars[_]
    h.contains_sensitive_data(var_name)
    
    msg := h.format_violation(plan, resource, sprintf("Lambda function has potentially sensitive data in environment variable: %s", [var_name]))
}

# Policy 8: Lambda functions must have appropriate memory and timeout settings
warn contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_lambda_function")[_]
    
    # Check memory size
    resource.values.memory_size > 3008  # Max is 3008 MB
    
    msg := h.format_violation(plan, resource, "Lambda function memory size is very high, consider optimization")
}

warn contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_lambda_function")[_]
    
    # Check timeout
    resource.values.timeout > 300  # 5 minutes
    
    msg := h.format_violation(plan, resource, "Lambda function timeout is very high, consider optimization")
}

# Policy 9: Lambda functions must have X-Ray tracing enabled in production
deny contains msg if {
    plan := input
    h.is_production(plan)
    resource := h.resources_by_type(plan, "aws_lambda_function")[_]
    
    # Check tracing config
    not resource.values.tracing_config[0].mode == "Active"
    
    msg := h.format_violation(plan, resource, "Lambda function must have X-Ray tracing enabled in production")
}

# Policy 10: Lambda functions must use specific runtimes
deny contains msg if {
    plan := input
    resource := h.resources_by_type(plan, "aws_lambda_function")[_]
    
    # Allowed runtimes for security and maintenance
    allowed_runtimes := [
        "python3.11",
        "python3.12",
        "nodejs18.x",
        "nodejs20.x",
        "go1.x",
        "java17",
        "java21"
    ]
    
    runtime := resource.values.runtime
    not runtime in allowed_runtimes
    
    msg := h.format_violation(plan, resource, sprintf("Lambda function uses unsupported runtime '%s'. Allowed: %v", [runtime, allowed_runtimes]))
}