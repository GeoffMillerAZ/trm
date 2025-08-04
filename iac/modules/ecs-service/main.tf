# ECS Service Module for Application Deployment

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  common_tags = merge(var.tags, {
    Module = "ecs-service"
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.service_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  # Specify runtime platform to ensure x86_64 architecture
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name  = var.service_name
      image = "${var.container_image}:${var.image_tag}"

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = concat(
        [
          { name = "ENVIRONMENT", value = var.environment },
          { name = "REGION", value = data.aws_region.current.name },
          { name = "PORT", value = tostring(var.container_port) },
          { name = "PROJECT_NAME", value = var.project_name }
        ],
        var.environment_variables
      )

      secrets = var.secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.health_check

      essential = true
    }
  ])

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-${var.service_name}-${var.environment}"
    ServiceName = var.service_name
  })
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.service_name}-${var.environment}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  platform_version = var.platform_version

  # Commenting out deployment configuration for now to get basic service working
  # deployment_configuration {
  #   maximum_percent         = var.deployment_configuration.maximum_percent
  #   minimum_healthy_percent = var.deployment_configuration.minimum_healthy_percent
  # }

  # deployment_circuit_breaker {
  #   enable   = var.deployment_configuration.enable_circuit_breaker
  #   rollback = var.deployment_configuration.enable_rollback
  # }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  # Load balancer configuration (optional)
  dynamic "load_balancer" {
    for_each = var.load_balancer_config != null ? [var.load_balancer_config] : []
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  # Service discovery configuration (optional)
  dynamic "service_registries" {
    for_each = var.service_discovery_config != null ? [var.service_discovery_config] : []
    content {
      registry_arn = service_registries.value.registry_arn
    }
  }

  # Enable execute command for debugging
  enable_execute_command = var.enable_execute_command

  # Force deployment when task definition changes
  force_new_deployment = var.force_new_deployment

  # Wait for steady state
  wait_for_steady_state = var.wait_for_steady_state

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-${var.service_name}-${var.environment}"
    ServiceName = var.service_name
  })

  depends_on = [aws_ecs_task_definition.main]
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_config.max_capacity
  min_capacity       = var.autoscaling_config.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.service_name}-${var.environment}-autoscaling"
  })
}

# CPU-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling && var.autoscaling_config.enable_cpu_scaling ? 1 : 0

  name               = "${var.project_name}-${var.service_name}-${var.environment}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_config.cpu_target_value
    scale_in_cooldown  = var.autoscaling_config.scale_in_cooldown
    scale_out_cooldown = var.autoscaling_config.scale_out_cooldown
  }
}

# Memory-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "memory" {
  count = var.enable_autoscaling && var.autoscaling_config.enable_memory_scaling ? 1 : 0

  name               = "${var.project_name}-${var.service_name}-${var.environment}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.autoscaling_config.memory_target_value
    scale_in_cooldown  = var.autoscaling_config.scale_in_cooldown
    scale_out_cooldown = var.autoscaling_config.scale_out_cooldown
  }
}

# ALB Request Count-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "alb_request_count" {
  count = var.enable_autoscaling && var.autoscaling_config.enable_alb_request_scaling ? 1 : 0

  name               = "${var.project_name}-${var.service_name}-${var.environment}-request-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.autoscaling_config.alb_resource_label
    }
    target_value       = var.autoscaling_config.alb_request_target_value
    scale_in_cooldown  = var.autoscaling_config.scale_in_cooldown
    scale_out_cooldown = var.autoscaling_config.scale_out_cooldown
  }
}

# Scheduled Auto Scaling (optional)
resource "aws_appautoscaling_scheduled_action" "scheduled" {
  for_each = var.enable_autoscaling ? var.autoscaling_config.scheduled_actions : {}

  name               = "${var.project_name}-${var.service_name}-${var.environment}-${each.key}"
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  schedule           = each.value.schedule

  scalable_target_action {
    min_capacity = lookup(each.value, "min_capacity", var.autoscaling_config.min_capacity)
    max_capacity = lookup(each.value, "max_capacity", var.autoscaling_config.max_capacity)
  }
}
