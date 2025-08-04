# API Gateway and Related Resources

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  api_name   = var.api_name != null ? var.api_name : "${var.project_name}-api-${var.environment}-${var.region}"
  stage_name = var.stage_name != null ? var.stage_name : var.environment

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Region      = var.region
    Module      = "api-gateway"
  })
}

# VPC Link for HTTP integrations to ECS services
resource "aws_api_gateway_vpc_link" "main" {
  count = var.integration_type == "http" ? 1 : 0

  name        = "${var.project_name}-${var.environment}-vpc-link"
  description = "VPC Link for API Gateway to ECS services"
  target_arns = [var.alb_arn]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-link"
  })
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = local.api_name
  description = var.api_description

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  api_key_source = var.api_key_source

  tags = merge(local.common_tags, {
    Name = local.api_name
  })
}

# API Gateway Resources and Methods
resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "health"
}

resource "aws_api_gateway_method" "health_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.health.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

# Health endpoint integration - Lambda
resource "aws_api_gateway_integration" "health_lambda" {
  count = var.integration_type == "lambda" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.health_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.health_lambda_invoke_arn != null ? var.health_lambda_invoke_arn : var.lambda_function_invoke_arn
}

# Health endpoint integration - HTTP (ECS)
resource "aws_api_gateway_integration" "health_http" {
  count = var.integration_type == "http" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.health_get.http_method

  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}:${var.alb_listener_port}/health"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.main[0].id
}

# Address resource
resource "aws_api_gateway_resource" "address" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "address"
}

resource "aws_api_gateway_resource" "address_balance" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.address.id
  path_part   = "balance"
}

resource "aws_api_gateway_resource" "address_param" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.address_balance.id
  path_part   = "{address}"
}

resource "aws_api_gateway_method" "address_balance_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.address_param.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = length(var.api_keys) > 0

  request_parameters = {
    "method.request.path.address" = true
  }
}

# Address balance integration - Lambda
resource "aws_api_gateway_integration" "address_balance_lambda" {
  count = var.integration_type == "lambda" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.address_param.id
  http_method = aws_api_gateway_method.address_balance_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_function_invoke_arn

  cache_key_parameters = var.enable_caching ? ["method.request.path.address"] : []
}

# Address balance integration - HTTP (ECS)
resource "aws_api_gateway_integration" "address_balance_http" {
  count = var.integration_type == "http" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.address_param.id
  http_method = aws_api_gateway_method.address_balance_get.http_method

  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}:${var.alb_listener_port}/address/balance/{address}"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.main[0].id

  request_parameters = {
    "integration.request.path.address" = "method.request.path.address"
  }

  cache_key_parameters = var.enable_caching ? ["method.request.path.address"] : []
}

# Watchlist resource
resource "aws_api_gateway_resource" "watchlist" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "watchlist"
}

resource "aws_api_gateway_resource" "watchlist_addresses" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.watchlist.id
  path_part   = "addresses"
}

# Watchlist addresses methods
resource "aws_api_gateway_method" "watchlist_addresses_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.watchlist_addresses.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = length(var.api_keys) > 0
}

resource "aws_api_gateway_method" "watchlist_addresses_post" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.watchlist_addresses.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = length(var.api_keys) > 0
}

# Watchlist addresses integrations - Lambda
resource "aws_api_gateway_integration" "watchlist_addresses_get_lambda" {
  count = var.integration_type == "lambda" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.watchlist_addresses.id
  http_method = aws_api_gateway_method.watchlist_addresses_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_function_invoke_arn
}

resource "aws_api_gateway_integration" "watchlist_addresses_post_lambda" {
  count = var.integration_type == "lambda" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.watchlist_addresses.id
  http_method = aws_api_gateway_method.watchlist_addresses_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_function_invoke_arn
}

# Watchlist addresses integrations - HTTP (ECS)
resource "aws_api_gateway_integration" "watchlist_addresses_get_http" {
  count = var.integration_type == "http" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.watchlist_addresses.id
  http_method = aws_api_gateway_method.watchlist_addresses_get.http_method

  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}:${var.alb_listener_port}/watchlist/addresses"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.main[0].id
}

resource "aws_api_gateway_integration" "watchlist_addresses_post_http" {
  count = var.integration_type == "http" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.watchlist_addresses.id
  http_method = aws_api_gateway_method.watchlist_addresses_post.http_method

  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}:${var.alb_listener_port}/watchlist/addresses"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.main[0].id
}

# CORS support for all resources
locals {
  cors_resources = {
    health              = aws_api_gateway_resource.health.id
    address_param       = aws_api_gateway_resource.address_param.id
    watchlist_addresses = aws_api_gateway_resource.watchlist_addresses.id
  }
}

resource "aws_api_gateway_method" "options" {
  for_each = local.cors_resources

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each = aws_api_gateway_method.options

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  for_each = aws_api_gateway_method.options

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

resource "aws_api_gateway_integration_response" "options" {
  for_each = aws_api_gateway_integration.options

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = aws_api_gateway_method_response.options[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${join(",", var.cors_configuration.allow_headers)}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${join(",", var.cors_configuration.allow_methods)}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${join(",", var.cors_configuration.allow_origins)}'"
    "method.response.header.Access-Control-Max-Age"       = "'${var.cors_configuration.max_age}'"
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.health_lambda,
    aws_api_gateway_integration.health_http,
    aws_api_gateway_integration.address_balance_lambda,
    aws_api_gateway_integration.address_balance_http,
    aws_api_gateway_integration.watchlist_addresses_get_lambda,
    aws_api_gateway_integration.watchlist_addresses_post_lambda,
    aws_api_gateway_integration.watchlist_addresses_get_http,
    aws_api_gateway_integration.watchlist_addresses_post_http,
    aws_api_gateway_integration_response.options
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode(concat(
      [
        aws_api_gateway_resource.health.id,
        aws_api_gateway_method.health_get.id,
        aws_api_gateway_resource.address_param.id,
        aws_api_gateway_method.address_balance_get.id,
        aws_api_gateway_resource.watchlist_addresses.id,
        aws_api_gateway_method.watchlist_addresses_get.id,
        aws_api_gateway_method.watchlist_addresses_post.id,
        var.integration_type,
      ],
      var.integration_type == "lambda" ? [
        try(aws_api_gateway_integration.health_lambda[0].id, ""),
        try(aws_api_gateway_integration.address_balance_lambda[0].id, ""),
        try(aws_api_gateway_integration.watchlist_addresses_get_lambda[0].id, ""),
        try(aws_api_gateway_integration.watchlist_addresses_post_lambda[0].id, ""),
      ] : [
        try(aws_api_gateway_integration.health_http[0].id, ""),
        try(aws_api_gateway_integration.address_balance_http[0].id, ""),
        try(aws_api_gateway_integration.watchlist_addresses_get_http[0].id, ""),
        try(aws_api_gateway_integration.watchlist_addresses_post_http[0].id, ""),
      ]
    )))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = local.stage_name

  # Caching configuration
  cache_cluster_enabled = var.enable_caching
  cache_cluster_size    = var.enable_caching ? var.cache_cluster_size : null

  # X-Ray tracing
  xray_tracing_enabled = var.enable_xray_tracing

  # Access logging
  dynamic "access_log_settings" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      # Use log group ARN format since log group is auto-created
      destination_arn = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${local.api_name}"
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        caller         = "$context.identity.caller"
        user           = "$context.identity.user"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
        responseTime   = "$context.responseTime"
        error          = "$context.error.message"
        errorType      = "$context.error.messageString"
      })
    }
  }

  tags = merge(local.common_tags, {
    Name  = "${local.api_name}-${local.stage_name}"
    Stage = local.stage_name
  })
}

# Lambda permissions for API Gateway (only for Lambda integrations)
resource "aws_lambda_permission" "api_gateway_lambda" {
  count = var.integration_type == "lambda" && var.lambda_function_name != null ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_health_lambda" {
  count = var.integration_type == "lambda" && var.health_lambda_function_name != null ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGatewayHealth"
  action        = "lambda:InvokeFunction"
  function_name = var.health_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# CloudWatch Log Group for API Gateway Access Logs
# TEMPORARILY DISABLED: API Gateway auto-creates log groups
# resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
#   name              = "/aws/apigateway/${local.api_name}"
#   retention_in_days = 30
# 
#   tags = local.common_tags
# }

# CloudWatch Log Group for API Gateway Execution Logs
# TEMPORARILY DISABLED: API Gateway auto-creates log groups
# resource "aws_cloudwatch_log_group" "api_gateway_execution_logs" {
#   name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.main.id}/${local.stage_name}"
#   retention_in_days = 30
# 
#   tags = local.common_tags
# }