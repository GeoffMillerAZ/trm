# API Gateway Module Outputs

output "rest_api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.main.id
}

output "rest_api_root_resource_id" {
  description = "Root resource ID of the REST API"
  value       = aws_api_gateway_rest_api.main.root_resource_id
}

output "rest_api_execution_arn" {
  description = "Execution ARN of the REST API"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "deployment_id" {
  description = "ID of the API Gateway deployment"
  value       = aws_api_gateway_deployment.main.id
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.main.stage_name
}

output "stage_invoke_url" {
  description = "Invoke URL of the API Gateway stage"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "stage_execution_arn" {
  description = "Execution ARN of the API Gateway stage"
  value       = aws_api_gateway_stage.main.execution_arn
}

output "custom_domain_name" {
  description = "Custom domain name for the API"
  value       = var.custom_domain_name != null && var.certificate_arn != null ? aws_api_gateway_domain_name.custom[0].domain_name : null
}

output "custom_domain_target" {
  description = "Target domain name for the custom domain"
  value       = var.custom_domain_name != null && var.certificate_arn != null ? aws_api_gateway_domain_name.custom[0].regional_domain_name : null
}

output "custom_domain_zone_id" {
  description = "Zone ID for the custom domain"
  value       = var.custom_domain_name != null && var.certificate_arn != null ? aws_api_gateway_domain_name.custom[0].regional_zone_id : null
}

output "api_key_ids" {
  description = "Map of API key names to IDs"
  value       = { for k, v in aws_api_gateway_api_key.keys : k => v.id }
}

output "api_key_values" {
  description = "Map of API key names to values"
  value       = { for k, v in aws_api_gateway_api_key.keys : k => v.value }
  sensitive   = true
}

output "usage_plan_ids" {
  description = "Map of usage plan names to IDs"
  value       = { for k, v in aws_api_gateway_usage_plan.plans : k => v.id }
}

output "access_log_group_name" {
  description = "CloudWatch log group name for API Gateway access logs"
  value       = "/aws/apigateway/${local.api_name}"
}

output "access_log_group_arn" {
  description = "CloudWatch log group ARN for API Gateway access logs"
  value       = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${local.api_name}"
}

output "execution_log_group_name" {
  description = "CloudWatch log group name for API Gateway execution logs"
  value       = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.main.id}/${local.stage_name}"
}

output "execution_log_group_arn" {
  description = "CloudWatch log group ARN for API Gateway execution logs"
  value       = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.main.id}/${local.stage_name}"
}

# Resource IDs for additional configuration
output "health_resource_id" {
  description = "Resource ID for health endpoint"
  value       = aws_api_gateway_resource.health.id
}

output "address_balance_resource_id" {
  description = "Resource ID for address balance endpoint"
  value       = aws_api_gateway_resource.address_param.id
}

output "watchlist_addresses_resource_id" {
  description = "Resource ID for watchlist addresses endpoint"
  value       = aws_api_gateway_resource.watchlist_addresses.id
}

# VPC Link outputs (for HTTP integrations)
output "vpc_link_id" {
  description = "ID of the VPC Link (for HTTP integrations)"
  value       = var.integration_type == "http" ? aws_api_gateway_vpc_link.main[0].id : null
}

output "vpc_link_name" {
  description = "Name of the VPC Link (for HTTP integrations)"
  value       = var.integration_type == "http" ? aws_api_gateway_vpc_link.main[0].name : null
}

# Integration type
output "integration_type" {
  description = "Type of integration used (lambda or http)"
  value       = var.integration_type
}

# Configuration summary
output "api_gateway_configuration" {
  description = "Summary of API Gateway configuration"
  value = {
    api_name             = local.api_name
    stage_name           = local.stage_name
    integration_type     = var.integration_type
    caching_enabled      = var.enable_caching
    cache_cluster_size   = var.cache_cluster_size
    cache_ttl_seconds    = var.cache_ttl_seconds
    xray_tracing_enabled = var.enable_xray_tracing
    throttle_burst_limit = var.throttle_burst_limit
    throttle_rate_limit  = var.throttle_rate_limit
    custom_domain        = var.custom_domain_name
    api_keys_count       = length(var.api_keys)
    usage_plans_count    = length(var.usage_plans)
    vpc_link_enabled     = var.integration_type == "http"
  }
}