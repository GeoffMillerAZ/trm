# Production Environment - Global Outputs

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.global.hosted_zone_id
}

output "hosted_zone_name_servers" {
  description = "Route 53 hosted zone name servers"
  value       = module.global.hosted_zone_name_servers
}

output "domain_name" {
  description = "Domain name"
  value       = module.global.domain_name
}

output "kms_secrets_key_arn" {
  description = "KMS key ARN for secrets encryption"
  value       = module.global.kms_secrets_key_arn
}

output "kms_data_key_arn" {
  description = "KMS key ARN for data encryption"
  value       = module.global.kms_data_key_arn
}

output "kms_logs_key_arn" {
  description = "KMS key ARN for logs encryption"
  value       = module.global.kms_logs_key_arn
}

output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = module.global.lambda_execution_role_arn
}

output "global_alarms_topic_arn" {
  description = "SNS topic ARN for global alarms"
  value       = module.global.global_alarms_topic_arn
  sensitive   = true
}

# Regional deployment parameters
output "regional_deployment_params" {
  description = "Parameters for regional deployments"
  value       = module.global.regional_deployment_params
}

# Multi-region health checks
# TODO: Re-enable when health checks are fixed in the global module
# output "primary_health_check_id" {
#   description = "Primary region health check ID"
#   value       = module.global.primary_health_check_id
# }

# output "secondary_health_check_id" {
#   description = "Secondary region health check ID"
#   value       = module.global.secondary_health_check_id
# }

# Configuration summary for regional deployments
output "prod_global_config" {
  description = "Production global configuration summary"
  value       = module.global.global_configuration
  sensitive   = true
}

# DynamoDB table configurations
output "dynamodb_table_configs" {
  description = "DynamoDB table configurations for regional deployments"
  value       = module.global.dynamodb_table_configs
}