# ALB Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for ALB name (e.g., 'api', 'internal')"
  type        = string
  default     = "alb"
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal (true) or internet-facing (false)"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Enable HTTP/2 for the ALB"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "access_logs_config" {
  description = "Access logs configuration"
  type = object({
    bucket  = string
    prefix  = string
    enabled = bool
  })
  default = null
}

variable "target_group_config" {
  description = "Default target group configuration"
  type = object({
    port                = number
    protocol            = string
    target_type         = string
    deregistration_delay = number
    
    health_check = object({
      enabled             = bool
      healthy_threshold   = number
      unhealthy_threshold = number
      timeout             = number
      interval            = number
      path                = string
      matcher             = string
      port                = string
      protocol            = string
    })
    
    stickiness = optional(object({
      type            = string
      cookie_duration = number
      enabled         = bool
    }))
  })
  default = {
    port                = 8000
    protocol            = "HTTP"
    target_type         = "ip"
    deregistration_delay = 300
    
    health_check = {
      enabled             = true
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
      interval            = 30
      path                = "/health"
      matcher             = "200"
      port                = "traffic-port"
      protocol            = "HTTP"
    }
  }
}

variable "additional_target_groups" {
  description = "Additional target groups for blue-green deployments or multiple services"
  type = map(object({
    port                = number
    protocol            = string
    target_type         = string
    deregistration_delay = number
    
    health_check = object({
      enabled             = bool
      healthy_threshold   = number
      unhealthy_threshold = number
      timeout             = number
      interval            = number
      path                = string
      matcher             = string
      port                = string
      protocol            = string
    })
    
    stickiness = optional(object({
      type            = string
      cookie_duration = number
      enabled         = bool
    }))
  }))
  default = {}
}

variable "create_http_listener" {
  description = "Create HTTP listener"
  type        = bool
  default     = true
}

variable "create_https_listener" {
  description = "Create HTTPS listener"
  type        = bool
  default     = false
}

variable "http_redirect_to_https" {
  description = "Redirect HTTP traffic to HTTPS"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "listener_rules" {
  description = "Listener rules for advanced routing"
  type = map(object({
    priority = number
    
    action = object({
      type         = string
      target_group = optional(string)
      
      redirect = optional(object({
        port        = string
        protocol    = string
        status_code = string
        host        = optional(string)
        path        = optional(string)
        query       = optional(string)
      }))
      
      fixed_response = optional(object({
        content_type = string
        message_body = optional(string)
        status_code  = string
      }))
    })
    
    # Conditions
    path_pattern          = optional(string)
    host_header          = optional(string)
    http_request_method  = optional(list(string))
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}