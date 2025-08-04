# Account Bootstrap Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "trm-blockexplorer"
}

variable "aws_region" {
  description = "Primary AWS region for deployment"
  type        = string
  default     = "us-west-2"
}

variable "secondary_region" {
  description = "Secondary AWS region for multi-region services"
  type        = string
  default     = "us-east-2"
}

# Security Services
variable "enable_guardduty" {
  description = "Enable AWS GuardDuty for threat detection"
  type        = bool
  default     = false
}

variable "enable_inspector" {
  description = "Enable AWS Inspector v2 for vulnerability scanning"
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Enable AWS Security Hub for centralized security findings"
  type        = bool
  default     = false
}

variable "enable_multi_region_guardduty" {
  description = "Enable GuardDuty in multiple regions"
  type        = bool
  default     = false
}

# Inspector Scanning Options
variable "enable_lambda_scanning" {
  description = "Enable AWS Inspector scanning for Lambda functions"
  type        = bool
  default     = false
}

variable "enable_ec2_scanning" {
  description = "Enable AWS Inspector scanning for EC2 instances"
  type        = bool
  default     = false
}

variable "enable_ecr_scanning" {
  description = "Enable AWS Inspector scanning for ECR images"
  type        = bool
  default     = false
}

# Retention Settings
variable "security_findings_retention_days" {
  description = "Number of days to retain security findings in S3"
  type        = number
  default     = 90
}

variable "sbom_retention_days" {
  description = "Number of days to retain SBOM exports in S3"
  type        = number
  default     = 365
}

# Notifications
variable "notification_email" {
  description = "Email address for security notifications"
  type        = string
  default     = ""
}

# GuardDuty Configuration
variable "guardduty_finding_publishing_frequency" {
  description = "How often GuardDuty publishes findings (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)"
  type        = string
  default     = "FIFTEEN_MINUTES"
}

# Additional Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# DNS Configuration
variable "root_domain" {
  description = "Root domain managed in Namecheap"
  type        = string
  default     = "geoffmiller.cloud"
}

variable "subdomain_prefix" {
  description = "Subdomain prefix for this project"
  type        = string
  default     = "trm"
}

variable "create_dev_zone" {
  description = "Create separate hosted zone for dev environment"
  type        = bool
  default     = true
}

variable "create_staging_zone" {
  description = "Create separate hosted zone for staging environment"
  type        = bool
  default     = false
}