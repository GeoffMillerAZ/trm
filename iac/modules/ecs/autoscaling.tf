# ECS Service Auto Scaling Configuration

# This file provides reusable auto-scaling configurations for ECS services
# Services using this module can leverage these policies

# Auto Scaling Target for ECS Service
resource "aws_appautoscaling_target" "ecs_service" {
  for_each = var.service_autoscaling_configs

  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_cluster.main]
}

# CPU-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "ecs_cpu" {
  for_each = {
    for k, v in var.service_autoscaling_configs : k => v
    if lookup(v, "enable_cpu_scaling", true)
  }

  name               = "${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = lookup(each.value, "cpu_target_value", 70)
    scale_in_cooldown  = lookup(each.value, "scale_in_cooldown", 300)
    scale_out_cooldown = lookup(each.value, "scale_out_cooldown", 60)
  }
}

# Memory-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "ecs_memory" {
  for_each = {
    for k, v in var.service_autoscaling_configs : k => v
    if lookup(v, "enable_memory_scaling", false)
  }

  name               = "${each.key}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = lookup(each.value, "memory_target_value", 80)
    scale_in_cooldown  = lookup(each.value, "scale_in_cooldown", 300)
    scale_out_cooldown = lookup(each.value, "scale_out_cooldown", 60)
  }
}

# Request Count-based Auto Scaling Policy (for services with ALB)
resource "aws_appautoscaling_policy" "ecs_alb_request_count" {
  for_each = {
    for k, v in var.service_autoscaling_configs : k => v
    if lookup(v, "enable_alb_request_scaling", false) && lookup(v, "alb_target_group_arn", null) != null
  }

  name               = "${each.key}-alb-request-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${split("/", each.value.alb_target_group_arn)[1]}/${split("/", each.value.alb_target_group_arn)[2]}"
    }
    target_value       = lookup(each.value, "alb_request_target_value", 1000)
    scale_in_cooldown  = lookup(each.value, "scale_in_cooldown", 300)
    scale_out_cooldown = lookup(each.value, "scale_out_cooldown", 60)
  }
}

# Scheduled Scaling for predictable traffic patterns
resource "aws_appautoscaling_scheduled_action" "ecs_scheduled" {
  for_each = {
    for item in flatten([
      for service_name, config in var.service_autoscaling_configs : [
        for schedule_name, schedule in lookup(config, "scheduled_actions", {}) : {
          key           = "${service_name}-${schedule_name}"
          service_name  = service_name
          schedule_name = schedule_name
          schedule      = schedule
        }
      ]
    ]) : item.key => item
  }

  name               = each.value.schedule_name
  service_namespace  = aws_appautoscaling_target.ecs_service[each.value.service_name].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_service[each.value.service_name].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service[each.value.service_name].scalable_dimension

  schedule = each.value.schedule.schedule

  scalable_target_action {
    min_capacity = lookup(each.value.schedule, "min_capacity", null)
    max_capacity = lookup(each.value.schedule, "max_capacity", null)
  }
}