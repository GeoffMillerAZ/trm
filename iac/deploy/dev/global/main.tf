# Development Environment - Global Resources

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
    # key            = "environments/dev/global/terraform.tfstate"
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
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "trm-blockexplorer"
      Layer       = "global"
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

  # Development-specific settings (multi-region enabled for testing)
  enable_multi_region_kms = true # Enable multi-region KMS for testing active-active
  kms_key_deletion_window = 7    # Shorter deletion window for dev

  alarm_email_endpoints               = var.alarm_email_endpoints
  enable_cross_region_log_replication = true # Enable for multi-region testing

  tags = var.additional_tags
}