# Development Environment - US West 2 Variables

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
  default     = ["us-east-2"] # Secondary region for multi-region testing
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

# Development Networking Configuration
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

# DNS Configuration
variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for DNS records"
  type        = string
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
    Owner       = "Development Team"
    CostCenter  = "Engineering"
    Purpose     = "Development"
    Automation  = "terraform"
    Region      = "us-west-2"
    MultiRegion = "false"
  }
}
