# Security S3 Buckets Configuration

# S3 bucket for security findings (GuardDuty, Inspector)
resource "aws_s3_bucket" "security_findings" {
  bucket = "${local.account_id}-security-findings"

  tags = merge(local.common_tags, {
    Name               = "${local.account_id}-security-findings"
    Purpose            = "SecurityFindings"
    DataClassification = "confidential"
  })
}

# S3 bucket versioning for security findings
resource "aws_s3_bucket_versioning" "security_findings" {
  bucket = aws_s3_bucket.security_findings.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption for security findings
resource "aws_s3_bucket_server_side_encryption_configuration" "security_findings" {
  bucket = aws_s3_bucket.security_findings.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.security.arn
    }
    bucket_key_enabled = true
  }
}

# S3 bucket lifecycle for security findings
resource "aws_s3_bucket_lifecycle_configuration" "security_findings" {
  bucket = aws_s3_bucket.security_findings.id

  rule {
    id     = "expire-old-findings"
    status = "Enabled"

    filter {}

    expiration {
      days = var.security_findings_retention_days
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

# S3 bucket for SBOM exports
resource "aws_s3_bucket" "sbom_exports" {
  bucket = "${local.account_id}-sbom-exports"

  tags = merge(local.common_tags, {
    Name               = "${local.account_id}-sbom-exports"
    Purpose            = "SBOM"
    DataClassification = "internal"
    Compliance         = "required"
  })
}

# S3 bucket versioning for SBOM exports
resource "aws_s3_bucket_versioning" "sbom_exports" {
  bucket = aws_s3_bucket.sbom_exports.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption for SBOM exports
resource "aws_s3_bucket_server_side_encryption_configuration" "sbom_exports" {
  bucket = aws_s3_bucket.sbom_exports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.security.arn
    }
    bucket_key_enabled = true
  }
}

# S3 bucket lifecycle for SBOM exports
resource "aws_s3_bucket_lifecycle_configuration" "sbom_exports" {
  bucket = aws_s3_bucket.sbom_exports.id

  rule {
    id     = "archive-old-sboms"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = var.sbom_retention_days
    }
  }
}

# S3 bucket for security reports and aggregated data
resource "aws_s3_bucket" "security_reports" {
  bucket = "${local.account_id}-security-reports"

  tags = merge(local.common_tags, {
    Name               = "${local.account_id}-security-reports"
    Purpose            = "SecurityReports"
    DataClassification = "internal"
  })
}

# S3 bucket versioning for security reports
resource "aws_s3_bucket_versioning" "security_reports" {
  bucket = aws_s3_bucket.security_reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption for security reports
resource "aws_s3_bucket_server_side_encryption_configuration" "security_reports" {
  bucket = aws_s3_bucket.security_reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.security.arn
    }
    bucket_key_enabled = true
  }
}

# S3 bucket policy for security findings
resource "aws_s3_bucket_policy" "security_findings" {
  bucket = aws_s3_bucket.security_findings.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.security_findings.arn,
          "${aws_s3_bucket.security_findings.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowGuardDutyAccess"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.security_findings.arn,
          "${aws_s3_bucket.security_findings.arn}/*"
        ]
      },
      {
        Sid    = "AllowEventBridgeAccess"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.security_findings.arn,
          "${aws_s3_bucket.security_findings.arn}/*"
        ]
      }
    ]
  })
}

# S3 bucket policy for SBOM exports
resource "aws_s3_bucket_policy" "sbom_exports" {
  bucket = aws_s3_bucket.sbom_exports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.sbom_exports.arn,
          "${aws_s3_bucket.sbom_exports.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowInspectorAccess"
        Effect = "Allow"
        Principal = {
          Service = "inspector2.amazonaws.com"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.sbom_exports.arn,
          "${aws_s3_bucket.sbom_exports.arn}/*"
        ]
      }
    ]
  })
}

# S3 bucket policy for security reports
resource "aws_s3_bucket_policy" "security_reports" {
  bucket = aws_s3_bucket.security_reports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.security_reports.arn,
          "${aws_s3_bucket.security_reports.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Block public access for all security buckets
resource "aws_s3_bucket_public_access_block" "security_reports" {
  bucket = aws_s3_bucket.security_reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS key for security services
resource "aws_kms_key" "security" {
  description             = "KMS key for security services (GuardDuty, Inspector, etc.)"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow security services to use the key"
        Effect = "Allow"
        Principal = {
          Service = [
            "guardduty.amazonaws.com",
            "inspector2.amazonaws.com",
            "events.amazonaws.com",
            "s3.amazonaws.com"
          ]
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
    Name = "security-services-key"
  })
}

# KMS key alias
resource "aws_kms_alias" "security" {
  name          = "alias/security-services"
  target_key_id = aws_kms_key.security.key_id
}

# KMS key for CloudWatch Logs (used by ECS)
resource "aws_kms_key" "logs" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.primary_region}.amazonaws.com"
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
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.primary_region}:${local.account_id}:*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name    = "cloudwatch-logs-encryption"
    Purpose = "CloudWatchLogs"
  })
}

resource "aws_kms_alias" "logs" {
  name          = "alias/cloudwatch-logs"
  target_key_id = aws_kms_key.logs.key_id
}

# KMS key for CloudWatch Logs in secondary region
resource "aws_kms_key" "logs_secondary" {
  count = var.enable_multi_region_guardduty ? 1 : 0

  provider = aws.secondary

  description             = "KMS key for CloudWatch Logs encryption (secondary region)"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.secondary_region}.amazonaws.com"
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
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.secondary_region}:${local.account_id}:*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name    = "cloudwatch-logs-encryption-secondary"
    Purpose = "CloudWatchLogs"
    Region  = "Secondary"
  })
}

resource "aws_kms_alias" "logs_secondary" {
  count = var.enable_multi_region_guardduty ? 1 : 0

  provider      = aws.secondary
  name          = "alias/cloudwatch-logs"
  target_key_id = aws_kms_key.logs_secondary[0].key_id
}

# SNS topic for security alerts
resource "aws_sns_topic" "security_alerts" {
  count = var.notification_email != "" ? 1 : 0

  name              = "security-alerts"
  kms_master_key_id = aws_kms_key.security.id

  tags = merge(local.common_tags, {
    Name = "security-alerts"
  })
}

# SNS topic subscription for email notifications
resource "aws_sns_topic_subscription" "security_alerts_email" {
  count = var.notification_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.security_alerts[0].arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# SNS topic policy
resource "aws_sns_topic_policy" "security_alerts" {
  count = var.notification_email != "" ? 1 : 0

  arn = aws_sns_topic.security_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToPublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.security_alerts[0].arn
      }
    ]
  })
}