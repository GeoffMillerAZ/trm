# ECS Service Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID where the service will be deployed"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name (used for auto-scaling resource ID)"
  type        = string
}

variable "container_image" {
  description = "Container image URI (without tag)"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Memory for the task in MB"
  type        = string
  default     = "1024"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8000
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "task_execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the service"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = false
}

variable "platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}

variable "log_group_name" {
  description = "CloudWatch log group name for container logs"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Secrets from AWS Secrets Manager or SSM Parameter Store"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "health_check" {
  description = "Container health check configuration"
  type = object({
    command     = list(string)
    interval    = number
    timeout     = number
    retries     = number
    startPeriod = number
  })
  default = {
    command     = ["CMD-SHELL", "curl -f http://localhost:8080/api/v1/health || exit 1"]
    interval    = 30
    timeout     = 5
    retries     = 3
    startPeriod = 60
  }
}

variable "deployment_configuration" {
  description = "ECS service deployment configuration"
  type = object({
    maximum_percent         = number
    minimum_healthy_percent = number
    enable_circuit_breaker  = bool
    enable_rollback         = bool
  })
  default = {
    maximum_percent         = 200
    minimum_healthy_percent = 100
    enable_circuit_breaker  = true
    enable_rollback         = true
  }
}

variable "load_balancer_config" {
  description = "Load balancer configuration for the service"
  type = object({
    target_group_arn = string
  })
  default = null
}

variable "service_discovery_config" {
  description = "Service discovery configuration"
  type = object({
    registry_arn = string
  })
  default = null
}

variable "health_check_grace_period_seconds" {
  description = "Grace period for health checks when load balancer is configured"
  type        = number
  default     = 60
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

variable "force_new_deployment" {
  description = "Force new deployment when task definition changes"
  type        = bool
  default     = false
}

variable "wait_for_steady_state" {
  description = "Wait for service to reach steady state after deployment"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling for the ECS service"
  type        = bool
  default     = true
}

variable "autoscaling_config" {
  description = "Auto-scaling configuration for the ECS service"
  type = object({
    min_capacity               = number
    max_capacity               = number
    enable_cpu_scaling         = optional(bool, true)
    cpu_target_value           = optional(number, 70)
    enable_memory_scaling      = optional(bool, false)
    memory_target_value        = optional(number, 80)
    enable_alb_request_scaling = optional(bool, false)
    alb_resource_label         = optional(string)
    alb_request_target_value   = optional(number, 1000)
    scale_in_cooldown          = optional(number, 300)
    scale_out_cooldown         = optional(number, 60)
    scheduled_actions = optional(map(object({
      schedule     = string
      min_capacity = optional(number)
      max_capacity = optional(number)
    })), {})
  })
  default = {
    min_capacity     = 2
    max_capacity     = 10
    cpu_target_value = 70
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
