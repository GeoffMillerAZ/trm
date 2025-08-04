# Production Environment - Global Resources

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration will be provided via -backend-config
    # bucket         = "trm-blockexplorer-terraform-state-{account-id}-us-west-2"
    # key            = "environments/prod/global/terraform.tfstate"
    # region         = "us-west-2"
    # dynamodb_table = "trm-blockexplorer-terraform-locks"
    # encrypt        = true
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project        = var.project_name
      Environment    = var.environment
      ManagedBy      = "terraform"
      Repository     = "trm-blockexplorer"
      Layer          = "global"
      CriticalSystem = "true"
    }
  }
}

# Global Project Module
module "global" {
  source = "../../../projects/trm-blockexplorer/global"

  project_name       = var.project_name
  environment        = var.environment
  primary_region     = var.primary_region
  secondary_region   = var.secondary_region
  domain_name        = var.domain_name
  hosted_zone_id     = var.hosted_zone_id
  create_hosted_zone = var.create_hosted_zone

  enable_multi_region  = var.enable_multi_region
  health_check_regions = var.health_check_regions

  # Production-specific settings
  enable_multi_region_kms = true # Multi-region KMS for production
  kms_key_deletion_window = 30   # Longer deletion window for production

  alarm_email_endpoints               = var.alarm_email_endpoints
  enable_cross_region_log_replication = true # Enabled for production

  tags = var.additional_tags
}