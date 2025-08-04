# DynamoDB Tables and Global Tables

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
    Module      = "dynamodb"
  })
}

# DynamoDB Tables
resource "aws_dynamodb_table" "tables" {
  for_each = var.tables

  name         = "${each.key}-${var.environment}"
  billing_mode = each.value.billing_mode
  hash_key     = each.value.hash_key
  range_key    = each.value.range_key

  # Only set read/write capacity for PROVISIONED billing mode
  read_capacity  = each.value.billing_mode == "PROVISIONED" ? each.value.read_capacity : null
  write_capacity = each.value.billing_mode == "PROVISIONED" ? each.value.write_capacity : null

  deletion_protection_enabled = var.enable_deletion_protection

  # Attributes
  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = each.value.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type

      # Only set read/write capacity for PROVISIONED billing mode
      read_capacity  = each.value.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity = each.value.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  # Local Secondary Indexes
  dynamic "local_secondary_index" {
    for_each = each.value.local_secondary_indexes
    content {
      name            = local_secondary_index.value.name
      range_key       = local_secondary_index.value.range_key
      projection_type = local_secondary_index.value.projection_type
    }
  }

  # DynamoDB Streams
  stream_enabled   = each.value.stream_enabled
  stream_view_type = each.value.stream_enabled ? each.value.stream_view_type : null

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = each.value.point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = var.kms_key_arn != null && var.kms_key_arn != ""
    kms_key_arn = var.kms_key_arn != "" ? var.kms_key_arn : null
  }

  tags = merge(local.common_tags, {
    Name  = "${each.key}-${var.environment}"
    Table = each.key
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Global Tables (only create in primary region)
# TEMPORARILY DISABLED: DynamoDB Global Tables with CMK not supported
# TODO: Re-enable after switching to AWS-managed keys or upgrading to Global Tables v2
# resource "aws_dynamodb_global_table" "global_tables" {
#   for_each = var.is_primary_region && length(var.replica_regions) > 0 ? var.tables : {}
# 
#   name = aws_dynamodb_table.tables[each.key].name
# 
#   # Primary region replica
#   replica {
#     region_name = var.region
#   }
# 
#   # Replica regions
#   dynamic "replica" {
#     for_each = var.replica_regions
#     content {
#       region_name = replica.value
#     }
#   }
# 
#   depends_on = [aws_dynamodb_table.tables]
# 
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# CloudWatch Alarms for DynamoDB Tables
resource "aws_cloudwatch_metric_alarm" "read_throttled_events" {
  for_each = var.tables

  alarm_name          = "${var.project_name}-${each.key}-read-throttled-events-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB read throttled events"
  alarm_actions       = [] # Add SNS topic ARN if needed

  dimensions = {
    TableName = aws_dynamodb_table.tables[each.key].name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "write_throttled_events" {
  for_each = var.tables

  alarm_name          = "${var.project_name}-${each.key}-write-throttled-events-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB write throttled events"
  alarm_actions       = [] # Add SNS topic ARN if needed

  dimensions = {
    TableName = aws_dynamodb_table.tables[each.key].name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "consumed_read_capacity" {
  for_each = { for k, v in var.tables : k => v if v.billing_mode == "PROVISIONED" }

  alarm_name          = "${var.project_name}-${each.key}-consumed-read-capacity-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConsumedReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = each.value.read_capacity * 240 # 80% of 5-minute capacity
  alarm_description   = "This metric monitors DynamoDB consumed read capacity"
  alarm_actions       = [] # Add SNS topic ARN if needed

  dimensions = {
    TableName = aws_dynamodb_table.tables[each.key].name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "consumed_write_capacity" {
  for_each = { for k, v in var.tables : k => v if v.billing_mode == "PROVISIONED" }

  alarm_name          = "${var.project_name}-${each.key}-consumed-write-capacity-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConsumedWriteCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = each.value.write_capacity * 240 # 80% of 5-minute capacity
  alarm_description   = "This metric monitors DynamoDB consumed write capacity"
  alarm_actions       = [] # Add SNS topic ARN if needed

  dimensions = {
    TableName = aws_dynamodb_table.tables[each.key].name
  }

  tags = local.common_tags
}