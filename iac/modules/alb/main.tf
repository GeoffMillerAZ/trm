# Application Load Balancer Module for ECS Services

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Module = "alb"
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-${var.name_suffix}"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  
  # Access logs (optional)
  dynamic "access_logs" {
    for_each = var.access_logs_config != null ? [var.access_logs_config] : []
    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = access_logs.value.enabled
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${var.name_suffix}"
  })
}

# Default Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-${var.environment}-${var.name_suffix}"
  port        = var.target_group_config.port
  protocol    = var.target_group_config.protocol
  vpc_id      = var.vpc_id
  target_type = var.target_group_config.target_type

  # Health check configuration
  health_check {
    enabled             = var.target_group_config.health_check.enabled
    healthy_threshold   = var.target_group_config.health_check.healthy_threshold
    unhealthy_threshold = var.target_group_config.health_check.unhealthy_threshold
    timeout             = var.target_group_config.health_check.timeout
    interval            = var.target_group_config.health_check.interval
    path                = var.target_group_config.health_check.path
    matcher             = var.target_group_config.health_check.matcher
    port                = var.target_group_config.health_check.port
    protocol            = var.target_group_config.health_check.protocol
  }

  # Deregistration delay
  deregistration_delay = var.target_group_config.deregistration_delay

  # Target group attributes
  dynamic "stickiness" {
    for_each = var.target_group_config.stickiness != null ? [var.target_group_config.stickiness] : []
    content {
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      enabled         = stickiness.value.enabled
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${var.name_suffix}"
  })
}

# Additional Target Groups (for blue-green deployments, multiple services, etc.)
resource "aws_lb_target_group" "additional" {
  for_each = var.additional_target_groups

  name        = "${var.project_name}-${var.environment}-${each.key}"
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.target_type

  health_check {
    enabled             = each.value.health_check.enabled
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    timeout             = each.value.health_check.timeout
    interval            = each.value.health_check.interval
    path                = each.value.health_check.path
    matcher             = each.value.health_check.matcher
    port                = each.value.health_check.port
    protocol            = each.value.health_check.protocol
  }

  deregistration_delay = each.value.deregistration_delay

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      enabled         = stickiness.value.enabled
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}"
  })
}

# HTTP Listener (for redirecting HTTP to HTTPS or handling HTTP traffic)
resource "aws_lb_listener" "http" {
  count = var.create_http_listener ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.http_redirect_to_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.http_redirect_to_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main.arn
    }
  }

  tags = local.common_tags
}

# HTTPS Listener (for SSL/TLS traffic)
resource "aws_lb_listener" "https" {
  count = var.create_https_listener ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = local.common_tags
}

# Listener Rules for routing (optional)
resource "aws_lb_listener_rule" "rules" {
  for_each = var.listener_rules

  listener_arn = var.create_https_listener ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn
  priority     = each.value.priority

  action {
    type             = each.value.action.type
    target_group_arn = each.value.action.type == "forward" ? aws_lb_target_group.additional[each.value.action.target_group].arn : null
    
    dynamic "redirect" {
      for_each = each.value.action.type == "redirect" ? [each.value.action.redirect] : []
      content {
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        status_code = redirect.value.status_code
        host        = redirect.value.host
        path        = redirect.value.path
        query       = redirect.value.query
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.action.type == "fixed-response" ? [each.value.action.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }
  }

  # Path-based routing
  dynamic "condition" {
    for_each = lookup(each.value, "path_pattern", null) != null ? [1] : []
    content {
      path_pattern {
        values = [each.value.path_pattern]
      }
    }
  }

  # Host-based routing
  dynamic "condition" {
    for_each = lookup(each.value, "host_header", null) != null ? [1] : []
    content {
      host_header {
        values = [each.value.host_header]
      }
    }
  }

  # HTTP method routing
  dynamic "condition" {
    for_each = lookup(each.value, "http_request_method", null) != null ? [1] : []
    content {
      http_request_method {
        values = each.value.http_request_method
      }
    }
  }

  tags = local.common_tags
}