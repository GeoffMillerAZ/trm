# KMS Keys for Encryption

# KMS Key for Secrets (SSM Parameters)
resource "aws_kms_key" "secrets" {
  count = var.create_kms_keys ? 1 : 0

  description              = "KMS key for encrypting secrets and SSM parameters"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 7
  multi_region             = var.enable_multi_region_keys

  policy = data.aws_iam_policy_document.kms_secrets_policy[0].json

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-${var.kms_key_aliases.secrets}-${var.environment}"
    Purpose     = "secrets"
    MultiRegion = var.enable_multi_region_keys
  })
}

resource "aws_kms_alias" "secrets" {
  count = var.create_kms_keys ? 1 : 0

  name          = "alias/${var.project_name}-${var.kms_key_aliases.secrets}-${var.environment}"
  target_key_id = aws_kms_key.secrets[0].key_id
}

data "aws_iam_policy_document" "kms_secrets_policy" {
  count = var.create_kms_keys ? 1 : 0

  # Allow root account full access
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow Lambda service to use the key
  statement {
    sid    = "AllowLambdaAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # Allow SSM service to use the key
  statement {
    sid    = "AllowSSMAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
  }
}

# KMS Key for Data (DynamoDB, S3)
resource "aws_kms_key" "data" {
  count = var.create_kms_keys ? 1 : 0

  description              = "KMS key for encrypting application data"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 7
  multi_region             = var.enable_multi_region_keys

  policy = data.aws_iam_policy_document.kms_data_policy[0].json

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-${var.kms_key_aliases.data}-${var.environment}"
    Purpose     = "data"
    MultiRegion = var.enable_multi_region_keys
  })
}

resource "aws_kms_alias" "data" {
  count = var.create_kms_keys ? 1 : 0

  name          = "alias/${var.project_name}-${var.kms_key_aliases.data}-${var.environment}"
  target_key_id = aws_kms_key.data[0].key_id
}

data "aws_iam_policy_document" "kms_data_policy" {
  count = var.create_kms_keys ? 1 : 0

  # Allow root account full access
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow DynamoDB service to use the key
  statement {
    sid    = "AllowDynamoDBAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["dynamodb.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  # Allow S3 service to use the key
  statement {
    sid    = "AllowS3Access"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

# KMS Key for Logs (CloudWatch Logs)
resource "aws_kms_key" "logs" {
  count = var.create_kms_keys ? 1 : 0

  description              = "KMS key for encrypting CloudWatch logs"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 7
  multi_region             = var.enable_multi_region_keys

  policy = data.aws_iam_policy_document.kms_logs_policy[0].json

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-${var.kms_key_aliases.logs}-${var.environment}"
    Purpose     = "logs"
    MultiRegion = var.enable_multi_region_keys
  })
}

resource "aws_kms_alias" "logs" {
  count = var.create_kms_keys ? 1 : 0

  name          = "alias/${var.project_name}-${var.kms_key_aliases.logs}-${var.environment}"
  target_key_id = aws_kms_key.logs[0].key_id
}

data "aws_iam_policy_document" "kms_logs_policy" {
  count = var.create_kms_keys ? 1 : 0

  # Allow root account full access
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow CloudWatch Logs service to use the key
  statement {
    sid    = "AllowCloudWatchLogsAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*"]
    }
  }
}