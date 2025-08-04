# Development Environment - US East 2 Variables (Secondary Region)

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

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "is_primary_region" {
  description = "Whether this is the primary region"
  type        = bool
  default     = false # This is the secondary region
}

variable "replica_regions" {
  description = "List of replica regions for Global Tables"
  type        = list(string)
  default     = ["us-west-2"] # Primary region for replication
}

# Terraform State Configuration
variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "terraform_state_region" {
  description = "AWS region for Terraform state bucket"
  type        = string
  default     = "us-west-2" # State bucket is in primary region
}

# Development Networking Configuration - Secondary Region
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16" # Different CIDR to avoid conflicts
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# ECS Configuration
variable "ecs_cluster_name" {
  description = "ECS cluster name from global resources"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN from global resources"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS task role ARN from global resources"
  type        = string
}

variable "container_image_uri" {
  description = "Container image URI for ECS service"
  type        = string
}

variable "ecs_service_config" {
  description = "ECS service configuration"
  type = object({
    cpu                    = optional(number, 256)
    memory                 = optional(number, 512)
    desired_count          = optional(number, 1)
    container_port         = optional(number, 8000)
    enable_autoscaling     = optional(bool, true)
    min_capacity           = optional(number, 1)
    max_capacity           = optional(number, 10)
    target_cpu_utilization = optional(number, 70)
    enable_logging         = optional(bool, true)
  })
}

variable "api_gateway_config" {
  description = "API Gateway configuration for ECS integration"
  type = object({
    enable_caching       = optional(bool, true)
    cache_cluster_size   = optional(string, "0.5")
    cache_ttl_seconds    = optional(number, 300)
    throttle_burst_limit = optional(number, 1000)
    throttle_rate_limit  = optional(number, 500)
    api_key_source       = optional(string, "HEADER")
  })
}

# API Keys Configuration - Different keys for secondary region
variable "api_keys" {
  description = "API keys configuration"
  type = map(object({
    description = string
    usage_plan  = string
  }))
  default = {
    dev_premium_key_secondary = {
      description = "Development premium API key (secondary region)"
      usage_plan  = "premium"
    }
    dev_standard_key_secondary = {
      description = "Development standard API key (secondary region)"
      usage_plan  = "standard"
    }
    dev_basic_key_secondary = {
      description = "Development basic API key (secondary region)"
      usage_plan  = "basic"
    }
  }
}

# Monitoring Configuration
variable "alarm_email_endpoints" {
  description = "Email addresses for alarm notifications"
  type        = list(string)
  default     = []
  sensitive   = true
}

# Tags
# Development-specific Configuration
variable "use_mock_blockchain" {
  description = "Whether to use mock blockchain or real Infura API"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Owner         = "Development Team"
    CostCenter    = "Engineering"
    Purpose       = "Development"
    Automation    = "terraform"
    Region        = "us-east-2"
    RegionType    = "secondary"
    MultiRegion   = "true"
    TestingRegion = "true"
  }
}
