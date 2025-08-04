# API Gateway Module Variables

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

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = null
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "Blockchain Explorer API"
}

variable "stage_name" {
  description = "Stage name for API deployment"
  type        = string
  default     = null
}

variable "lambda_function_invoke_arn" {
  description = "Lambda function invoke ARN for API integration (legacy)"
  type        = string
  default     = null
}

variable "lambda_function_name" {
  description = "Lambda function name for permissions (legacy)"
  type        = string
  default     = null
}

variable "health_lambda_invoke_arn" {
  description = "Health check Lambda function invoke ARN (legacy)"
  type        = string
  default     = null
}

variable "health_lambda_function_name" {
  description = "Health check Lambda function name (legacy)"
  type        = string
  default     = null
}

# ECS Integration Variables
variable "integration_type" {
  description = "Integration type: 'lambda' for Lambda functions, 'http' for ECS services"
  type        = string
  default     = "lambda"
  validation {
    condition     = contains(["lambda", "http"], var.integration_type)
    error_message = "Integration type must be either 'lambda' or 'http'."
  }
}

variable "alb_arn" {
  description = "ALB ARN for VPC Link target (required for HTTP integrations)"
  type        = string
  default     = null
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer for HTTP integrations"
  type        = string
  default     = null
}

variable "alb_listener_port" {
  description = "Port of the ALB listener for HTTP integrations"
  type        = number
  default     = 80
}

variable "custom_domain_name" {
  description = "Custom domain name for API Gateway"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain"
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for custom domain"
  type        = string
  default     = null
}

variable "enable_caching" {
  description = "Enable API Gateway caching"
  type        = bool
  default     = true
}

variable "cache_cluster_size" {
  description = "API Gateway cache cluster size"
  type        = string
  default     = "0.5"
}

variable "cache_ttl_seconds" {
  description = "Cache TTL in seconds"
  type        = number
  default     = 300
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 1000
}

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 500
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for API Gateway"
  type        = bool
  default     = true
}

variable "enable_access_logs" {
  description = "Enable access logging for API Gateway"
  type        = bool
  default     = true
}

variable "api_key_source" {
  description = "Source of API key for requests"
  type        = string
  default     = "HEADER"
  validation {
    condition     = contains(["HEADER", "AUTHORIZER"], var.api_key_source)
    error_message = "API key source must be either HEADER or AUTHORIZER."
  }
}

variable "usage_plans" {
  description = "Map of usage plans to create"
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
  default = {}
}

variable "api_keys" {
  description = "Map of API keys to create"
  type = map(object({
    description = string
    usage_plan  = string
  }))
  default = {}
}

variable "cors_configuration" {
  description = "CORS configuration for API Gateway"
  type = object({
    allow_origins     = list(string)
    allow_methods     = list(string)
    allow_headers     = list(string)
    expose_headers    = list(string)
    allow_credentials = bool
    max_age           = number
  })
  default = {
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
    expose_headers    = ["X-Amz-Request-Id"]
    allow_credentials = false
    max_age           = 86400
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}