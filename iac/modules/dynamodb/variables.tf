# DynamoDB Module Variables

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

variable "is_primary_region" {
  description = "Whether this is the primary region for Global Tables"
  type        = bool
  default     = true
}

variable "replica_regions" {
  description = "List of replica regions for Global Tables"
  type        = list(string)
  default     = []
}

variable "tables" {
  description = "Map of DynamoDB tables to create"
  type = map(object({
    hash_key               = string
    range_key              = optional(string)
    billing_mode           = optional(string, "PAY_PER_REQUEST")
    read_capacity          = optional(number, 5)
    write_capacity         = optional(number, 5)
    stream_enabled         = optional(bool, true)
    stream_view_type       = optional(string, "NEW_AND_OLD_IMAGES")
    point_in_time_recovery = optional(bool, true)

    attributes = list(object({
      name = string
      type = string
    }))

    global_secondary_indexes = optional(list(object({
      name            = string
      hash_key        = string
      range_key       = optional(string)
      projection_type = optional(string, "ALL")
      read_capacity   = optional(number, 5)
      write_capacity  = optional(number, 5)
    })), [])

    local_secondary_indexes = optional(list(object({
      name            = string
      range_key       = string
      projection_type = optional(string, "ALL")
    })), [])
  }))

  default = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for tables"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}