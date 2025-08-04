# Development Environment - US East 2 Outputs (Secondary Region)

# Application Endpoints
output "alb_url" {
  description = "ALB endpoint URL"
  value       = "http://${module.regional.alb_dns_name}"
}

# Legacy compatibility output (for workflows expecting api_gateway_url)
output "api_gateway_url" {
  description = "API Gateway invoke URL (ALB DNS name for compatibility)"
  value       = "http://${module.regional.alb_dns_name}"
}

output "custom_domain_url" {
  description = "Custom domain URL"
  value       = module.regional.application_endpoints.root_domain_url
}

output "health_endpoint" {
  description = "Health check endpoint"
  value       = module.regional.application_endpoints.health_endpoint
}

output "address_balance_endpoint" {
  description = "Address balance endpoint template"
  value       = module.regional.application_endpoints.address_balance_endpoint
}

output "watchlist_endpoint" {
  description = "Watchlist endpoint"
  value       = module.regional.application_endpoints.watchlist_endpoint
}

output "suspicious_transactions_endpoint" {
  description = "Suspicious transactions endpoint"
  value       = module.regional.application_endpoints.watchlist_endpoint
}

output "investigation_notes_endpoint" {
  description = "Investigation notes endpoint"
  value       = module.regional.application_endpoints.watchlist_endpoint
}

# Infrastructure Information
output "vpc_id" {
  description = "VPC ID"
  value       = module.regional.vpc_id
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.regional.ecs_service_name
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.regional.alb_dns_name
}

output "dynamodb_table_names" {
  description = "DynamoDB table names"
  value       = module.regional.dynamodb_table_names
}

# Development-specific Information (for compatibility with existing workflows)
output "lambda_function_names" {
  description = "ECS service names (replacing Lambda function names)"
  value       = [module.regional.ecs_service_name]
}

output "main_function_name" {
  description = "Main ECS service name (replacing Lambda function name)"
  value       = module.regional.ecs_service_name
}

output "api_keys" {
  description = "API keys (not applicable for ECS)"
  value       = {}
  sensitive   = true
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.regional.dashboard_url
}

# Deployment Information
output "deployment_info" {
  description = "Information for CI/CD and development"
  value       = module.regional.deployment_info
}

# Regional Configuration Summary
output "dev_use2_config" {
  description = "Development US East 2 configuration summary"
  value       = module.regional.regional_configuration
}

# Development Operations Reference - Secondary Region
output "dev_secondary_operations_reference" {
  description = "Development secondary region operations reference"
  value = {
    # Secondary endpoints
    api_base_url  = module.regional.application_endpoints.root_domain_url != null ? module.regional.application_endpoints.root_domain_url : "https://${module.regional.alb_dns_name}"
    custom_domain = module.regional.application_endpoints.root_domain_url
    health_check  = module.regional.application_endpoints.health_endpoint

    # API key information
    api_key_hint = "Not applicable for ECS deployment"

    # Monitoring
    dashboard = module.regional.dashboard_url

    # Database tables (Global Tables replicas)
    tables = {
      watchlist               = module.regional.address_watchlist_table_name
      suspicious_transactions = module.regional.suspicious_transactions_table_name
      investigation_notes     = module.regional.investigation_notes_table_name
    }

    # ECS services (replacing Lambda functions)
    functions = [module.regional.ecs_service_name]

    # Networking
    vpc_id = module.regional.vpc_id

    # Environment info
    environment          = "development"
    region               = "us-east-2"
    role                 = "secondary"
    multi_region_testing = "enabled"
  }
}
