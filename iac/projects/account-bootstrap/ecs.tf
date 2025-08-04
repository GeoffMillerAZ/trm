# ECS Configuration for Account Bootstrap
# This creates ECS clusters per environment per region as defined in the architecture

# Create ECS clusters for each environment in primary region
locals {
  environments = ["dev", "prod"]
}

module "ecs_primary" {
  source   = "../../modules/ecs"
  for_each = toset(local.environments)

  project_name = "trm"
  environment  = each.value
  region       = var.primary_region

  # VPC will be created per environment deployment
  vpc_id = data.aws_vpc.default.id # Temporary until VPCs are created

  # Enable Container Insights for all clusters
  enable_container_insights = true

  # Enable Fargate for container workloads
  enable_fargate = true
  enable_ec2     = false

  # Service discovery namespace per environment
  enable_service_discovery    = true
  service_discovery_namespace = "${each.value}.internal"

  # Logging
  log_retention_days = each.value == "prod" ? 90 : 30
  kms_key_arn        = aws_kms_key.logs.arn

  # X-Ray tracing for observability
  enable_xray = true

  # Container port for ALB integration
  container_port = 8000

  # Don't create service-linked role (it's account-wide and may already exist)
  create_service_linked_role = false

  # Capacity provider strategy
  default_capacity_provider_strategy = each.value == "prod" ? [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 2 # Always run at least 2 tasks on standard Fargate
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 0
      base              = 0
    }
    ] : [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 2
      base              = 0
    },
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 2 # Minimum HA requirement
    }
  ]

  tags = merge(local.common_tags, {
    Purpose     = "ECSCluster"
    Environment = each.value
  })
}

# Create ECS clusters for each environment in secondary region
module "ecs_secondary" {
  source   = "../../modules/ecs"
  for_each = var.enable_multi_region_guardduty ? toset(local.environments) : toset([])

  providers = {
    aws = aws.secondary
  }

  project_name = "trm"
  environment  = each.value
  region       = var.secondary_region

  vpc_id = data.aws_vpc.default_secondary[0].id # Temporary until VPCs are created

  enable_container_insights = true
  enable_fargate            = true
  enable_ec2                = false

  enable_service_discovery    = true
  service_discovery_namespace = "${each.value}.internal"

  log_retention_days = each.value == "prod" ? 90 : 30
  kms_key_arn        = aws_kms_key.logs_secondary[0].arn

  enable_xray = true

  container_port = 8000

  create_service_linked_role = false

  # Same capacity provider strategy as primary
  default_capacity_provider_strategy = each.value == "prod" ? [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 2
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 0
      base              = 0
    }
    ] : [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 2
      base              = 0
    },
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 2
    }
  ]

  tags = merge(local.common_tags, {
    Purpose     = "ECSCluster"
    Environment = each.value
    Region      = "Secondary"
  })
}

# Data sources for default VPCs (temporary until proper VPCs are created)
data "aws_vpc" "default" {
  default = true
}

data "aws_vpc" "default_secondary" {
  count = var.enable_multi_region_guardduty ? 1 : 0

  provider = aws.secondary
  default  = true
}

# ECR Repository for container images
resource "aws_ecr_repository" "trm_blockexplorer" {
  name                 = "trm-blockexplorer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = merge(local.common_tags, {
    Purpose = "ContainerRegistry"
  })
}

# ECR lifecycle policy for image retention
resource "aws_ecr_lifecycle_policy" "trm_blockexplorer" {
  repository = aws_ecr_repository.trm_blockexplorer.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 development images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# KMS key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR repository encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRoot"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowECRUse"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Purpose = "ECREncryption"
  })
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/ecr-encryption"
  target_key_id = aws_kms_key.ecr.key_id
}

# Outputs for ECS clusters by environment
output "ecs_clusters_primary" {
  description = "Map of ECS cluster details by environment in primary region"
  value = {
    for env, cluster in module.ecs_primary : env => {
      cluster_id                     = cluster.cluster_id
      cluster_arn                    = cluster.cluster_arn
      task_execution_role_arn        = cluster.task_execution_role_arn
      task_role_arn                  = cluster.task_role_arn
      service_discovery_namespace_id = cluster.service_discovery_namespace_id
      service_security_group_id      = cluster.service_security_group_id
    }
  }
}

output "ecs_clusters_secondary" {
  description = "Map of ECS cluster details by environment in secondary region"
  value = var.enable_multi_region_guardduty ? {
    for env, cluster in module.ecs_secondary : env => {
      cluster_id                     = cluster.cluster_id
      cluster_arn                    = cluster.cluster_arn
      task_execution_role_arn        = cluster.task_execution_role_arn
      task_role_arn                  = cluster.task_role_arn
      service_discovery_namespace_id = cluster.service_discovery_namespace_id
      service_security_group_id      = cluster.service_security_group_id
    }
  } : {}
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for container images"
  value       = aws_ecr_repository.trm_blockexplorer.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.trm_blockexplorer.arn
}
