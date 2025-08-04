# IAM Roles for Security Services

# Cross-service security scanner role
resource "aws_iam_role" "security_scanner" {
  count = (var.enable_inspector || var.enable_codeguru) ? 1 : 0

  name = "security-scanner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = compact([
            var.enable_codeguru ? "codeguru-reviewer.amazonaws.com" : "",
            var.enable_inspector ? "inspector2.amazonaws.com" : ""
          ])
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "security-scanner"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "security-scanner-role"
  })
}

# Policy for security scanner role
resource "aws_iam_role_policy" "security_scanner_policy" {
  count = (var.enable_inspector || var.enable_codeguru) ? 1 : 0

  name = "security-scanner-policy"
  role = aws_iam_role.security_scanner[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:ListFunctions",
          "lambda:ListTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:${local.partition}:s3:::*-lambda-deployment*",
          "arn:${local.partition}:s3:::*-lambda-deployment*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:*:${local.account_id}:*"
      }
    ]
  })
}

# Role for Inspector to scan Lambda functions
resource "aws_iam_role" "inspector_lambda" {
  count = var.enable_inspector ? 1 : 0

  name = "inspector-lambda-scanner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "inspector2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "inspector-lambda-scanner-role"
  })
}

# Policy for Inspector Lambda scanning
resource "aws_iam_role_policy" "inspector_lambda_policy" {
  count = var.enable_inspector ? 1 : 0

  name = "inspector-lambda-scanner-policy"
  role = aws_iam_role.inspector_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:GetLayerVersion",
          "lambda:GetFunctionConfiguration",
          "lambda:ListFunctions",
          "lambda:ListLayers",
          "lambda:ListLayerVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:ExistingObjectTag/aws-inspector-scan" = "true"
          }
        }
      }
    ]
  })
}

# Role for GitHub Actions to assume for security scanning
resource "aws_iam_role" "github_actions_security" {
  name = "github-actions-security-scanner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:${local.partition}:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:*:ref:refs/heads/*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name    = "github-actions-security-scanner"
    Purpose = "CI/CD"
  })
}

# Policy for GitHub Actions security scanning
resource "aws_iam_role_policy" "github_actions_security_policy" {
  name = "github-actions-security-policy"
  role = aws_iam_role.github_actions_security.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codeguru-reviewer:ListRepositoryAssociations",
          "codeguru-reviewer:CreateCodeReview",
          "codeguru-reviewer:DescribeCodeReview",
          "codeguru-reviewer:ListRecommendations",
          "codeguru-security:CreateScan",
          "codeguru-security:GetScan",
          "codeguru-security:ListScans",
          "codeguru-security:GetFindings"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "inspector2:ListFindings",
          "inspector2:GetFindings",
          "inspector2:GetSbomExport",
          "inspector2:CreateSbomExport"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.security_findings.arn,
          "${aws_s3_bucket.security_findings.arn}/*",
          aws_s3_bucket.sbom_exports.arn,
          "${aws_s3_bucket.sbom_exports.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:ListFunctions"
        ]
        Resource = "arn:${local.partition}:lambda:*:${local.account_id}:function:trm-blockexplorer-*"
      }
    ]
  })
}

# Role for automated remediation (future use)
resource "aws_iam_role" "security_remediation" {
  name = "security-automated-remediation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "ssm.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name    = "security-automated-remediation"
    Purpose = "Remediation"
  })
}

# Attach AWS managed policies for Lambda execution
resource "aws_iam_role_policy_attachment" "sbom_lambda_basic" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.sbom_exporter_lambda[0].name
}

# Instance profile for EC2-based security scanning (if needed)
resource "aws_iam_instance_profile" "security_scanner" {
  count = (var.enable_inspector || var.enable_codeguru) ? 1 : 0

  name = "security-scanner-instance-profile"
  role = aws_iam_role.security_scanner[0].name
}

# Create the Lambda directory if it doesn't exist
resource "null_resource" "create_lambda_dir" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/lambda"
  }

  triggers = {
    always_run = timestamp()
  }
}