# Security Module Outputs

# Security Group Outputs
output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  value       = var.create_security_groups && var.vpc_id != "" ? aws_security_group.lambda[0].id : null
}

output "api_gateway_security_group_id" {
  description = "Security group ID for API Gateway"
  value       = var.create_security_groups && var.vpc_id != "" ? aws_security_group.api_gateway[0].id : null
}

output "database_security_group_id" {
  description = "Security group ID for database instances"
  value       = var.create_security_groups && var.vpc_id != "" ? aws_security_group.database[0].id : null
}

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = var.create_security_groups && var.vpc_id != "" ? aws_security_group.alb[0].id : null
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS services"
  value       = var.create_security_groups && var.vpc_id != "" ? aws_security_group.ecs[0].id : null
}

# KMS Key Outputs
output "kms_secrets_key_id" {
  description = "KMS key ID for secrets encryption"
  value       = var.create_kms_keys ? aws_kms_key.secrets[0].key_id : null
}

output "kms_secrets_key_arn" {
  description = "KMS key ARN for secrets encryption"
  value       = var.create_kms_keys ? aws_kms_key.secrets[0].arn : null
}

output "kms_secrets_alias_name" {
  description = "KMS key alias name for secrets encryption"
  value       = var.create_kms_keys ? aws_kms_alias.secrets[0].name : null
}

output "kms_data_key_id" {
  description = "KMS key ID for data encryption"
  value       = var.create_kms_keys ? aws_kms_key.data[0].key_id : null
}

output "kms_data_key_arn" {
  description = "KMS key ARN for data encryption"
  value       = var.create_kms_keys ? aws_kms_key.data[0].arn : null
}

output "kms_data_alias_name" {
  description = "KMS key alias name for data encryption"
  value       = var.create_kms_keys ? aws_kms_alias.data[0].name : null
}

output "kms_logs_key_id" {
  description = "KMS key ID for logs encryption"
  value       = var.create_kms_keys ? aws_kms_key.logs[0].key_id : null
}

output "kms_logs_key_arn" {
  description = "KMS key ARN for logs encryption"
  value       = var.create_kms_keys ? aws_kms_key.logs[0].arn : null
}

output "kms_logs_alias_name" {
  description = "KMS key alias name for logs encryption"
  value       = var.create_kms_keys ? aws_kms_alias.logs[0].name : null
}

# Security Configuration Summary
output "security_summary" {
  description = "Summary of security configuration"
  value = {
    lambda_security_group      = var.create_security_groups && var.vpc_id != "" ? aws_security_group.lambda[0].id : null
    api_gateway_security_group = var.create_security_groups && var.vpc_id != "" ? aws_security_group.api_gateway[0].id : null
    database_security_group    = var.create_security_groups && var.vpc_id != "" ? aws_security_group.database[0].id : null
    alb_security_group         = var.create_security_groups && var.vpc_id != "" ? aws_security_group.alb[0].id : null
    ecs_security_group         = var.create_security_groups && var.vpc_id != "" ? aws_security_group.ecs[0].id : null
    kms_keys_created           = var.create_kms_keys
    multi_region_keys          = var.enable_multi_region_keys
  }
}