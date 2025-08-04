# Production Environment - US West 2 Variables (Primary Region)

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

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "is_primary_region" {
  description = "Whether this is the primary region"
  type        = bool
  default     = true
}

variable "replica_regions" {
  description = "List of replica regions for Global Tables"
  type        = list(string)
  default     = ["us-east-2"] # Secondary region for production
}

# Terraform State Configuration
variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "terraform_state_region" {
  description = "AWS region for Terraform state bucket"
  type        = string
  default     = "us-west-2"
}

# Production Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# Lambda Deployment Configuration
variable "lambda_deployment_package" {
  description = "Lambda deployment package configuration"
  type = object({
    filename  = optional(string)
    s3_bucket = optional(string)
    s3_key    = optional(string)
  })
  default = {
    filename  = "../../../../src/lambda_package.zip" # Local package for planning
    s3_bucket = null                                 # Will be configured in CI/CD pipeline
    s3_key    = null                                 # Will be configured in CI/CD pipeline
  }
}

# API Keys Configuration
variable "api_keys" {
  description = "API keys configuration"
  type = map(object({
    description = string
    usage_plan  = string
  }))
  default = {
    prod_premium_key = {
      description = "Production premium API key"
      usage_plan  = "premium"
    }
    prod_standard_key = {
      description = "Production standard API key"
      usage_plan  = "standard"
    }
    prod_basic_key = {
      description = "Production basic API key"
      usage_plan  = "basic"
    }
  }
  sensitive = true
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
    Owner            = "Platform Team"
    CostCenter       = "Production"
    Purpose          = "BlockExplorer"
    Automation       = "terraform"
    Region           = "us-west-2"
    RegionType       = "primary"
    MultiRegion      = "true"
    BackupSchedule   = "continuous"
    DisasterRecovery = "active-active"
  }
}