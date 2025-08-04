# Development Environment - US West 2 Outputs

# Application Endpoints
output "alb_url" {
  description = "ALB endpoint URL"
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

# Development-specific Information
# API keys removed - no longer using API Gateway

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
output "dev_usw2_config" {
  description = "Development US West 2 configuration summary"
  value       = module.regional.regional_configuration
}

# Quick Reference for Development
output "dev_quick_reference" {
  description = "Quick reference information for developers"
  value = {
    # Primary endpoints
    api_base_url = module.regional.application_endpoints.root_domain_url != null ? module.regional.application_endpoints.root_domain_url : "https://${module.regional.alb_dns_name}"
    health_check = module.regional.application_endpoints.health_endpoint

    # Monitoring
    dashboard = module.regional.dashboard_url

    # Database tables
    tables = {
      watchlist    = module.regional.address_watchlist_table_name
      transactions = module.regional.suspicious_transactions_table_name
      notes        = module.regional.investigation_notes_table_name
    }

    # ECS services
    services = {
      api_service = module.regional.ecs_service_name
      alb_dns     = module.regional.alb_dns_name
    }

    # Development settings
    settings = {
      log_level           = "DEBUG"
      cache_enabled       = false
      cache_ttl           = "1 minute"
      api_throttle        = "50 req/sec burst, 25 req/sec sustained"
      log_retention       = "7 days"
      deletion_protection = false
    }
  }
}