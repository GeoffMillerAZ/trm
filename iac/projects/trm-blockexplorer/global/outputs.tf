# Global Project Outputs

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : (var.hosted_zone_id != null ? data.aws_route53_zone.main[0].zone_id : null)
}

output "hosted_zone_name_servers" {
  description = "Route 53 hosted zone name servers"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].name_servers : null
}

output "domain_name" {
  description = "Domain name for the application"
  value       = var.domain_name
}

# Health Check Outputs
# TODO: Re-enable when health checks are fixed and uncommented
# output "primary_health_check_id" {
#   description = "Route 53 health check ID for primary region"
#   value       = var.enable_multi_region ? aws_route53_health_check.primary_region[0].id : null
# }

# output "secondary_health_check_id" {
#   description = "Route 53 health check ID for secondary region"
#   value       = var.enable_multi_region ? aws_route53_health_check.secondary_region[0].id : null
# }

# KMS Key Outputs
output "kms_secrets_key_id" {
  description = "KMS key ID for secrets encryption"
  value       = local.security_global.kms_secrets_key_id
}

output "kms_secrets_key_arn" {
  description = "KMS key ARN for secrets encryption"
  value       = local.security_global.kms_secrets_key_arn
}

output "kms_data_key_id" {
  description = "KMS key ID for data encryption"
  value       = local.security_global.kms_data_key_id
}

output "kms_data_key_arn" {
  description = "KMS key ARN for data encryption"
  value       = local.security_global.kms_data_key_arn
}

output "kms_logs_key_id" {
  description = "KMS key ID for logs encryption"
  value       = local.security_global.kms_logs_key_id
}

output "kms_logs_key_arn" {
  description = "KMS key ARN for logs encryption"
  value       = local.security_global.kms_logs_key_arn
}

# IAM Role Outputs
output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = var.create_execution_role ? aws_iam_role.lambda_execution[0].arn : null
}

output "lambda_execution_role_name" {
  description = "Lambda execution role name"
  value       = var.create_execution_role ? aws_iam_role.lambda_execution[0].name : null
}

# SNS Topic Outputs
output "global_alarms_topic_arn" {
  description = "SNS topic ARN for global alarms"
  value       = length(var.alarm_email_endpoints) > 0 ? aws_sns_topic.global_alarms[0].arn : null
  sensitive   = true
}

# DynamoDB Table Configuration
output "dynamodb_table_configs" {
  description = "DynamoDB table configurations for regional deployment"
  value       = var.dynamodb_tables
}

# Configuration Summary
output "global_configuration" {
  description = "Summary of global configuration"
  value = {
    project_name           = var.project_name
    environment            = var.environment
    primary_region         = var.primary_region
    secondary_region       = var.secondary_region
    domain_name            = var.domain_name
    multi_region_enabled   = var.enable_multi_region
    multi_region_kms       = var.enable_multi_region_kms
    hosted_zone_created    = var.create_hosted_zone
    health_checks_enabled  = var.enable_multi_region
    execution_role_created = var.create_execution_role
    alarm_notifications    = length(var.alarm_email_endpoints) > 0
  }
  sensitive = true
}

# Regional Deployment Parameters
output "regional_deployment_params" {
  description = "Parameters to pass to regional deployments"
  value = {
    project_name              = var.project_name
    environment               = var.environment
    domain_name               = var.domain_name
    hosted_zone_id            = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : (var.hosted_zone_id != null ? data.aws_route53_zone.main[0].zone_id : null)
    kms_secrets_key_arn       = local.security_global.kms_secrets_key_arn
    kms_data_key_arn          = local.security_global.kms_data_key_arn
    kms_logs_key_arn          = local.security_global.kms_logs_key_arn
    lambda_execution_role_arn = var.create_execution_role ? aws_iam_role.lambda_execution[0].arn : null
    dynamodb_tables           = var.dynamodb_tables
    enable_multi_region       = var.enable_multi_region
    replica_regions           = local.replica_regions
  }
}