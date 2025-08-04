# Monitoring Module Outputs

output "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  value       = length(aws_sns_topic.alarms) > 0 ? aws_sns_topic.alarms[0].arn : null
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = var.create_dashboard ? "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}" : null
}

# Lambda Alarm ARNs
output "lambda_error_alarm_arns" {
  description = "Map of Lambda function names to error alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_errors : k => v.arn }
}

output "lambda_duration_alarm_arns" {
  description = "Map of Lambda function names to duration alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_duration : k => v.arn }
}

output "lambda_throttle_alarm_arns" {
  description = "Map of Lambda function names to throttle alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_throttles : k => v.arn }
}

# API Gateway Alarm ARNs
output "api_gateway_4xx_alarm_arn" {
  description = "API Gateway 4XX error alarm ARN"
  value       = var.api_gateway_id != null ? aws_cloudwatch_metric_alarm.api_gateway_4xx_errors[0].arn : null
}

output "api_gateway_5xx_alarm_arn" {
  description = "API Gateway 5XX error alarm ARN"
  value       = var.api_gateway_id != null ? aws_cloudwatch_metric_alarm.api_gateway_5xx_errors[0].arn : null
}

output "api_gateway_latency_alarm_arn" {
  description = "API Gateway latency alarm ARN"
  value       = var.api_gateway_id != null ? aws_cloudwatch_metric_alarm.api_gateway_latency[0].arn : null
}

# DynamoDB Alarm ARNs
output "dynamodb_read_throttle_alarm_arns" {
  description = "Map of DynamoDB table names to read throttle alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.dynamodb_read_throttles : k => v.arn }
}

output "dynamodb_write_throttle_alarm_arns" {
  description = "Map of DynamoDB table names to write throttle alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.dynamodb_write_throttles : k => v.arn }
}

# Custom Metric Alarm ARNs
output "custom_metric_alarm_arns" {
  description = "Map of custom metric names to alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.custom_metrics : k => v.arn }
}

# All Alarm ARNs (for easy reference)
output "all_alarm_arns" {
  description = "List of all alarm ARNs created by this module"
  value = flatten([
    values(aws_cloudwatch_metric_alarm.lambda_errors)[*].arn,
    values(aws_cloudwatch_metric_alarm.lambda_duration)[*].arn,
    values(aws_cloudwatch_metric_alarm.lambda_throttles)[*].arn,
    var.api_gateway_id != null ? [
      aws_cloudwatch_metric_alarm.api_gateway_4xx_errors[0].arn,
      aws_cloudwatch_metric_alarm.api_gateway_5xx_errors[0].arn,
      aws_cloudwatch_metric_alarm.api_gateway_latency[0].arn
    ] : [],
    values(aws_cloudwatch_metric_alarm.dynamodb_read_throttles)[*].arn,
    values(aws_cloudwatch_metric_alarm.dynamodb_write_throttles)[*].arn,
    values(aws_cloudwatch_metric_alarm.custom_metrics)[*].arn
  ])
}

# Configuration summary
output "monitoring_configuration" {
  description = "Summary of monitoring configuration"
  value = {
    lambda_functions_monitored = length(var.lambda_function_names)
    api_gateway_monitored      = var.api_gateway_id != null
    dynamodb_tables_monitored  = length(var.dynamodb_table_names)
    custom_metrics_monitored   = length(var.custom_metrics)
    dashboard_created          = var.create_dashboard
    sns_topic_created          = length(var.alarm_email_endpoints) > 0
    total_alarms_created = (
      length(var.lambda_function_names) * 3 + # errors, duration, throttles
      (var.api_gateway_id != null ? 3 : 0) +  # 4xx, 5xx, latency
      length(var.dynamodb_table_names) * 2 +  # read throttles, write throttles
      length(var.custom_metrics)
    )
  }
}