# Production Environment - US East 2 Outputs (Secondary Region)

# Application Endpoints
output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.regional.api_gateway_invoke_url
}

output "custom_domain_url" {
  description = "Custom domain URL"
  value       = module.regional.api_gateway_custom_domain != null ? "https://${module.regional.api_gateway_custom_domain}" : null
}

output "health_endpoint" {
  description = "Health check endpoint"
  value       = "${module.regional.api_gateway_invoke_url}/health"
}

output "address_balance_endpoint" {
  description = "Address balance endpoint template"
  value       = "${module.regional.api_gateway_invoke_url}/address/balance/{address}"
}

output "watchlist_endpoint" {
  description = "Watchlist endpoint"
  value       = "${module.regional.api_gateway_invoke_url}/watchlist/addresses"
}

output "suspicious_transactions_endpoint" {
  description = "Suspicious transactions endpoint"
  value       = "${module.regional.api_gateway_invoke_url}/transactions/suspicious"
}

output "investigation_notes_endpoint" {
  description = "Investigation notes endpoint"
  value       = "${module.regional.api_gateway_invoke_url}/investigations/notes"
}

# Infrastructure Information
output "vpc_id" {
  description = "VPC ID"
  value       = module.regional.vpc_id
}

output "lambda_function_names" {
  description = "Lambda function names"
  value       = module.regional.lambda_function_names
}

output "dynamodb_table_names" {
  description = "DynamoDB table names"
  value       = module.regional.dynamodb_table_names
}

# Production-specific Information
output "api_keys" {
  description = "API key values for production (secondary region)"
  value       = module.regional.api_key_values
  sensitive   = true
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.regional.dashboard_url
}

# Deployment Information
output "deployment_info" {
  description = "Information for CI/CD and operations"
  value       = module.regional.deployment_info
}

# Regional Configuration Summary
output "prod_use2_config" {
  description = "Production US East 2 configuration summary"
  value       = module.regional.regional_configuration
}

# Production Operations Reference - Secondary Region
output "prod_secondary_operations_reference" {
  description = "Production secondary region operations reference"
  value = {
    # Secondary endpoints
    api_base_url  = module.regional.api_gateway_invoke_url
    custom_domain = module.regional.api_gateway_custom_domain
    health_check  = "${module.regional.api_gateway_invoke_url}/health"

    # API key information
    api_key_hint = "Use 'terraform output -raw api_keys' to get API key values"

    # Monitoring
    dashboard = module.regional.dashboard_url

    # Database tables (Global Tables replicas)
    tables = {
      watchlist               = module.regional.address_watchlist_table_name
      suspicious_transactions = module.regional.suspicious_transactions_table_name
      investigation_notes     = module.regional.investigation_notes_table_name
    }

    # Lambda functions (secondary region)
    functions = module.regional.lambda_function_names

    # Networking
    vpc_id = module.regional.vpc_id

    # Environment info
    environment = "production"
    region      = "us-east-2"
    role        = "secondary"
  }
}
output "main_function_name" {
  description = "Main Lambda function name"
  value       = module.regional.main_function_name
}
