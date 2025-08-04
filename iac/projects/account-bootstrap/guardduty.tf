# GuardDuty Configuration - Threat Detection Service

# Enable GuardDuty in primary region
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = var.guardduty_finding_publishing_frequency

  # Enable S3 protection
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false # Not needed for serverless
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = false # Not needed for serverless
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "trm-guardduty-detector-primary"
  })
}

# Enable GuardDuty in secondary region (if multi-region is enabled)
resource "aws_guardduty_detector" "secondary" {
  count    = var.enable_guardduty && var.enable_multi_region_guardduty ? 1 : 0
  provider = aws.secondary

  enable                       = true
  finding_publishing_frequency = var.guardduty_finding_publishing_frequency

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = false
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "trm-guardduty-detector-secondary"
  })
}

# S3 bucket for GuardDuty findings export
resource "aws_s3_bucket_public_access_block" "guardduty_findings" {
  bucket = aws_s3_bucket.security_findings.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# GuardDuty publishing destination (primary region)
resource "aws_guardduty_publishing_destination" "s3" {
  count = var.enable_guardduty ? 1 : 0

  detector_id     = aws_guardduty_detector.main[0].id
  destination_arn = aws_s3_bucket.security_findings.arn
  kms_key_arn     = aws_kms_key.security.arn

  depends_on = [
    aws_s3_bucket_policy.security_findings
  ]
}

# EventBridge rule for high-severity GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_high_severity" {
  count = var.enable_guardduty && var.notification_email != "" ? 1 : 0

  name        = "guardduty-high-severity-findings"
  description = "Capture high severity GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        { numeric = [">=", 7] } # High severity: 7-8.9, Critical: 9+
      ]
    }
  })

  tags = local.common_tags
}

# EventBridge target for SNS notifications
resource "aws_cloudwatch_event_target" "guardduty_sns" {
  count = var.enable_guardduty && var.notification_email != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.guardduty_high_severity[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts[0].arn
}

# IAM role for GuardDuty to publish findings
resource "aws_iam_role" "guardduty_publisher" {
  count = var.enable_guardduty ? 1 : 0

  name = "guardduty-s3-publisher"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for GuardDuty to write to S3
resource "aws_iam_role_policy" "guardduty_s3_policy" {
  count = var.enable_guardduty ? 1 : 0

  name = "guardduty-s3-write"
  role = aws_iam_role.guardduty_publisher[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.security_findings.arn,
          "${aws_s3_bucket.security_findings.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.security.arn
      }
    ]
  })
}

# GuardDuty threat intelligence set (optional - for custom threat lists)
# Uncomment and configure if you have custom IP threat lists
/*
resource "aws_guardduty_threatintelset" "custom" {
  count = var.enable_guardduty ? 1 : 0

  activate    = true
  detector_id = aws_guardduty_detector.main[0].id
  format      = "TXT"
  location    = "s3://${aws_s3_bucket.security_findings.id}/threat-intel/ip-list.txt"
  name        = "custom-threat-intel"

  tags = local.common_tags
}
*/

# GuardDuty trusted IP set (optional - for known good IPs)
# Uncomment and configure if you have trusted IPs to whitelist
/*
resource "aws_guardduty_ipset" "trusted" {
  count = var.enable_guardduty ? 1 : 0

  activate    = true
  detector_id = aws_guardduty_detector.main[0].id
  format      = "TXT"
  location    = "s3://${aws_s3_bucket.security_findings.id}/trusted-ips/ip-list.txt"
  name        = "trusted-ip-list"

  tags = local.common_tags
}
*/