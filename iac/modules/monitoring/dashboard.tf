# CloudWatch Dashboard

resource "aws_cloudwatch_dashboard" "main" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = concat(
      # Lambda Function Widgets
      var.lambda_function_names != [] ? [
        {
          type   = "metric"
          x      = 0
          y      = 0
          width  = 12
          height = 6
          properties = {
            metrics = flatten([
              for func_name in var.lambda_function_names : [
                ["AWS/Lambda", "Invocations", "FunctionName", func_name],
                ["AWS/Lambda", "Errors", "FunctionName", func_name],
                ["AWS/Lambda", "Duration", "FunctionName", func_name]
              ]
            ])
            period  = 300
            stat    = "Sum"
            region  = var.region
            title   = "Lambda Functions - Invocations, Errors, Duration"
            view    = "timeSeries"
            stacked = false
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 0
          width  = 12
          height = 6
          properties = {
            metrics = flatten([
              for func_name in var.lambda_function_names : [
                ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", func_name],
                ["AWS/Lambda", "Throttles", "FunctionName", func_name]
              ]
            ])
            period  = 300
            stat    = "Average"
            region  = var.region
            title   = "Lambda Functions - Concurrency & Throttles"
            view    = "timeSeries"
            stacked = false
          }
        }
      ] : [],

      # API Gateway Widgets
      var.api_gateway_id != null ? [
        {
          type   = "metric"
          x      = 0
          y      = 6
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_id, "Stage", var.api_gateway_stage_name],
              ["AWS/ApiGateway", "4XXError", "ApiName", var.api_gateway_id, "Stage", var.api_gateway_stage_name],
              ["AWS/ApiGateway", "5XXError", "ApiName", var.api_gateway_id, "Stage", var.api_gateway_stage_name]
            ]
            period  = 300
            stat    = "Sum"
            region  = var.region
            title   = "API Gateway - Requests & Errors"
            view    = "timeSeries"
            stacked = false
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 6
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApiGateway", "Latency", "ApiName", var.api_gateway_id, "Stage", var.api_gateway_stage_name],
              ["AWS/ApiGateway", "IntegrationLatency", "ApiName", var.api_gateway_id, "Stage", var.api_gateway_stage_name]
            ]
            period  = 300
            stat    = "Average"
            region  = var.region
            title   = "API Gateway - Latency"
            view    = "timeSeries"
            stacked = false
          }
        }
      ] : [],

      # DynamoDB Widgets
      var.dynamodb_table_names != [] ? [
        {
          type   = "metric"
          x      = 0
          y      = 12
          width  = 12
          height = 6
          properties = {
            metrics = flatten([
              for table_name in var.dynamodb_table_names : [
                ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", table_name],
                ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", table_name]
              ]
            ])
            period  = 300
            stat    = "Sum"
            region  = var.region
            title   = "DynamoDB - Consumed Capacity"
            view    = "timeSeries"
            stacked = false
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 12
          width  = 12
          height = 6
          properties = {
            metrics = flatten([
              for table_name in var.dynamodb_table_names : [
                ["AWS/DynamoDB", "ReadThrottledEvents", "TableName", table_name],
                ["AWS/DynamoDB", "WriteThrottledEvents", "TableName", table_name]
              ]
            ])
            period  = 300
            stat    = "Sum"
            region  = var.region
            title   = "DynamoDB - Throttled Events"
            view    = "timeSeries"
            stacked = false
          }
        }
      ] : [],

      # System Health Widget
      [
        {
          type   = "metric"
          x      = 0
          y      = 18
          width  = 24
          height = 6
          properties = {
            metrics = concat(
              [for func_name in var.lambda_function_names :
                ["AWS/Lambda", "Errors", "FunctionName", func_name]
              ],
              var.api_gateway_id != null ? [
                ["AWS/ApiGateway", "5XXError", "ApiName", var.api_gateway_id, "Stage", var.api_gateway_stage_name]
              ] : [],
              [for table_name in var.dynamodb_table_names :
                ["AWS/DynamoDB", "SystemErrors", "TableName", table_name]
              ]
            )
            period  = 300
            stat    = "Sum"
            region  = var.region
            title   = "System Health - All Error Metrics"
            view    = "timeSeries"
            stacked = false
            annotations = {
              horizontal = [
                {
                  label = "Error Threshold"
                  value = 0
                }
              ]
            }
          }
        }
      ]
    )
  })
}