# Global Resources for TRM Block Explorer

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "trm-blockexplorer"
    Layer       = "global"
  })

  replica_regions = var.enable_multi_region ? [var.secondary_region] : []
}

# Route 53 Hosted Zone (if creating new)
resource "aws_route53_zone" "main" {
  count = var.create_hosted_zone ? 1 : 0

  name = var.domain_name

  tags = merge(local.common_tags, {
    Name = var.domain_name
  })
}

# Data source for existing hosted zone
data "aws_route53_zone" "main" {
  count = var.hosted_zone_id != null ? 1 : 0

  zone_id = var.hosted_zone_id
}

# Route 53 Health Checks for Regional Endpoints
# TODO: Re-enable health checks after fixing configuration
# Health checks are temporarily disabled to unblock Lambda deployment
# resource "aws_route53_health_check" "primary_region" {
#   count = var.enable_multi_region ? 1 : 0

#   fqdn                            = "${var.primary_region}.api.${var.domain_name}"
#   port                            = 443
#   type                            = "HTTPS"
#   resource_path                   = "/health"
#   failure_threshold               = "3"
#   request_interval                = "30"
#   cloudwatch_alarm_region         = var.primary_region
#   cloudwatch_alarm_name           = "${var.project_name}-health-check-${var.primary_region}-${var.environment}"
#   insufficient_data_health_status = "Unhealthy"

#   regions = var.health_check_regions

#   tags = merge(local.common_tags, {
#     Name   = "${var.project_name}-health-check-${var.primary_region}-${var.environment}"
#     Region = var.primary_region
#   })
# }

# resource "aws_route53_health_check" "secondary_region" {
#   count = var.enable_multi_region ? 1 : 0

#   fqdn                            = "${var.secondary_region}.api.${var.domain_name}"
#   port                            = 443
#   type                            = "HTTPS"
#   resource_path                   = "/health"
#   failure_threshold               = "3"
#   request_interval                = "30"
#   cloudwatch_alarm_region         = var.secondary_region
#   cloudwatch_alarm_name           = "${var.project_name}-health-check-${var.secondary_region}-${var.environment}"
#   insufficient_data_health_status = "Unhealthy"

#   regions = var.health_check_regions

#   tags = merge(local.common_tags, {
#     Name   = "${var.project_name}-health-check-${var.secondary_region}-${var.environment}"
#     Region = var.secondary_region
#   })
# }

# Route 53 DNS Records for API Gateway (Latency-based routing)
resource "aws_route53_record" "api_primary" {
  count = var.enable_multi_region ? 1 : 0

  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.main[0].zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = var.primary_region

  latency_routing_policy {
    region = var.primary_region
  }

  # health_check_id = aws_route53_health_check.primary_region[0].id

  alias {
    name                   = "${var.primary_region}.api.${var.domain_name}"
    zone_id                = aws_route53_zone.main[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_secondary" {
  count = var.enable_multi_region ? 1 : 0

  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.main[0].zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = var.secondary_region

  latency_routing_policy {
    region = var.secondary_region
  }

  # health_check_id = aws_route53_health_check.secondary_region[0].id

  alias {
    name                   = "${var.secondary_region}.api.${var.domain_name}"
    zone_id                = aws_route53_zone.main[0].zone_id
    evaluate_target_health = true
  }
}

# KMS Keys (Multi-region if enabled)
module "security_global" {
  source = "../../../modules/security"

  project_name         = var.project_name
  environment          = var.environment
  region               = var.primary_region
  vpc_id               = ""
  private_subnet_cidrs = []
  vpc_cidr_block       = ""

  create_security_groups   = false
  create_kms_keys          = true
  enable_multi_region_keys = var.enable_multi_region_kms
  primary_region           = var.primary_region

  kms_key_aliases = {
    secrets = "secrets-key"
    data    = "data-key"
    logs    = "logs-key"
  }

  tags = local.common_tags
}

# IAM Role for Lambda Execution (Global)
resource "aws_iam_role" "lambda_execution" {
  count = var.create_execution_role ? 1 : 0

  name = "${var.project_name}-lambda-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for Lambda Execution
resource "aws_iam_role_policy" "lambda_execution" {
  count = var.create_execution_role ? 1 : 0

  name = "${var.project_name}-lambda-execution-policy-${var.environment}"
  role = aws_iam_role.lambda_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # VPC permissions
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface"
        ]
        Resource = "*"
      },
      # CloudWatch Logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:*:${local.account_id}:log-group:/aws/lambda/${var.project_name}-*"
      },
      # DynamoDB
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          for table_name in keys(var.dynamodb_tables) :
          "arn:${local.partition}:dynamodb:*:${local.account_id}:table/${table_name}-${var.environment}"
        ]
      },
      # DynamoDB Global Secondary Indexes
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          for table_name in keys(var.dynamodb_tables) :
          "arn:${local.partition}:dynamodb:*:${local.account_id}:table/${table_name}-${var.environment}/index/*"
        ]
      },
      # SSM Parameter Store
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:${local.partition}:ssm:*:${local.account_id}:parameter/${var.project_name}/*"
      },
      # KMS
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = [
          module.security_global.kms_secrets_key_arn,
          module.security_global.kms_data_key_arn,
          module.security_global.kms_logs_key_arn
        ]
      },
      # X-Ray Tracing
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count = var.create_execution_role ? 1 : 0

  role       = aws_iam_role.lambda_execution[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach additional policies
resource "aws_iam_role_policy_attachment" "lambda_additional_policies" {
  count = var.create_execution_role ? length(var.lambda_policies) : 0

  role       = aws_iam_role.lambda_execution[0].name
  policy_arn = var.lambda_policies[count.index]
}

# SNS Topic for Global Alarms
resource "aws_sns_topic" "global_alarms" {
  count = length(var.alarm_email_endpoints) > 0 ? 1 : 0

  name = "${var.project_name}-global-alarms-${var.environment}"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "global_alarm_emails" {
  count = length(var.alarm_email_endpoints)

  topic_arn = aws_sns_topic.global_alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email_endpoints[count.index]
}