# DynamoDB Module Outputs

output "table_names" {
  description = "Map of table logical names to actual table names"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.name }
}

output "table_arns" {
  description = "Map of table logical names to table ARNs"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.arn }
}

output "table_stream_arns" {
  description = "Map of table logical names to stream ARNs"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.stream_arn if v.stream_enabled }
}

# TEMPORARILY DISABLED: Global table outputs while global tables are disabled
# output "global_table_names" {
#   description = "Map of global table logical names to actual table names"
#   value       = var.is_primary_region && length(var.replica_regions) > 0 ? { for k, v in aws_dynamodb_global_table.global_tables : k => v.name } : {}
# }
# 
# output "global_table_arns" {
#   description = "Map of global table logical names to table ARNs"
#   value       = var.is_primary_region && length(var.replica_regions) > 0 ? { for k, v in aws_dynamodb_global_table.global_tables : k => v.arn } : {}
# }

# Return empty maps for now to maintain output compatibility
output "global_table_names" {
  description = "Map of global table logical names to actual table names"
  value       = {}
}

output "global_table_arns" {
  description = "Map of global table logical names to table ARNs"
  value       = {}
}

# Specific table outputs for common access patterns
output "address_watchlist_table_name" {
  description = "Address watchlist table name"
  value       = contains(keys(var.tables), "AddressWatchlist") ? aws_dynamodb_table.tables["AddressWatchlist"].name : null
}

output "address_watchlist_table_arn" {
  description = "Address watchlist table ARN"
  value       = contains(keys(var.tables), "AddressWatchlist") ? aws_dynamodb_table.tables["AddressWatchlist"].arn : null
}

output "suspicious_transactions_table_name" {
  description = "Suspicious transactions table name"
  value       = contains(keys(var.tables), "SuspiciousTransactions") ? aws_dynamodb_table.tables["SuspiciousTransactions"].name : null
}

output "suspicious_transactions_table_arn" {
  description = "Suspicious transactions table ARN"
  value       = contains(keys(var.tables), "SuspiciousTransactions") ? aws_dynamodb_table.tables["SuspiciousTransactions"].arn : null
}

output "investigation_notes_table_name" {
  description = "Investigation notes table name"
  value       = contains(keys(var.tables), "InvestigationNotes") ? aws_dynamodb_table.tables["InvestigationNotes"].name : null
}

output "investigation_notes_table_arn" {
  description = "Investigation notes table ARN"
  value       = contains(keys(var.tables), "InvestigationNotes") ? aws_dynamodb_table.tables["InvestigationNotes"].arn : null
}

# CloudWatch Alarm ARNs
output "read_throttled_events_alarm_arns" {
  description = "Map of table names to read throttled events alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.read_throttled_events : k => v.arn }
}

output "write_throttled_events_alarm_arns" {
  description = "Map of table names to write throttled events alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.write_throttled_events : k => v.arn }
}

# Configuration summary
output "dynamodb_configuration" {
  description = "Summary of DynamoDB configuration"
  value = {
    tables_created      = keys(aws_dynamodb_table.tables)
    global_tables       = [] # Temporarily disabled
    primary_region      = var.is_primary_region
    replica_regions     = var.replica_regions
    encryption_enabled  = var.kms_key_arn != null
    deletion_protection = var.enable_deletion_protection
  }
}