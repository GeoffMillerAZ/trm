# Lambda Module Variables

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

variable "lambda_functions" {
  description = "Map of Lambda functions to create"
  type = map(object({
    filename             = optional(string)
    s3_bucket            = optional(string)
    s3_key               = optional(string)
    handler              = string
    runtime              = optional(string, "python3.12")
    memory_size          = optional(number, 1024)
    timeout              = optional(number, 29)
    reserved_concurrency = optional(number)

    environment_variables = optional(map(string), {})

    # VPC Configuration
    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))

    # Dead Letter Queue
    dead_letter_config = optional(object({
      target_arn = string
    }))

    # Layers
    layers = optional(list(string), [])

    # Tracing
    tracing_mode = optional(string, "Active")

    # Log retention
    log_retention_days = optional(number, 30)
  }))

  default = {}
}

variable "execution_role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for environment variable encryption"
  type        = string
  default     = null
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for Lambda functions"
  type        = bool
  default     = true
}

variable "default_environment_variables" {
  description = "Default environment variables for all Lambda functions"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}