# Lambda Module Outputs

output "function_names" {
  description = "Map of logical names to Lambda function names"
  value       = { for k, v in aws_lambda_function.functions : k => v.function_name }
}

output "function_arns" {
  description = "Map of logical names to Lambda function ARNs"
  value       = { for k, v in aws_lambda_function.functions : k => v.arn }
}

output "function_invoke_arns" {
  description = "Map of logical names to Lambda function invoke ARNs"
  value       = { for k, v in aws_lambda_function.functions : k => v.invoke_arn }
}

output "function_qualified_arns" {
  description = "Map of logical names to Lambda function qualified ARNs"
  value       = { for k, v in aws_lambda_function.functions : k => v.qualified_arn }
}

output "function_versions" {
  description = "Map of logical names to Lambda function versions"
  value       = { for k, v in aws_lambda_function.functions : k => v.version }
}

output "function_urls" {
  description = "Map of logical names to Lambda function URLs"
  value       = { for k, v in aws_lambda_function_url.function_urls : k => v.function_url }
}

output "log_group_names" {
  description = "Map of logical names to CloudWatch log group names"
  value       = { for k, v in aws_lambda_function.functions : k => "/aws/lambda/${v.function_name}" }
}

output "log_group_arns" {
  description = "Map of logical names to CloudWatch log group ARNs"
  value       = { for k, v in aws_lambda_function.functions : k => v.arn }
}

# Specific function outputs for common access patterns
output "main_function_name" {
  description = "Main application function name"
  value       = contains(keys(var.lambda_functions), "main") ? aws_lambda_function.functions["main"].function_name : null
}

output "main_function_arn" {
  description = "Main application function ARN"
  value       = contains(keys(var.lambda_functions), "main") ? aws_lambda_function.functions["main"].arn : null
}

output "main_function_invoke_arn" {
  description = "Main application function invoke ARN"
  value       = contains(keys(var.lambda_functions), "main") ? aws_lambda_function.functions["main"].invoke_arn : null
}

output "health_function_name" {
  description = "Health check function name"
  value       = contains(keys(var.lambda_functions), "health") ? aws_lambda_function.functions["health"].function_name : null
}

output "health_function_arn" {
  description = "Health check function ARN"
  value       = contains(keys(var.lambda_functions), "health") ? aws_lambda_function.functions["health"].arn : null
}

output "health_function_invoke_arn" {
  description = "Health check function invoke ARN"
  value       = contains(keys(var.lambda_functions), "health") ? aws_lambda_function.functions["health"].invoke_arn : null
}

# CloudWatch Alarm ARNs
output "error_alarm_arns" {
  description = "Map of function names to error alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_errors : k => v.arn }
}

output "duration_alarm_arns" {
  description = "Map of function names to duration alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_duration : k => v.arn }
}

output "throttle_alarm_arns" {
  description = "Map of function names to throttle alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_throttles : k => v.arn }
}

# Configuration summary
output "lambda_configuration" {
  description = "Summary of Lambda configuration"
  value = {
    functions_created = keys(aws_lambda_function.functions)
    xray_tracing      = var.enable_xray_tracing
    kms_encryption    = var.kms_key_arn != null
    vpc_enabled       = length([for k, v in var.lambda_functions : k if v.vpc_config != null]) > 0
  }
}