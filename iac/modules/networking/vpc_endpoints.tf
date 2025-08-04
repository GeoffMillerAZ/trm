# VPC Endpoints for AWS Services

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name_prefix = "${var.project_name}-vpc-endpoints-${var.environment}-${var.region}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc-endpoints-sg-${var.environment}-${var.region}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "s3") ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id
  policy            = data.aws_iam_policy_document.s3_endpoint_policy[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-s3-endpoint-${var.environment}-${var.region}"
  })
}

data "aws_iam_policy_document" "s3_endpoint_policy" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "s3") ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "dynamodb") ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id
  policy            = data.aws_iam_policy_document.dynamodb_endpoint_policy[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-dynamodb-endpoint-${var.environment}-${var.region}"
  })
}

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "dynamodb") ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem"
    ]
    resources = ["*"]
  }
}

# SSM Interface Endpoint
resource "aws_vpc_endpoint" "ssm" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "ssm") ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  policy              = data.aws_iam_policy_document.ssm_endpoint_policy[0].json
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ssm-endpoint-${var.environment}-${var.region}"
  })
}

data "aws_iam_policy_document" "ssm_endpoint_policy" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "ssm") ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = ["*"]
  }
}

# KMS Interface Endpoint
resource "aws_vpc_endpoint" "kms" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "kms") ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-kms-endpoint-${var.environment}-${var.region}"
  })
}

# CloudWatch Logs Interface Endpoint
resource "aws_vpc_endpoint" "logs" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "monitoring") ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-logs-endpoint-${var.environment}-${var.region}"
  })
}

# CloudWatch Monitoring Interface Endpoint
resource "aws_vpc_endpoint" "monitoring" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "monitoring") ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-monitoring-endpoint-${var.environment}-${var.region}"
  })
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "ecr.api") ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-api-endpoint-${var.environment}-${var.region}"
  })
}

# ECR DKR Interface Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_vpc_endpoints && contains(var.vpc_endpoints, "ecr.dkr") ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-dkr-endpoint-${var.environment}-${var.region}"
  })
}
