# Regional Resources for TRM Block Explorer

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Auto-generate AZs and subnets if not provided
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnet_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2),
    cidrsubnet(var.vpc_cidr, 8, 3)
  ]

  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    cidrsubnet(var.vpc_cidr, 8, 11),
    cidrsubnet(var.vpc_cidr, 8, 12),
    cidrsubnet(var.vpc_cidr, 8, 13)
  ]

  # Environment-based resource sizing
  lambda_memory_size = var.cost_optimization.environment_based_sizing ? (
    var.environment == "prod" ? 1024 : 512
  ) : 1024

  lambda_reserved_concurrency = var.cost_optimization.environment_based_sizing ? (
    var.environment == "prod" ? 100 : 25
  ) : null


  common_tags = merge(var.tags, {
    Project       = var.project_name
    Environment   = var.environment
    Region        = local.region
    ManagedBy     = "terraform"
    Repository    = "trm-blockexplorer"
    Layer         = "regional"
    PrimaryRegion = var.is_primary_region
  })
}

# Networking Module
module "networking" {
  source = "../../../modules/networking"

  project_name              = var.project_name
  environment               = var.environment
  region                    = local.region
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = local.availability_zones
  public_subnet_cidrs       = local.public_subnet_cidrs
  private_subnet_cidrs      = local.private_subnet_cidrs
  enable_nat_gateway        = var.enable_nat_gateway
  enable_single_nat_gateway = var.enable_single_nat_gateway
  enable_vpc_endpoints      = true
  vpc_endpoints             = ["s3", "dynamodb", "ssm", "kms", "monitoring", "ecr.api", "ecr.dkr", "logs"]
  enable_flow_logs          = true
  flow_logs_retention_days  = var.monitoring_config.log_retention_days

  tags = local.common_tags
}

# Security Module
module "security" {
  source = "../../../modules/security"

  project_name         = var.project_name
  environment          = var.environment
  region               = local.region
  vpc_id               = module.networking.vpc_id
  vpc_cidr_block       = module.networking.vpc_cidr_block
  private_subnet_cidrs = module.networking.private_subnet_cidrs
  create_kms_keys      = false # Using global KMS keys

  tags = local.common_tags
}

# DynamoDB Module
module "dynamodb" {
  source = "../../../modules/dynamodb"

  project_name               = var.project_name
  environment                = var.environment
  region                     = local.region
  is_primary_region          = var.is_primary_region
  replica_regions            = var.replica_regions
  tables                     = var.dynamodb_tables
  kms_key_arn                = var.kms_data_key_arn
  enable_deletion_protection = var.cost_optimization.enable_deletion_protection

  tags = local.common_tags
}

# IAM Roles for ECS
# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-${var.environment}-${local.region}"

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
    Name = "${var.project_name}-ecs-task-execution-${var.environment}-${local.region}"
    Type = "ECSTaskExecution"
  })
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach read-only ECR policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_ecr_readonly" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# Policy for ECR access to allow pulling container images
resource "aws_iam_role_policy" "ecs_task_execution_ecr" {
  count = 0 # Disabling this as it's covered by the managed policy
  name = "${var.project_name}-ecs-task-execution-ecr-${var.environment}"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:*",
        ]
        Resource = "*"
      }
    ]
  })
}


# Additional policy for accessing secrets and ECR
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${var.project_name}-ecs-task-execution-secrets-${var.environment}"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:*",
          "arn:aws:ssm:${local.region}:${local.account_id}:parameter/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "kms:Decrypt"
        Resource = "*"
      }
    ]
  })
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-${var.environment}-${local.region}"

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
    Name = "${var.project_name}-ecs-task-${var.environment}-${local.region}"
    Type = "ECSTask"
  })
}

# Task role policies for DynamoDB access
resource "aws_iam_role_policy" "ecs_task_dynamodb" {
  name = "${var.project_name}-ecs-task-dynamodb-${var.environment}"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          module.dynamodb.address_watchlist_table_arn,
          "${module.dynamodb.address_watchlist_table_arn}/index/*",
          module.dynamodb.suspicious_transactions_table_arn,
          "${module.dynamodb.suspicious_transactions_table_arn}/index/*",
          module.dynamodb.investigation_notes_table_arn,
          "${module.dynamodb.investigation_notes_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [var.kms_data_key_arn]
      }
    ]
  })
}

# CloudWatch Logs policy for task role
resource "aws_iam_role_policy" "ecs_task_logs" {
  name = "${var.project_name}-ecs-task-logs-${var.environment}"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/ecs/${var.project_name}-${var.environment}-*"
      }
    ]
  })
}

# ECR Repository Policy
data "aws_ecr_repository" "trm_blockexplorer" {
  name = "trm-blockexplorer"
}

resource "aws_ecr_repository_policy" "trm_blockexplorer" {
  repository = data.aws_ecr_repository.trm_blockexplorer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
      }
    ]
  })
}

# ECS Cluster Module
module "ecs_cluster" {
  source = "../../../modules/ecs"

  project_name              = var.project_name
  environment               = var.environment
  region                    = local.region
  vpc_id                    = module.networking.vpc_id
  enable_container_insights = true
  enable_fargate            = true
  enable_ec2                = false
  kms_key_arn              = var.kms_secrets_key_arn

  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 100
    }
  ]

  tags = local.common_tags
}

# Security Group for Public ALB
resource "aws_security_group" "public_alb" {
  name_prefix = "${var.project_name}-public-alb-sg-${var.environment}-"
  vpc_id      = module.networking.vpc_id
  description = "Security group for public-facing ALB"

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere (if using HTTPS)
  ingress {
    description = "HTTPS from Internet"
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
    Name = "${var.project_name}-public-alb-sg-${var.environment}"
  })
}

# Public Application Load Balancer for ECS service access
resource "aws_lb" "alb" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false  # Public-facing
  load_balancer_type = "application"
  subnets            = module.networking.public_subnet_ids  # Use public subnets
  security_groups    = [aws_security_group.public_alb.id]

  enable_deletion_protection = false
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb"
    Type = "ALB"
  })
}

# ALB Target Group for ECS Service (Fargate uses IP target type)
resource "aws_lb_target_group" "alb_ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-tg"
  port        = var.ecs_service_config.container_port
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"  # Required for Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/api/v1/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  deregistration_delay = 30

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-ecs-tg"
  })
}

# ALB Listener for HTTP traffic (redirect to HTTPS)
resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener with ACM certificate
resource "aws_lb_listener" "alb_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.alb.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_ecs.arn
  }

  depends_on = [aws_acm_certificate_validation.alb]
}

# Security Group Rule to allow ECS to receive traffic from public ALB
resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = var.ecs_service_config.container_port
  to_port                  = var.ecs_service_config.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_alb.id
  security_group_id        = module.security.ecs_security_group_id
  description              = "Allow traffic from public ALB"
}

# Use existing CloudWatch Log Group for ECS
# The log group is automatically created by ECS when the first task runs
locals {
  ecs_log_group_name = "/ecs/${var.project_name}-${var.environment}-api"
}

# ECS Service Module
module "ecs_service" {
  source = "../../../modules/ecs-service"

  project_name             = var.project_name
  environment              = var.environment
  service_name             = "api"
  cluster_id               = module.ecs_cluster.cluster_id
  cluster_name             = module.ecs_cluster.cluster_name
  task_execution_role_arn  = aws_iam_role.ecs_task_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  # Parse container image URI to separate image and tag
  container_image = split(":", var.container_image_uri)[0]
  image_tag       = length(split(":", var.container_image_uri)) > 1 ? split(":", var.container_image_uri)[1] : "latest"

  cpu           = tostring(var.ecs_service_config.cpu)
  memory        = tostring(var.ecs_service_config.memory)
  container_port = var.ecs_service_config.container_port
  desired_count = var.ecs_service_config.desired_count

  log_group_name = local.ecs_log_group_name

  environment_variables = [
    {
      name  = "PROJECT_NAME"
      value = var.project_name
    },
    {
      name  = "ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "REGION"
      value = local.region
    },
    {
      name  = "ADDRESS_WATCHLIST_TABLE"
      value = module.dynamodb.address_watchlist_table_name
    },
    {
      name  = "SUSPICIOUS_TRANSACTIONS_TABLE"
      value = module.dynamodb.suspicious_transactions_table_name
    },
    {
      name  = "INVESTIGATION_NOTES_TABLE"
      value = module.dynamodb.investigation_notes_table_name
    },
    {
      name  = "KMS_DATA_KEY_ARN"
      value = var.kms_data_key_arn
    },
    {
      name  = "KMS_SECRETS_KEY_ARN"
      value = var.kms_secrets_key_arn
    },
    {
      name  = "USE_MOCK_BLOCKCHAIN"
      value = tostring(var.use_mock_blockchain)
    }
  ]

  secrets = [
    {
      name      = "INFURA_API_KEY"
      valueFrom = "/${var.project_name}/${var.environment}/global/secrets/infura_api_key"
    },
    {
      name      = "INFURA_API_SECRET"
      valueFrom = "/${var.project_name}/${var.environment}/global/secrets/infura_api_secret"
    }
  ]

  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.ecs_cluster.service_security_group_id]

  # Load balancer configuration - ALB target group
  load_balancer_config = {
    target_group_arn = aws_lb_target_group.alb_ecs.arn
  }

  # Deployment configuration
  deployment_configuration = {
    maximum_percent          = 200
    minimum_healthy_percent  = 100
    enable_circuit_breaker   = true
    enable_rollback         = true
  }

  # Auto-scaling configuration
  enable_autoscaling = var.ecs_service_config.enable_autoscaling
  autoscaling_config = {
    min_capacity     = var.ecs_service_config.min_capacity
    max_capacity     = var.ecs_service_config.max_capacity
    cpu_target_value = var.ecs_service_config.target_cpu_utilization
  }

  enable_execute_command = var.environment == "dev" ? true : false

  tags = local.common_tags
}

# API Gateway removed - using NLB directly

# ACM Certificate for ALB HTTPS
resource "aws_acm_certificate" "alb" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}",
    "api.${var.domain_name}"
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 record for ACM certificate validation
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

# Route53 A record for ALB (root domain)
resource "aws_route53_record" "alb_root" {
  count = var.hosted_zone_id != null ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

# Route53 A record for ALB (api subdomain)
resource "aws_route53_record" "alb_api" {
  count = var.hosted_zone_id != null ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

# Monitoring Module (ECS-focused)
module "monitoring" {
  source = "../../../modules/monitoring"

  project_name                  = var.project_name
  environment                   = var.environment
  region                        = local.region
  lambda_function_names         = [] # No Lambda functions
  api_gateway_id                = null
  api_gateway_stage_name        = null
  enable_api_gateway_monitoring = false
  dynamodb_table_names          = values(module.dynamodb.table_names)
  create_dashboard              = var.monitoring_config.create_dashboard
  enable_detailed_monitoring    = var.monitoring_config.enable_detailed_monitoring
  log_retention_days            = var.monitoring_config.log_retention_days
  alarm_email_endpoints         = var.monitoring_config.alarm_email_endpoints
  sns_topic_arns                = var.global_alarms_topic_arn != null ? [var.global_alarms_topic_arn] : []

  custom_metrics = {
    blockchain_api_errors = {
      metric_name         = "blockchain_api_errors"
      namespace           = "${var.project_name}/Application"
      statistic           = "Sum"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 10
      evaluation_periods  = 2
      period              = 300
      alarm_description   = "High number of blockchain API errors"
    }

    cache_hit_rate = {
      metric_name         = "cache_hit_rate"
      namespace           = "${var.project_name}/Application"
      statistic           = "Average"
      comparison_operator = "LessThanThreshold"
      threshold           = 80
      evaluation_periods  = 3
      period              = 300
      alarm_description   = "Low cache hit rate"
    }

    ecs_service_cpu_utilization = {
      metric_name         = "CPUUtilization"
      namespace           = "AWS/ECS"
      statistic           = "Average"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      period              = 300
      alarm_description   = "High ECS service CPU utilization"
      dimensions = {
        ServiceName = module.ecs_service.service_name
        ClusterName = module.ecs_cluster.cluster_name
      }
    }

    ecs_service_memory_utilization = {
      metric_name         = "MemoryUtilization"
      namespace           = "AWS/ECS"
      statistic           = "Average"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      period              = 300
      alarm_description   = "High ECS service memory utilization"
      dimensions = {
        ServiceName = module.ecs_service.service_name
        ClusterName = module.ecs_cluster.cluster_name
      }
    }

    alb_response_time = {
      metric_name         = "TargetResponseTime"
      namespace           = "AWS/ApplicationELB"
      statistic           = "Average"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 1.0
      evaluation_periods  = 2
      period              = 300
      alarm_description   = "High ALB response time"
      dimensions = {
        LoadBalancer = aws_lb.alb.arn
      }
    }

    alb_unhealthy_hosts = {
      metric_name         = "UnHealthyHostCount"
      namespace           = "AWS/ApplicationELB"
      statistic           = "Average"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 0
      evaluation_periods  = 2
      period              = 300
      alarm_description   = "ALB has unhealthy targets"
      dimensions = {
        TargetGroup  = aws_lb_target_group.alb_ecs.arn
        LoadBalancer = aws_lb.alb.arn
      }
    }
  }

  tags = local.common_tags
}

# SSM Parameters for Application Configuration
resource "aws_ssm_parameter" "app_config" {
  for_each = {
    log_level           = "INFO"
    cache_ttl_minutes   = "5"
    api_timeout_seconds = "30"
    blockchain_provider = "infura"
    enable_tracing      = "true"
    max_retry_attempts  = "3"
  }

  name  = "/${var.project_name}/${var.environment}/${local.region}/config/${each.key}"
  type  = "String"
  value = each.value

  tags = local.common_tags
}

# SSM Parameters for Secrets (placeholder - actual values set outside Terraform)
resource "aws_ssm_parameter" "app_secrets" {
  for_each = toset([
    "infura_api_key",
    "infura_api_secret"
  ])

  name   = "/${var.project_name}/${var.environment}/global/secrets/${each.value}"
  type   = "SecureString"
  value  = "placeholder-${each.value}" # Will be updated outside Terraform
  key_id = var.kms_secrets_key_arn != "" ? var.kms_secrets_key_arn : null

  tags = local.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}
