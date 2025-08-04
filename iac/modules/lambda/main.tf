# Lambda Functions and Configuration

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Region      = var.region
    Module      = "lambda"
  })
}

# Lambda Functions
resource "aws_lambda_function" "functions" {
  for_each = var.lambda_functions

  function_name = "${var.project_name}-${each.key}-${var.environment}-${var.region}"
  role          = var.execution_role_arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  memory_size   = each.value.memory_size
  timeout       = each.value.timeout

  # Reserved concurrency
  reserved_concurrent_executions = each.value.reserved_concurrency

  # Code deployment
  filename  = each.value.filename
  s3_bucket = each.value.s3_bucket
  s3_key    = each.value.s3_key
  # source_code_hash managed by external deployment process
  # source_code_hash = each.value.filename != null ? filebase64sha256(each.value.filename) : null

  # Layers
  layers = each.value.layers

  # Environment variables
  dynamic "environment" {
    for_each = length(merge(var.default_environment_variables, each.value.environment_variables)) > 0 ? [1] : []
    content {
      variables = merge(var.default_environment_variables, each.value.environment_variables)
    }
  }

  # KMS encryption for environment variables
  kms_key_arn = var.kms_key_arn

  # VPC Configuration
  dynamic "vpc_config" {
    for_each = each.value.vpc_config != null ? [each.value.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead Letter Queue
  dynamic "dead_letter_config" {
    for_each = each.value.dead_letter_config != null ? [each.value.dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  # X-Ray Tracing
  tracing_config {
    mode = var.enable_xray_tracing ? each.value.tracing_mode : "PassThrough"
  }

  tags = merge(local.common_tags, {
    Name       = "${var.project_name}-${each.key}-${var.environment}-${var.region}"
    Function   = each.key
    Runtime    = each.value.runtime
    MemorySize = each.value.memory_size
    Timeout    = each.value.timeout
  })

  lifecycle {
    ignore_changes = [
      source_code_hash,
      filename,
      s3_bucket,
      s3_key,
    ]
  }

  # depends_on = [aws_cloudwatch_log_group.lambda_logs] # Removed since log groups are auto-created
}

# CloudWatch Log Groups for Lambda functions
# TEMPORARILY DISABLED: Lambda auto-creates log groups
# resource "aws_cloudwatch_log_group" "lambda_logs" {
#   for_each = var.lambda_functions
#
#   name              = "/aws/lambda/${var.project_name}-${each.key}-${var.environment}-${var.region}"
#   retention_in_days = each.value.log_retention_days
#   # kms_key_id       = var.kms_key_arn  # Disabled for cross-region deployment
#
#   tags = merge(local.common_tags, {
#     Name     = "/aws/lambda/${var.project_name}-${each.key}-${var.environment}-${var.region}"
#     Function = each.key
#   })
# }

# Lambda Function URLs (if needed for direct HTTP access)
resource "aws_lambda_function_url" "function_urls" {
  for_each = { for k, v in var.lambda_functions : k => v if can(v.enable_function_url) && v.enable_function_url }

  function_name      = aws_lambda_function.functions[each.key].function_name
  authorization_type = "NONE" # Change to "AWS_IAM" for authenticated access

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["date", "keep-alive", "content-type", "authorization"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }
}

# CloudWatch Alarms for Lambda Functions
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.lambda_functions

  alarm_name          = "${var.project_name}-${each.key}-errors-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors Lambda function errors"
  alarm_actions       = [] # Add SNS topic ARN if needed

  dimensions = {
    FunctionName = aws_lambda_function.functions[each.key].function_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = var.lambda_functions

  alarm_name          = "${var.project_name}-${each.key}-duration-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = each.value.timeout * 800 # 80% of timeout in milliseconds
  alarm_description   = "This metric monitors Lambda function duration"
  alarm_actions       = [] # Add SNS topic ARN if needed

  dimensions = {
    FunctionName = aws_lambda_function.functions[each.key].function_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each = var.lambda_functions

  alarm_name          = "${var.project_name}-${each.key}-throttles-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors Lambda function throttles"
  alarm_actions       = [] # Add SNS topic ARN if needed

  dimensions = {
    FunctionName = aws_lambda_function.functions[each.key].function_name
  }

  tags = local.common_tags
}
