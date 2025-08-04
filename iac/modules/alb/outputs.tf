# ALB Module Outputs

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = aws_lb.main.id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the default target group"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "Name of the default target group"
  value       = aws_lb_target_group.main.name
}

output "additional_target_group_arns" {
  description = "ARNs of additional target groups"
  value       = { for k, v in aws_lb_target_group.additional : k => v.arn }
}

output "additional_target_group_names" {
  description = "Names of additional target groups"
  value       = { for k, v in aws_lb_target_group.additional : k => v.name }
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = var.create_http_listener ? aws_lb_listener.http[0].arn : null
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.create_https_listener ? aws_lb_listener.https[0].arn : null
}

output "vpc_link_target_arns" {
  description = "Target ARNs for VPC Link (load balancer ARN)"
  value       = [aws_lb.main.arn]
}