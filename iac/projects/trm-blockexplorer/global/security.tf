# Global Security Resources

# Create KMS keys directly for global resources
# Secrets encryption key
resource "aws_kms_key" "secrets" {
  description             = "${var.project_name} secrets encryption key - ${var.environment}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.environment == "prod"
  multi_region            = var.enable_multi_region_kms

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-secrets-global"
    Type = "secrets"
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-${var.environment}-secrets-global"
  target_key_id = aws_kms_key.secrets.key_id
}

# Data encryption key
resource "aws_kms_key" "data" {
  description             = "${var.project_name} data encryption key - ${var.environment}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.environment == "prod"
  multi_region            = var.enable_multi_region_kms

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = [
            "logs.amazonaws.com",
            "logs.us-east-1.amazonaws.com",
            "logs.us-east-2.amazonaws.com",
            "logs.us-west-1.amazonaws.com",
            "logs.us-west-2.amazonaws.com",
            "logs.eu-west-1.amazonaws.com",
            "logs.eu-central-1.amazonaws.com",
            "logs.ap-southeast-1.amazonaws.com",
            "logs.ap-southeast-2.amazonaws.com",
            "logs.ap-northeast-1.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
      {
        Sid    = "Allow ECS Services"
        Effect = "Allow"
        Principal = {
          Service = [
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow services to use the key via grants"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "logs.us-west-2.amazonaws.com",
              "logs.us-east-1.amazonaws.com",
              "logs.us-east-2.amazonaws.com",
              "ecs.us-west-2.amazonaws.com",
              "ecs.us-east-1.amazonaws.com",
              "ecs.us-east-2.amazonaws.com"
            ]
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-data-global"
    Type = "data"
  })
}

resource "aws_kms_alias" "data" {
  name          = "alias/${var.project_name}-${var.environment}-data-global"
  target_key_id = aws_kms_key.data.key_id
}

# Logs encryption key
resource "aws_kms_key" "logs" {
  description             = "${var.project_name} logs encryption key - ${var.environment}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.environment == "prod"
  multi_region            = var.enable_multi_region_kms

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-logs-global"
    Type = "logs"
  })
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project_name}-${var.environment}-logs-global"
  target_key_id = aws_kms_key.logs.key_id
}

# Module outputs for compatibility
locals {
  security_global = {
    kms_secrets_key_id  = aws_kms_key.secrets.id
    kms_secrets_key_arn = aws_kms_key.secrets.arn
    kms_data_key_id     = aws_kms_key.data.id
    kms_data_key_arn    = aws_kms_key.data.arn
    kms_logs_key_id     = aws_kms_key.logs.id
    kms_logs_key_arn    = aws_kms_key.logs.arn
  }
}
