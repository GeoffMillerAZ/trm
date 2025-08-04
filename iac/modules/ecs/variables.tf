# ECS Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ECS cluster will be deployed"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

variable "enable_fargate" {
  description = "Enable Fargate capacity provider"
  type        = bool
  default     = true
}

variable "enable_ec2" {
  description = "Enable EC2 capacity provider"
  type        = bool
  default     = false
}

variable "ec2_asg_arn" {
  description = "ARN of the Auto Scaling Group for EC2 capacity provider"
  type        = string
  default     = null
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
    }
  ]
}

variable "managed_termination_protection" {
  description = "Enable managed termination protection for EC2 capacity provider"
  type        = string
  default     = "ENABLED"
}

variable "maximum_scaling_step_size" {
  description = "Maximum scaling step size for EC2 capacity provider"
  type        = number
  default     = 10
}

variable "minimum_scaling_step_size" {
  description = "Minimum scaling step size for EC2 capacity provider"
  type        = number
  default     = 1
}

variable "target_capacity" {
  description = "Target capacity for EC2 capacity provider"
  type        = number
  default     = 80
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting logs and secrets"
  type        = string
  default     = null
}

variable "enable_service_discovery" {
  description = "Enable AWS Service Discovery (Cloud Map)"
  type        = bool
  default     = true
}

variable "service_discovery_namespace" {
  description = "Service discovery namespace (e.g., local, internal)"
  type        = string
  default     = "local"
}

variable "secrets_arns" {
  description = "List of Secrets Manager secret ARNs that tasks can access"
  type        = list(string)
  default     = ["*"]
}

variable "enable_xray" {
  description = "Enable AWS X-Ray tracing for tasks"
  type        = bool
  default     = true
}

variable "container_port" {
  description = "Default container port for services"
  type        = number
  default     = 8000
}

variable "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer"
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ECS services"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "create_service_linked_role" {
  description = "Create ECS service-linked role (set to false if it already exists)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "service_autoscaling_configs" {
  description = "Auto-scaling configurations for ECS services"
  type = map(object({
    min_capacity               = number
    max_capacity               = number
    enable_cpu_scaling         = optional(bool, true)
    cpu_target_value           = optional(number, 70)
    enable_memory_scaling      = optional(bool, false)
    memory_target_value        = optional(number, 80)
    enable_alb_request_scaling = optional(bool, false)
    alb_target_group_arn       = optional(string)
    alb_request_target_value   = optional(number, 1000)
    scale_in_cooldown          = optional(number, 300)
    scale_out_cooldown         = optional(number, 60)
    scheduled_actions = optional(map(object({
      schedule     = string
      min_capacity = optional(number)
      max_capacity = optional(number)
    })), {})
  }))
  default = {}
}