# Regional Project Variables for TRM Block Explorer

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

variable "region" {
  description = "AWS region for regional resources"
  type        = string
}

variable "is_primary_region" {
  description = "Whether this is the primary region"
  type        = bool
  default     = true
}

variable "replica_regions" {
  description = "List of replica regions for Global Tables"
  type        = list(string)
  default     = []
}

# Global Resource References
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}

variable "kms_secrets_key_arn" {
  description = "KMS key ARN for secrets encryption"
  type        = string
}

variable "kms_data_key_arn" {
  description = "KMS key ARN for data encryption"
  type        = string
}

variable "kms_logs_key_arn" {
  description = "KMS key ARN for logs encryption"
  type        = string
}

variable "lambda_execution_role_arn" {
  description = "Lambda execution role ARN (optional - migrating to ECS)"
  type        = string
  default     = ""
}

variable "global_alarms_topic_arn" {
  description = "Global SNS topic ARN for alarms"
  type        = string
  default     = null
}

variable "dynamodb_tables" {
  description = "DynamoDB table configurations"
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
}

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_single_nat_gateway" {
  description = "Use single NAT Gateway for cost optimization"
  type        = bool
  default     = false
}

# Lambda Configuration (optional - migrating to ECS)
variable "lambda_functions" {
  description = "Lambda function configurations (optional - migrating to ECS)"
  type = map(object({
    handler               = string
    runtime               = optional(string, "python3.12")
    memory_size           = optional(number, 1024)
    timeout               = optional(number, 29)
    reserved_concurrency  = optional(number)
    environment_variables = optional(map(string), {})
    log_retention_days    = optional(number, 30)
  }))

  default = {}
}

variable "lambda_deployment_package" {
  description = "Lambda deployment package configuration (optional - migrating to ECS)"
  type = object({
    filename  = optional(string)
    s3_bucket = optional(string)
    s3_key    = optional(string)
  })
  default = {}
}

# ECS Configuration
variable "ecs_cluster_name" {
  description = "ECS cluster name from global resources"
  type        = string
  default     = ""
}

variable "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN from global resources"
  type        = string
  default     = ""
}

variable "ecs_task_role_arn" {
  description = "ECS task role ARN from global resources"
  type        = string
  default     = ""
}

variable "container_image_uri" {
  description = "Container image URI for ECS service"
  type        = string
  default     = ""
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
  default = {
    cpu                    = 256
    memory                 = 512
    desired_count          = 1
    container_port         = 8000
    enable_autoscaling     = true
    min_capacity           = 1
    max_capacity           = 10
    target_cpu_utilization = 70
    enable_logging         = true
  }
}

# API Gateway Configuration (ECS-only)
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
  default = {
    enable_caching       = true
    cache_cluster_size   = "0.5"
    cache_ttl_seconds    = 300
    throttle_burst_limit = 1000
    throttle_rate_limit  = 500
    api_key_source       = "HEADER"
  }
}

variable "api_usage_plans" {
  description = "API Gateway usage plans"
  type = map(object({
    description = string
    quota = optional(object({
      limit  = number
      period = string
    }))
    throttle = optional(object({
      burst_limit = number
      rate_limit  = number
    }))
  }))
  default = {
    basic = {
      description = "Basic usage plan"
      quota = {
        limit  = 10000
        period = "DAY"
      }
      throttle = {
        burst_limit = 200
        rate_limit  = 100
      }
    }
    premium = {
      description = "Premium usage plan"
      quota = {
        limit  = 100000
        period = "DAY"
      }
      throttle = {
        burst_limit = 1000
        rate_limit  = 500
      }
    }
  }
}

variable "api_keys" {
  description = "API Gateway API keys"
  type = map(object({
    description = string
    usage_plan  = string
  }))
  default = {
    development = {
      description = "Development API key"
      usage_plan  = "basic"
    }
  }
}

# Monitoring Configuration
variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    create_dashboard           = optional(bool, true)
    enable_detailed_monitoring = optional(bool, true)
    log_retention_days         = optional(number, 30)
    alarm_email_endpoints      = optional(list(string), [])
  })
  default = {
    create_dashboard           = true
    enable_detailed_monitoring = true
    log_retention_days         = 30
    alarm_email_endpoints      = []
  }
}

# Cost Optimization
variable "cost_optimization" {
  description = "Cost optimization settings"
  type = object({
    environment_based_sizing   = optional(bool, true)
    enable_deletion_protection = optional(bool, true)
  })
  default = {
    environment_based_sizing   = true
    enable_deletion_protection = true
  }
}

# Application Configuration
variable "use_mock_blockchain" {
  description = "Whether to use mock blockchain or real Infura API"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
