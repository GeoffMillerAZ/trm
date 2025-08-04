# Security Resources - KMS Keys and Security Groups

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
    Project     = var.project_name
    Environment = var.environment
    Region      = var.region
    Module      = "security"
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Lambda Security Group
resource "aws_security_group" "lambda" {
  count       = var.create_security_groups ? 1 : 0
  name_prefix = "${var.project_name}-lambda-sg-${var.environment}-${var.region}-"
  vpc_id      = var.vpc_id
  description = "Security group for Lambda functions"

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-lambda-sg-${var.environment}-${var.region}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Security Group (if using private API Gateway in VPC)
resource "aws_security_group" "api_gateway" {
  count       = var.create_security_groups ? 1 : 0
  name_prefix = "${var.project_name}-api-gateway-sg-${var.environment}-${var.region}-"
  vpc_id      = var.vpc_id
  description = "Security group for API Gateway"

  # Inbound HTTPS from anywhere (public API)
  ingress {
    description = "HTTPS inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-api-gateway-sg-${var.environment}-${var.region}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Database Security Group (for future RDS/Aurora if needed)
resource "aws_security_group" "database" {
  count       = var.create_security_groups ? 1 : 0
  name_prefix = "${var.project_name}-database-sg-${var.environment}-${var.region}-"
  vpc_id      = var.vpc_id
  description = "Security group for database instances"

  # Inbound from Lambda security group
  ingress {
    description     = "From Lambda functions"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda[0].id]
  }

  # No outbound rules needed for database

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-database-sg-${var.environment}-${var.region}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  count       = var.create_security_groups ? 1 : 0
  name_prefix = "${var.project_name}-alb-sg-${var.environment}-${var.region}-"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  # Inbound HTTP from private subnets (API Gateway VPC Link)
  ingress {
    description = "HTTP from private subnets"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # Inbound HTTPS from private subnets (if needed)
  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb-sg-${var.environment}-${var.region}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  count       = var.create_security_groups ? 1 : 0
  name_prefix = "${var.project_name}-ecs-sg-${var.environment}-${var.region}-"
  vpc_id      = var.vpc_id
  description = "Security group for ECS services"

  # Inbound from ALB
  ingress {
    description     = "From ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = var.create_security_groups ? [aws_security_group.alb[0].id] : []
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecs-sg-${var.environment}-${var.region}"
  })

  lifecycle {
    create_before_destroy = true
  }
}
