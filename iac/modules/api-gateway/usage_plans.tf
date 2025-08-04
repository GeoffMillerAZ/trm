# API Gateway Usage Plans and API Keys

# Usage Plans
resource "aws_api_gateway_usage_plan" "plans" {
  for_each = var.usage_plans

  name        = "${var.project_name}-${each.key}-plan-${var.environment}"
  description = each.value.description

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  # Quota configuration
  dynamic "quota_settings" {
    for_each = each.value.quota != null ? [each.value.quota] : []
    content {
      limit  = quota_settings.value.limit
      period = quota_settings.value.period
    }
  }

  # Throttle configuration
  dynamic "throttle_settings" {
    for_each = each.value.throttle != null ? [each.value.throttle] : []
    content {
      burst_limit = throttle_settings.value.burst_limit
      rate_limit  = throttle_settings.value.rate_limit
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-plan-${var.environment}"
  })
}

# API Keys
resource "aws_api_gateway_api_key" "keys" {
  for_each = var.api_keys

  name        = "${var.project_name}-${each.key}-key-${var.environment}"
  description = each.value.description

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-key-${var.environment}"
  })
}

# Usage Plan Key associations
resource "aws_api_gateway_usage_plan_key" "plan_keys" {
  for_each = var.api_keys

  key_id        = aws_api_gateway_api_key.keys[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.plans[each.value.usage_plan].id
}