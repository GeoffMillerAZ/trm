# Production Environment - Global Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "trm-blockexplorer"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
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

# Domain Configuration
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID (if exists)"
  type        = string
  default     = null
}

variable "create_hosted_zone" {
  description = "Whether to create a new hosted zone"
  type        = bool
  default     = false
}

# Multi-region Configuration
variable "enable_multi_region" {
  description = "Enable multi-region deployment"
  type        = bool
  default     = true
}

variable "health_check_regions" {
  description = "Regions for Route 53 health checks"
  type        = list(string)
  default     = ["us-west-2", "us-east-1", "eu-west-1"]
}

# Monitoring Configuration
variable "alarm_email_endpoints" {
  description = "Email addresses for alarm notifications"
  type        = list(string)
  sensitive   = true
}

# Tags
variable "additional_tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Owner              = "Platform Team"
    CostCenter         = "Production"
    Purpose            = "BlockExplorer"
    Automation         = "terraform"
    Environment        = "prod"
    CriticalSystem     = "true"
    BackupSchedule     = "daily"
    ComplianceScope    = "SOC2"
    DataClassification = "internal"
  }
}