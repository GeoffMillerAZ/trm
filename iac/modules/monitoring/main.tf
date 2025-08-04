# CloudWatch Monitoring and Alerting

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
  dashboard_name = var.dashboard_name != null ? var.dashboard_name : "${var.project_name}-dashboard-${var.environment}-${var.region}"

  # Determine which SNS topics to use for alarms
  # Prefer global SNS topics if provided, otherwise create/use local ones
  alarm_topics = length(var.sns_topic_arns) > 0 ? var.sns_topic_arns : (
    length(var.alarm_email_endpoints) > 0 ? [aws_sns_topic.alarms[0].arn] : []
  )

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Region      = var.region
    Module      = "monitoring"
  })
}

# SNS Topic for Alarms (only create if no global topics provided and email endpoints specified)
resource "aws_sns_topic" "alarms" {
  count = length(var.sns_topic_arns) == 0 && length(var.alarm_email_endpoints) > 0 ? 1 : 0

  name = "${var.project_name}-alarms-${var.environment}-${var.region}"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email_alarms" {
  count = length(var.alarm_email_endpoints)

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email_endpoints[count.index]
}

# Lambda Function Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${var.project_name}-lambda-${each.value}-errors-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors Lambda function ${each.value} errors"
  alarm_actions       = local.alarm_topics

  dimensions = {
    FunctionName = each.value
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${var.project_name}-lambda-${each.value}-duration-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "25000" # 25 seconds (adjust based on function timeout)
  alarm_description   = "This metric monitors Lambda function ${each.value} duration"
  alarm_actions       = local.alarm_topics

  dimensions = {
    FunctionName = each.value
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${var.project_name}-lambda-${each.value}-throttles-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors Lambda function ${each.value} throttles"
  alarm_actions       = local.alarm_topics

  dimensions = {
    FunctionName = each.value
  }

  tags = local.common_tags
}

# API Gateway Alarms
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx_errors" {
  count = var.enable_api_gateway_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-api-gateway-4xx-errors-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors API Gateway 4XX errors"
  alarm_actions       = local.alarm_topics

  dimensions = {
    ApiName = var.api_gateway_id
    Stage   = var.api_gateway_stage_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  count = var.enable_api_gateway_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-api-gateway-5xx-errors-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors API Gateway 5XX errors"
  alarm_actions       = local.alarm_topics

  dimensions = {
    ApiName = var.api_gateway_id
    Stage   = var.api_gateway_stage_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  count = var.enable_api_gateway_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-api-gateway-latency-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000" # 5 seconds
  alarm_description   = "This metric monitors API Gateway latency"
  alarm_actions       = local.alarm_topics

  dimensions = {
    ApiName = var.api_gateway_id
    Stage   = var.api_gateway_stage_name
  }

  tags = local.common_tags
}

# DynamoDB Alarms
resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttles" {
  for_each = toset(var.dynamodb_table_names)

  alarm_name          = "${var.project_name}-dynamodb-${each.value}-read-throttles-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB ${each.value} read throttles"
  alarm_actions       = local.alarm_topics

  dimensions = {
    TableName = each.value
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttles" {
  for_each = toset(var.dynamodb_table_names)

  alarm_name          = "${var.project_name}-dynamodb-${each.value}-write-throttles-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB ${each.value} write throttles"
  alarm_actions       = local.alarm_topics

  dimensions = {
    TableName = each.value
  }

  tags = local.common_tags
}

# Custom Metric Alarms
resource "aws_cloudwatch_metric_alarm" "custom_metrics" {
  for_each = var.custom_metrics

  alarm_name          = "${var.project_name}-${each.key}-${var.environment}-${var.region}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  alarm_actions       = local.alarm_topics

  dimensions = each.value.dimensions

  tags = local.common_tags
}