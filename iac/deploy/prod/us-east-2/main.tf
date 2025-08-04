# Production Environment - US East 2 Regional Resources (Secondary)

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
    # key            = "environments/prod/us-east-2/terraform.tfstate"
    # region         = "us-west-2"  # State bucket is in primary region
    # dynamodb_table = "trm-blockexplorer-terraform-locks"
    # encrypt        = true
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project        = var.project_name
      Environment    = var.environment
      Region         = var.region
      RegionType     = "secondary"
      ManagedBy      = "terraform"
      Repository     = "trm-blockexplorer"
      Layer          = "regional"
      CriticalSystem = "true"
      BackupSchedule = "continuous"
    }
  }
}

# Data source for global outputs
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "environments/${var.environment}/global/terraform.tfstate"
    region = var.terraform_state_region
  }
}

# Regional Project Module
module "regional" {
  source = "../../../projects/trm-blockexplorer/regional"

  # Basic Configuration
  project_name      = var.project_name
  environment       = var.environment
  region            = var.region
  is_primary_region = var.is_primary_region
  replica_regions   = var.replica_regions

  # Global Resource References
  domain_name         = data.terraform_remote_state.global.outputs.domain_name
  hosted_zone_id      = data.terraform_remote_state.global.outputs.hosted_zone_id
  kms_secrets_key_arn = data.terraform_remote_state.global.outputs.kms_secrets_key_arn
  kms_data_key_arn    = data.terraform_remote_state.global.outputs.kms_data_key_arn
  kms_logs_key_arn    = data.terraform_remote_state.global.outputs.kms_logs_key_arn
  # lambda_execution_role_arn = data.terraform_remote_state.global.outputs.lambda_execution_role_arn # Removed - migrating to ECS
  dynamodb_tables = data.terraform_remote_state.global.outputs.regional_deployment_params.dynamodb_tables

  # Production-specific Networking - Secondary Region
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = var.availability_zones
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_subnet_cidrs      = var.private_subnet_cidrs
  enable_nat_gateway        = var.enable_nat_gateway
  enable_single_nat_gateway = false # Multi-AZ NAT for production

  # Lambda configuration removed - migrating to ECS
  # See ADR-018 for container architecture decision

  # Production API Gateway Configuration - Secondary Region
  api_gateway_config = {
    enable_caching           = true  # Enabled for production
    cache_cluster_size       = "1.6" # Larger cache for production
    cache_ttl_seconds        = 300   # 5 minutes cache TTL
    throttle_burst_limit     = 2000  # Higher limits for production
    throttle_rate_limit      = 1000
    api_key_source           = "HEADER"
    enable_compression       = true # Enable response compression
    minimum_compression_size = 1024
  }

  # Production Usage Plans - Same as primary for consistency
  api_usage_plans = {
    premium = {
      description = "Premium tier usage plan (secondary region)"
      quota = {
        limit  = 100000
        period = "DAY"
      }
      throttle = {
        burst_limit = 2000
        rate_limit  = 1000
      }
    }
    standard = {
      description = "Standard tier usage plan (secondary region)"
      quota = {
        limit  = 10000
        period = "DAY"
      }
      throttle = {
        burst_limit = 500
        rate_limit  = 250
      }
    }
    basic = {
      description = "Basic tier usage plan (secondary region)"
      quota = {
        limit  = 1000
        period = "DAY"
      }
      throttle = {
        burst_limit = 100
        rate_limit  = 50
      }
    }
  }

  api_keys = var.api_keys

  # Production Monitoring Configuration - Secondary Region
  monitoring_config = {
    create_dashboard           = true
    enable_detailed_monitoring = true # Full monitoring for production
    log_retention_days         = 30   # Extended retention
    alarm_email_endpoints      = var.alarm_email_endpoints
    enable_xray_tracing        = true # X-Ray for production
    enable_enhanced_monitoring = true
    cross_region_dashboards    = true # Enable cross-region monitoring
  }

  # Production Optimization Settings - Secondary Region
  cost_optimization = {
    environment_based_sizing      = true
    enable_deletion_protection    = true # Enabled for production safety
    enable_point_in_time_recovery = true
    backup_retention_days         = 30
    enable_cross_region_backup    = true
  }

  tags = var.additional_tags
}