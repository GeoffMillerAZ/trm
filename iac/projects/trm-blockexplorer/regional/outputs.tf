# Regional Project Outputs

# Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# Security Outputs
output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = module.security.lambda_security_group_id
}

# DynamoDB Outputs
output "dynamodb_table_names" {
  description = "DynamoDB table names"
  value       = module.dynamodb.table_names
}

output "dynamodb_table_arns" {
  description = "DynamoDB table ARNs"
  value       = module.dynamodb.table_arns
}

output "address_watchlist_table_name" {
  description = "Address watchlist table name"
  value       = module.dynamodb.address_watchlist_table_name
}

output "suspicious_transactions_table_name" {
  description = "Suspicious transactions table name"
  value       = module.dynamodb.suspicious_transactions_table_name
}

output "investigation_notes_table_name" {
  description = "Investigation notes table name"
  value       = module.dynamodb.investigation_notes_table_name
}

# ECS Outputs
output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs_service.service_name
}

output "ecs_service_arn" {
  description = "ECS service ARN"
  value       = module.ecs_service.service_arn
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = module.ecs_service.task_definition_arn
}

output "ecs_log_group_name" {
  description = "ECS CloudWatch log group name"
  value       = local.ecs_log_group_name
}

# ALB Outputs
output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.alb.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = aws_lb.alb.zone_id
}

# ALB Target Group Output
output "alb_target_group_arn" {
  description = "ALB target group ARN"
  value       = aws_lb_target_group.alb_ecs.arn
}

# ACM Certificate Output
output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.alb.arn
}

# DNS Records
output "dns_records" {
  description = "DNS records created"
  value = {
    root_domain = var.hosted_zone_id != null ? var.domain_name : null
    api_subdomain = var.hosted_zone_id != null ? "api.${var.domain_name}" : null
  }
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs_cluster.cluster_arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task.arn
}

# Monitoring Outputs
output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.monitoring.dashboard_name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.monitoring.sns_topic_arn
}

# Application Endpoints
output "application_endpoints" {
  description = "Application endpoint URLs"
  value = {
    alb_endpoint              = "https://${aws_lb.alb.dns_name}"
    root_domain_url          = var.hosted_zone_id != null ? "https://${var.domain_name}" : null
    api_subdomain_url        = var.hosted_zone_id != null ? "https://api.${var.domain_name}" : null
    health_endpoint          = var.hosted_zone_id != null ? "https://${var.domain_name}/health" : "https://${aws_lb.alb.dns_name}/health"
    address_balance_endpoint = var.hosted_zone_id != null ? "https://${var.domain_name}/address/balance/{address}" : "https://${aws_lb.alb.dns_name}/address/balance/{address}"
    watchlist_endpoint       = var.hosted_zone_id != null ? "https://${var.domain_name}/watchlist/addresses" : "https://${aws_lb.alb.dns_name}/watchlist/addresses"
  }
}

# SSM Parameter Names
output "ssm_parameter_names" {
  description = "SSM parameter names for application configuration"
  value = {
    config_parameters = [for k, v in aws_ssm_parameter.app_config : v.name]
    secret_parameters = [for k, v in aws_ssm_parameter.app_secrets : v.name]
  }
}

# Regional Configuration Summary
output "regional_configuration" {
  description = "Summary of regional configuration"
  value = {
    project_name       = var.project_name
    environment        = var.environment
    region             = local.region
    is_primary_region  = var.is_primary_region
    vpc_cidr           = var.vpc_cidr
    availability_zones = local.availability_zones

    # Resource counts
    ecs_services_deployed   = 1
    dynamodb_tables_created = length(var.dynamodb_tables)
    api_usage_plans_created = length(var.api_usage_plans)
    api_keys_created        = length(var.api_keys)

    # Features enabled
    vpc_endpoints_enabled = true
    xray_tracing_enabled  = true
    api_caching_enabled   = var.api_gateway_config.enable_caching
    monitoring_dashboard  = var.monitoring_config.create_dashboard
    nat_gateway_enabled   = var.enable_nat_gateway
    single_nat_gateway    = var.enable_single_nat_gateway

    # Security
    kms_encryption_enabled = true
    vpc_flow_logs_enabled  = true
    deletion_protection    = var.cost_optimization.enable_deletion_protection

    # Performance settings
    ecs_cpu_size              = var.ecs_service_config.cpu
    ecs_memory_size           = var.ecs_service_config.memory
    ecs_desired_count         = var.ecs_service_config.desired_count
    ecs_autoscaling_enabled   = var.ecs_service_config.enable_autoscaling
  }
}

# Deployment Information
output "deployment_info" {
  description = "Information for deployment and operations"
  value = {
    # ECS deployment
    ecs_service = {
      service_name         = module.ecs_service.service_name
      service_arn         = module.ecs_service.service_arn
      task_definition_arn = module.ecs_service.task_definition_arn
      log_group           = local.ecs_log_group_name
      container_image     = var.container_image_uri
      cpu                 = var.ecs_service_config.cpu
      memory              = var.ecs_service_config.memory
      desired_count       = var.ecs_service_config.desired_count
    }

    # ALB
    alb = {
      dns_name         = aws_lb.alb.dns_name
      arn              = aws_lb.alb.arn
      zone_id          = aws_lb.alb.zone_id
      target_group_arn = aws_lb_target_group.alb_ecs.arn
      dns_record       = var.hosted_zone_id != null ? "${local.region}.api.${var.domain_name}" : null
    }

    # DynamoDB
    dynamodb_tables = module.dynamodb.table_names

    # Monitoring
    dashboard_url = module.monitoring.dashboard_url
    alarm_topic   = module.monitoring.sns_topic_arn
  }
}
