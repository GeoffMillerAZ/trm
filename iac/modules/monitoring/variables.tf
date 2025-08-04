# Monitoring Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "lambda_function_names" {
  description = "List of Lambda function names to monitor"
  type        = list(string)
  default     = []
}

variable "api_gateway_id" {
  description = "API Gateway ID to monitor"
  type        = string
  default     = null
}

variable "api_gateway_stage_name" {
  description = "API Gateway stage name to monitor"
  type        = string
  default     = null
}

variable "enable_api_gateway_monitoring" {
  description = "Whether to enable API Gateway monitoring"
  type        = bool
  default     = true
}

variable "dynamodb_table_names" {
  description = "List of DynamoDB table names to monitor"
  type        = list(string)
  default     = []
}

variable "sns_topic_arns" {
  description = "List of SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

variable "alarm_email_endpoints" {
  description = "List of email addresses for alarm notifications"
  type        = list(string)
  default     = []
}

variable "create_dashboard" {
  description = "Whether to create CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
  default     = null
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring metrics"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention days"
  type        = number
  default     = 30
}

variable "custom_metrics" {
  description = "Map of custom metrics to create alarms for"
  type = map(object({
    metric_name         = string
    namespace           = string
    statistic           = string
    comparison_operator = string
    threshold           = number
    evaluation_periods  = number
    period              = number
    alarm_description   = string
    dimensions          = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}