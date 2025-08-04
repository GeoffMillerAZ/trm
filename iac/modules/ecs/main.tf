# ECS Cluster Module

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
  cluster_name = "${var.project_name}-${var.environment}-${var.region}"

  common_tags = merge(var.tags, {
    Module      = "ecs"
    ClusterName = local.cluster_name
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(local.common_tags, {
    Name = local.cluster_name
  })
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = concat(
    var.enable_fargate ? ["FARGATE", "FARGATE_SPOT"] : [],
    var.enable_ec2 ? [aws_ecs_capacity_provider.ec2[0].name] : []
  )

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = default_capacity_provider_strategy.value.weight
      base              = lookup(default_capacity_provider_strategy.value, "base", null)
    }
  }
}

# EC2 Capacity Provider (if enabled)
resource "aws_ecs_capacity_provider" "ec2" {
  count = var.enable_ec2 ? 1 : 0
  name  = "${local.cluster_name}-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.ec2_asg_arn
    managed_termination_protection = var.managed_termination_protection

    managed_scaling {
      maximum_scaling_step_size = var.maximum_scaling_step_size
      minimum_scaling_step_size = var.minimum_scaling_step_size
      status                    = "ENABLED"
      target_capacity           = var.target_capacity
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-ec2-capacity-provider"
  })
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.cluster_name}"
  retention_in_days = var.log_retention_days
  # Temporarily disable KMS encryption to avoid permission issues
  # kms_key_id        = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = "/ecs/${local.cluster_name}"
  })
}

# Service Discovery Namespace (AWS Cloud Map)
resource "aws_service_discovery_private_dns_namespace" "main" {
  count = var.enable_service_discovery ? 1 : 0

  name        = "${var.environment}.${var.service_discovery_namespace}"
  description = "Service discovery namespace for ${local.cluster_name}"
  vpc         = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.environment}.${var.service_discovery_namespace}"
  })
}

# ECS Task Execution Role (shared by all tasks)
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.cluster_name}-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-task-execution"
  })
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution.name
}

# Additional policy for Secrets Manager and KMS access
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${local.cluster_name}-task-execution-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = var.secrets_arns
        }
      ],
      var.kms_key_arn != null ? [
        {
          Effect = "Allow"
          Action = [
            "kms:Decrypt"
          ]
          Resource = [var.kms_key_arn]
        }
      ] : []
    )
  })
}

# Default ECS Task Role (for application permissions)
resource "aws_iam_role" "ecs_task" {
  name = "${local.cluster_name}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-task"
  })
}

# CloudWatch Logs policy for tasks
resource "aws_iam_role_policy" "ecs_task_logs" {
  name = "${local.cluster_name}-task-logs"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
      }
    ]
  })
}

# X-Ray policy for tasks (if enabled)
resource "aws_iam_role_policy" "ecs_task_xray" {
  count = var.enable_xray ? 1 : 0
  name  = "${local.cluster_name}-task-xray"
  role  = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECS Service Security Group
resource "aws_security_group" "ecs_service" {
  name        = "${local.cluster_name}-service"
  description = "Security group for ECS services in ${local.cluster_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow inbound traffic on container port"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow HTTPS traffic"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow HTTP traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-service"
  })
}

# Allow inbound traffic from ALB (if provided)
resource "aws_security_group_rule" "ecs_from_alb" {
  count = var.alb_security_group_id != null ? 1 : 0

  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
  security_group_id        = aws_security_group.ecs_service.id
  description              = "Allow traffic from ALB"
}

# EC2 Instance Profile for ECS (if using EC2 launch type)
resource "aws_iam_role" "ecs_instance" {
  count = var.enable_ec2 ? 1 : 0
  name  = "${local.cluster_name}-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-instance"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  count      = var.enable_ec2 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.ecs_instance[0].name
}

resource "aws_iam_instance_profile" "ecs" {
  count = var.enable_ec2 ? 1 : 0
  name  = "${local.cluster_name}-instance-profile"
  role  = aws_iam_role.ecs_instance[0].name
}

# ECS Service-Linked Role (ensure it exists)
resource "aws_iam_service_linked_role" "ecs" {
  count            = var.create_service_linked_role ? 1 : 0
  aws_service_name = "ecs.amazonaws.com"
}
