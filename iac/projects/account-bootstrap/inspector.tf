# AWS Inspector v2 Configuration - Vulnerability Scanning

# Enable Inspector v2 in the account
resource "aws_inspector2_enabler" "main" {
  count = var.enable_inspector ? 1 : 0

  account_ids = [local.account_id]
  resource_types = compact([
    var.enable_lambda_scanning ? "LAMBDA" : "",
    var.enable_ec2_scanning ? "EC2" : "",
    var.enable_ecr_scanning ? "ECR" : ""
  ])
}

# Enable Inspector v2 in secondary region if multi-region is enabled
resource "aws_inspector2_enabler" "secondary" {
  count    = var.enable_inspector && var.enable_multi_region_guardduty ? 1 : 0
  provider = aws.secondary

  account_ids = [local.account_id]
  resource_types = compact([
    var.enable_lambda_scanning ? "LAMBDA" : "",
    var.enable_ec2_scanning ? "EC2" : "",
    var.enable_ecr_scanning ? "ECR" : ""
  ])
}

# S3 bucket for SBOM exports
resource "aws_s3_bucket_public_access_block" "sbom_exports" {
  bucket = aws_s3_bucket.sbom_exports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# EventBridge rule for Inspector findings
resource "aws_cloudwatch_event_rule" "inspector_findings" {
  count = var.enable_inspector ? 1 : 0

  name        = "inspector-findings"
  description = "Capture Inspector v2 findings"

  event_pattern = jsonencode({
    source      = ["aws.inspector2"]
    detail-type = ["Inspector2 Finding"]
  })

  tags = local.common_tags
}

# EventBridge rule for high/critical Lambda vulnerabilities
resource "aws_cloudwatch_event_rule" "inspector_lambda_critical" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  name        = "inspector-lambda-critical-findings"
  description = "Capture critical Lambda vulnerabilities from Inspector"

  event_pattern = jsonencode({
    source      = ["aws.inspector2"]
    detail-type = ["Inspector2 Finding"]
    detail = {
      severity = ["CRITICAL", "HIGH"]
      resources = {
        type = ["AWS_LAMBDA_FUNCTION"]
      }
    }
  })

  tags = local.common_tags
}

# EventBridge target for Lambda critical findings to SNS
resource "aws_cloudwatch_event_target" "inspector_lambda_sns" {
  count = var.enable_inspector && var.enable_lambda_scanning && var.notification_email != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.inspector_lambda_critical[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts[0].arn
}

# Lambda function for automated SBOM exports
resource "aws_lambda_function" "sbom_exporter" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  filename         = data.archive_file.sbom_exporter[0].output_path
  function_name    = "inspector-sbom-exporter"
  role             = aws_iam_role.sbom_exporter_lambda[0].arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.sbom_exporter[0].output_base64sha256
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 512

  environment {
    variables = {
      SBOM_BUCKET   = aws_s3_bucket.sbom_exports.id
      KMS_KEY_ARN   = aws_kms_key.security.arn
      EXPORT_FORMAT = "CYCLONEDX_1_4" # or SPDX_2_3
    }
  }

  tags = merge(local.common_tags, {
    Name = "inspector-sbom-exporter"
  })
}

# Create Lambda deployment package for SBOM exporter
data "archive_file" "sbom_exporter" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/lambda/sbom_exporter.zip"

  source {
    content  = file("${path.module}/lambda/sbom_exporter.py")
    filename = "index.py"
  }
}

# EventBridge rule to trigger SBOM export weekly
resource "aws_cloudwatch_event_rule" "sbom_export_schedule" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  name                = "inspector-sbom-export-schedule"
  description         = "Trigger SBOM export weekly"
  schedule_expression = "rate(7 days)"

  tags = local.common_tags
}

# EventBridge target for SBOM export Lambda
resource "aws_cloudwatch_event_target" "sbom_export_lambda" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  rule      = aws_cloudwatch_event_rule.sbom_export_schedule[0].name
  target_id = "SBOMExportLambda"
  arn       = aws_lambda_function.sbom_exporter[0].arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge_sbom" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sbom_exporter[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sbom_export_schedule[0].arn
}

# IAM role for SBOM exporter Lambda
resource "aws_iam_role" "sbom_exporter_lambda" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  name = "inspector-sbom-exporter-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for SBOM exporter Lambda
resource "aws_iam_role_policy" "sbom_exporter_policy" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  name = "sbom-exporter-policy"
  role = aws_iam_role.sbom_exporter_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "inspector2:CreateSbomExport",
          "inspector2:ListFindings",
          "inspector2:GetSbomExport"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.sbom_exports.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.security.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:${var.primary_region}:${local.account_id}:*"
      }
    ]
  })
}

# Lambda function code for SBOM exporter
resource "local_file" "sbom_exporter_code" {
  count = var.enable_inspector && var.enable_lambda_scanning ? 1 : 0

  filename = "${path.module}/lambda/sbom_exporter.py"
  content  = <<-EOT
import json
import boto3
import os
from datetime import datetime

def handler(event, context):
    """Export SBOM for all Lambda functions"""
    
    inspector_client = boto3.client('inspector2')
    
    # Configuration from environment
    bucket_name = os.environ['SBOM_BUCKET']
    kms_key_arn = os.environ['KMS_KEY_ARN']
    export_format = os.environ.get('EXPORT_FORMAT', 'CYCLONEDX_1_4')
    
    try:
        # Create SBOM export for Lambda functions
        response = inspector_client.create_sbom_export(
            reportFormat=export_format,
            resourceFilterCriteria={
                'resourceType': [
                    {
                        'comparison': 'EQUALS',
                        'value': 'AWS_LAMBDA_FUNCTION'
                    }
                ]
            },
            s3Destination={
                'bucketName': bucket_name,
                'keyPrefix': f'lambda-sbom/{datetime.now().strftime("%Y/%m/%d")}/',
                'kmsKeyArn': kms_key_arn
            }
        )
        
        print(f"SBOM export initiated: {response['reportId']}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'SBOM export initiated successfully',
                'reportId': response['reportId']
            })
        }
        
    except Exception as e:
        print(f"Error creating SBOM export: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Failed to create SBOM export',
                'error': str(e)
            })
        }
EOT
}

# Lambda function to store Inspector findings in S3
resource "aws_lambda_function" "inspector_findings_to_s3" {
  count = var.enable_inspector ? 1 : 0

  filename      = data.archive_file.inspector_findings_handler[0].output_path
  function_name = "inspector-findings-to-s3"
  role          = aws_iam_role.inspector_findings_lambda[0].arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 128

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.security_findings.id
    }
  }

  tags = local.common_tags
}

# Archive for Lambda function
data "archive_file" "inspector_findings_handler" {
  count = var.enable_inspector ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/lambda-inspector-findings.zip"

  source {
    content  = <<-EOT
import json
import boto3
import os
from datetime import datetime

s3 = boto3.client('s3')

def handler(event, context):
    bucket = os.environ['BUCKET_NAME']
    timestamp = datetime.now().strftime('%Y/%m/%d/%H-%M-%S')
    
    # Store the finding
    key = f"inspector-findings/{timestamp}-{context.request_id}.json"
    
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=json.dumps(event, indent=2)
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Finding stored successfully'})
    }
EOT
    filename = "index.py"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "inspector_findings_lambda" {
  count = var.enable_inspector ? 1 : 0

  name = "inspector-findings-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "inspector_findings_lambda" {
  count = var.enable_inspector ? 1 : 0

  name = "inspector-findings-lambda-policy"
  role = aws_iam_role.inspector_findings_lambda[0].id

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
        Resource = "arn:${local.partition}:logs:${var.primary_region}:${local.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.security_findings.arn}/*"
      }
    ]
  })
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "inspector_findings" {
  count = var.enable_inspector ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inspector_findings_to_s3[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.inspector_findings[0].arn
}

# Store Inspector findings via Lambda
resource "aws_cloudwatch_event_target" "inspector_findings_lambda" {
  count = var.enable_inspector ? 1 : 0

  rule      = aws_cloudwatch_event_rule.inspector_findings[0].name
  target_id = "StoreInS3ViaLambda"
  arn       = aws_lambda_function.inspector_findings_to_s3[0].arn
}

# IAM role for EventBridge to write to S3
resource "aws_iam_role" "events_to_s3" {
  count = var.enable_inspector || var.enable_guardduty ? 1 : 0

  name = "eventbridge-to-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for EventBridge to write to S3
resource "aws_iam_role_policy" "events_to_s3_policy" {
  count = var.enable_inspector || var.enable_guardduty ? 1 : 0

  name = "events-to-s3-policy"
  role = aws_iam_role.events_to_s3[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.security_findings.arn,
          "${aws_s3_bucket.security_findings.arn}/*"
        ]
      }
    ]
  })
}