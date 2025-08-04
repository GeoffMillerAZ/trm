# ECS Service Module Outputs

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.main.id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.main.family
}

output "task_definition_revision" {
  description = "Revision of the task definition"
  value       = aws_ecs_task_definition.main.revision
}

output "autoscaling_target_resource_id" {
  description = "Resource ID of the auto-scaling target"
  value       = var.enable_autoscaling ? aws_appautoscaling_target.ecs[0].resource_id : null
}

output "container_name" {
  description = "Name of the container"
  value       = var.service_name
}

output "container_port" {
  description = "Port exposed by the container"
  value       = var.container_port
}

output "service_discovery_arn" {
  description = "ARN of the service discovery service"
  value       = var.service_discovery_config != null ? var.service_discovery_config.registry_arn : null
}