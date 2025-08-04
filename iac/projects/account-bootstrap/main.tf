# Account Bootstrap - Main Configuration
# This project sets up account-wide security services that are shared across all environments

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration should be provided via -backend-config
    # Example:
    # bucket         = "trm-terraform-state-{account-id}"
    # key            = "account-bootstrap/terraform.tfstate"
    # region         = "us-west-2"
    # dynamodb_table = "terraform-state-locks"
    # encrypt        = true
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project     = "AccountBootstrap"
      Purpose     = "Security"
      ManagedBy   = "terraform"
      Environment = "account-wide"
    }
  }
}

# Secondary region provider for multi-region services
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region

  default_tags {
    tags = {
      Project     = "AccountBootstrap"
      Purpose     = "Security"
      ManagedBy   = "terraform"
      Environment = "account-wide"
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS partition
data "aws_partition" "current" {}

# Local variables
locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # Common tags for all resources
  common_tags = {
    AccountId          = local.account_id
    SecurityService    = "true"
    ComplianceRequired = "true"
    DataClassification = "internal"
  }
}

# =============================================================================
# FUTURE ENHANCEMENT: AWS Security Hub Integration
# =============================================================================
# Security Hub provides a comprehensive view of your security state within AWS
# and helps you check your environment against security industry standards.
#
# When you're ready to enable Security Hub for a single pane of glass view
# of all security findings, uncomment the configuration below.
#
# BENEFITS:
# - Centralized security findings from GuardDuty, Inspector, and other services
# - Compliance checking against standards (CIS, PCI-DSS, AWS Foundational)
# - Custom insights for tracking specific security concerns
# - Integration with ticketing systems and SIEM solutions
#
# PREREQUISITES:
# 1. Enable AWS Config in all regions where you want Security Hub
# 2. Ensure GuardDuty and Inspector are already enabled (done above)
# 3. Have appropriate IAM permissions for Security Hub
#
# COST CONSIDERATIONS:
# - $0.001 per finding ingested (first 10,000 findings/month free)
# - $0.00003 per compliance check/month
# - Additional costs for integrated services (Config, GuardDuty, etc.)
#
# =============================================================================

/*
# Step 1: Enable AWS Config (prerequisite for Security Hub)
module "config" {
  source = "./modules/config"
  
  enable_config_recorder     = true
  enable_config_rules       = true
  config_bucket_name        = "${local.account_id}-config-logs"
  
  # Record all supported resource types
  recording_group = {
    all_supported = true
    include_global_resource_types = true
  }
  
  tags = local.common_tags
}

# Step 2: Enable Security Hub
resource "aws_securityhub_account" "main" {
  depends_on = [
    aws_guardduty_detector.main,
    aws_inspector2_enabler.main,
    module.config
  ]
}

# Step 3: Enable Security Standards
resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:${local.partition}:securityhub:${var.primary_region}::standards/cis-aws-foundations-benchmark/v/1.4.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:${local.partition}:securityhub:${var.primary_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# Step 4: Enable Product Integrations
resource "aws_securityhub_product_subscription" "guardduty" {
  product_arn = "arn:${local.partition}:securityhub:${var.primary_region}::product/aws/guardduty"
  depends_on  = [aws_securityhub_account.main]
}

resource "aws_securityhub_product_subscription" "inspector" {
  product_arn = "arn:${local.partition}:securityhub:${var.primary_region}::product/aws/inspector"
  depends_on  = [aws_securityhub_account.main]
}

# Step 5: Create Custom Insights for Lambda Security
resource "aws_securityhub_insight" "lambda_vulnerabilities" {
  filters {
    product_arn {
      comparison = "EQUALS"
      value      = "arn:${local.partition}:securityhub:${var.primary_region}::product/aws/inspector"
    }
    
    resource_type {
      comparison = "EQUALS"
      value      = "AwsLambdaFunction"
    }
    
    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
  }
  
  group_by_attribute = "ResourceId"
  name              = "Critical Lambda Vulnerabilities"
}

resource "aws_securityhub_insight" "high_severity_findings" {
  filters {
    severity_label {
      comparison = "EQUALS"
      value      = "HIGH"
    }
    
    workflow_status {
      comparison = "EQUALS"
      value      = "NEW"
    }
  }
  
  group_by_attribute = "ProductName"
  name              = "High Severity Findings by Product"
}

# Step 6: Configure Finding Aggregation for Multi-Region
resource "aws_securityhub_finding_aggregator" "main" {
  linking_mode = "ALL_REGIONS"
  
  depends_on = [aws_securityhub_account.main]
}

# Step 7: Create SNS Topic for Critical Findings
resource "aws_sns_topic" "security_hub_critical" {
  name              = "security-hub-critical-findings"
  kms_master_key_id = aws_kms_key.security.id
  
  tags = local.common_tags
}

# Step 8: EventBridge Rule for Critical Security Hub Findings
resource "aws_cloudwatch_event_rule" "security_hub_critical" {
  name        = "security-hub-critical-findings"
  description = "Capture critical findings from Security Hub"
  
  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL"]
        }
        Workflow = {
          Status = ["NEW"]
        }
      }
    }
  })
  
  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "security_hub_sns" {
  rule      = aws_cloudwatch_event_rule.security_hub_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_hub_critical.arn
}

# Step 9: Security Hub Outputs
output "security_hub_enabled" {
  value       = true
  description = "Security Hub is enabled for centralized findings"
}

output "security_hub_arn" {
  value       = aws_securityhub_account.main.arn
  description = "ARN of the Security Hub account"
}

output "security_hub_dashboard_url" {
  value       = "https://console.aws.amazon.com/securityhub/home?region=${var.primary_region}#/summary"
  description = "URL to Security Hub dashboard"
}

output "security_standards_enabled" {
  value = {
    cis_benchmark           = aws_securityhub_standards_subscription.cis.standards_arn
    aws_foundational       = aws_securityhub_standards_subscription.aws_foundational.standards_arn
  }
  description = "Enabled security standards in Security Hub"
}

# Step 10: Integration with CI/CD
# Add this IAM policy to your GitHub Actions role for Security Hub access:
resource "aws_iam_role_policy" "github_actions_security_hub" {
  name = "github-actions-security-hub-access"
  role = aws_iam_role.github_actions_security.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "securityhub:GetFindings",
          "securityhub:BatchImportFindings",
          "securityhub:BatchUpdateFindings"
        ]
        Resource = "*"
      }
    ]
  })
}
*/