# Development Environment - Global Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "trm-blockexplorer"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-west-2"
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
  default     = "us-east-2"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "dev.trm.geoffmiller.cloud"
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID (if using existing zone)"
  type        = string
  default     = null
}

variable "create_hosted_zone" {
  description = "Whether to create a new hosted zone"
  type        = bool
  default     = true
}

variable "enable_multi_region" {
  description = "Enable multi-region deployment"
  type        = bool
  default     = true # Enabled for multi-region active-active testing
}

variable "health_check_regions" {
  description = "Regions for Route 53 health checks (minimum 3 required)"
  type        = list(string)
  default     = ["us-east-1", "us-west-1", "eu-west-1"]
}

variable "alarm_email_endpoints" {
  description = "Email addresses for alarm notifications"
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "additional_tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Owner      = "Development Team"
    CostCenter = "Engineering"
    Purpose    = "Development"
    Automation = "terraform"
  }
}