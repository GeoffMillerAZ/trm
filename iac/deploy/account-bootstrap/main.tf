# Account Bootstrap Deployment
# This must be deployed manually before any other infrastructure

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration is provided via backend-config.hcl
  # This deployment has been migrated to use S3 backend
  backend "s3" {
    # Configuration loaded from backend-config.hcl file
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = var.project_name
      ManagedBy  = "terraform"
      Repository = "trm-blockexplorer"
      Layer      = "account-bootstrap"
    }
  }
}

# Account Bootstrap Module
module "account_bootstrap" {
  source = "../../projects/account-bootstrap"

  primary_region   = var.aws_region
  secondary_region = var.secondary_region

  # Security Configuration
  enable_guardduty              = var.enable_guardduty
  enable_inspector              = var.enable_inspector
  enable_security_hub           = var.enable_security_hub
  enable_multi_region_guardduty = var.enable_multi_region_guardduty

  # Inspector Scanning Options
  enable_lambda_scanning = var.enable_lambda_scanning
  enable_ec2_scanning    = var.enable_ec2_scanning
  enable_ecr_scanning    = var.enable_ecr_scanning

  # Retention Settings
  security_findings_retention_days = var.security_findings_retention_days
  sbom_retention_days              = var.sbom_retention_days

  # Notifications
  notification_email = var.notification_email

  # GuardDuty Configuration
  guardduty_finding_publishing_frequency = var.guardduty_finding_publishing_frequency

  # DNS Configuration
  root_domain         = var.root_domain
  subdomain_prefix    = var.subdomain_prefix
  create_dev_zone     = var.create_dev_zone
  create_staging_zone = var.create_staging_zone

  tags = var.additional_tags
}