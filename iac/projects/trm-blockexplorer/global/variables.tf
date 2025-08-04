# Global Project Variables for TRM Block Explorer

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "trm-blockexplorer"
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-west-2"
}

variable "secondary_region" {
  description = "Secondary AWS region for multi-region deployment"
  type        = string
  default     = "us-east-2"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  validation {
    condition     = can(regex("^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the domain"
  type        = string
  default     = null
}

variable "create_hosted_zone" {
  description = "Whether to create a new hosted zone"
  type        = bool
  default     = false
}

variable "enable_multi_region" {
  description = "Enable multi-region deployment"
  type        = bool
  default     = false
}

variable "health_check_regions" {
  description = "Regions for Route 53 health checks"
  type        = list(string)
  default     = ["us-east-1", "us-west-1", "eu-west-1"]
}

# DynamoDB Global Tables Configuration
variable "dynamodb_tables" {
  description = "Configuration for DynamoDB Global Tables"
  type = map(object({
    hash_key               = string
    range_key              = optional(string)
    billing_mode           = optional(string, "PAY_PER_REQUEST")
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
    })), [])
  }))

  default = {
    AddressWatchlist = {
      hash_key  = "address"
      range_key = "metadata_key"
      attributes = [
        { name = "address", type = "S" },
        { name = "metadata_key", type = "S" },
        { name = "risk_level", type = "S" },
        { name = "created_at", type = "S" },
        { name = "added_by", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name      = "risk_level-created_at-index"
          hash_key  = "risk_level"
          range_key = "created_at"
        },
        {
          name      = "added_by-created_at-index"
          hash_key  = "added_by"
          range_key = "created_at"
        }
      ]
    }

    SuspiciousTransactions = {
      hash_key  = "address"
      range_key = "transaction_id"
      attributes = [
        { name = "address", type = "S" },
        { name = "transaction_id", type = "S" },
        { name = "flagged_by", type = "S" },
        { name = "created_at", type = "S" },
        { name = "transaction_type", type = "S" },
        { name = "amount_eth", type = "N" }
      ]
      global_secondary_indexes = [
        {
          name      = "flagged_by-created_at-index"
          hash_key  = "flagged_by"
          range_key = "created_at"
        },
        {
          name      = "transaction_type-amount_eth-index"
          hash_key  = "transaction_type"
          range_key = "amount_eth"
        }
      ]
    }

    InvestigationNotes = {
      hash_key  = "address"
      range_key = "note_id"
      attributes = [
        { name = "address", type = "S" },
        { name = "note_id", type = "S" },
        { name = "analyst_id", type = "S" },
        { name = "created_at", type = "S" },
        { name = "priority", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name      = "analyst_id-created_at-index"
          hash_key  = "analyst_id"
          range_key = "created_at"
        },
        {
          name      = "priority-created_at-index"
          hash_key  = "priority"
          range_key = "created_at"
        }
      ]
    }
  }
}

# IAM Configuration
variable "create_execution_role" {
  description = "Whether to create Lambda execution role in global resources"
  type        = bool
  default     = true
}

variable "lambda_policies" {
  description = "Additional IAM policies to attach to Lambda execution role"
  type        = list(string)
  default     = []
}

# KMS Configuration
variable "enable_multi_region_kms" {
  description = "Enable multi-region KMS keys"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

# Monitoring Configuration
variable "alarm_email_endpoints" {
  description = "Email addresses for alarm notifications"
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "enable_cross_region_log_replication" {
  description = "Enable cross-region log replication"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}