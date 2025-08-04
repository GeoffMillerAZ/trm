# Account Bootstrap - Variables

variable "primary_region" {
  description = "Primary AWS region for security services"
  type        = string
  default     = "us-west-2"
}

variable "secondary_region" {
  description = "Secondary AWS region for multi-region services"
  type        = string
  default     = "us-east-2"
}

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

variable "enable_codeguru" {
  description = "Enable AWS CodeGuru for code quality and security analysis"
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Enable AWS Security Hub for centralized security findings (future enhancement)"
  type        = bool
  default     = false # Set to true when ready to enable Security Hub
}

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

variable "notification_email" {
  description = "Email address for security notifications"
  type        = string
  default     = ""
}

variable "enable_multi_region_guardduty" {
  description = "Enable GuardDuty in multiple regions"
  type        = bool
  default     = false # Set to true for production
}

variable "enable_lambda_scanning" {
  description = "Enable AWS Inspector scanning for Lambda functions"
  type        = bool
  default     = false
}

variable "enable_ec2_scanning" {
  description = "Enable AWS Inspector scanning for EC2 instances"
  type        = bool
  default     = false # Not needed for serverless demo
}

variable "enable_ecr_scanning" {
  description = "Enable AWS Inspector scanning for ECR images"
  type        = bool
  default     = false # Enable if using containers
}

variable "guardduty_finding_publishing_frequency" {
  description = "How often GuardDuty publishes findings (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)"
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "tags" {
  description = "Additional tags for resources"
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

variable "create_health_check_record" {
  description = "Create a health check endpoint record"
  type        = bool
  default     = false
}

# GitHub Actions Configuration
variable "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC role for pushing images to ECR"
  type        = string
  default     = null
}

# KMS Configuration
variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}
