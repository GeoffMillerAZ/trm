# Development Environment - US East 2 Regional Resources (Secondary)

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
    # key            = "environments/dev/us-east-2/terraform.tfstate"
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
      Project     = var.project_name
      Environment = var.environment
      Region      = var.region
      RegionType  = "secondary"
      ManagedBy   = "terraform"
      Repository  = "trm-blockexplorer"
      Layer       = "regional"
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
  kms_secrets_key_arn = "" # KMS keys are region-specific
  kms_data_key_arn    = "" # KMS keys are region-specific
  kms_logs_key_arn    = "" # KMS keys are region-specific
  # lambda_execution_role_arn = data.terraform_remote_state.global.outputs.lambda_execution_role_arn # Removed - migrating to ECS
  global_alarms_topic_arn = try(data.terraform_remote_state.global.outputs.global_alarms_topic_arn, null)
  dynamodb_tables         = data.terraform_remote_state.global.outputs.regional_deployment_params.dynamodb_tables

  # Development-specific Networking - Secondary Region
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = var.availability_zones
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_subnet_cidrs      = var.private_subnet_cidrs
  enable_nat_gateway        = var.enable_nat_gateway
  enable_single_nat_gateway = true # Single NAT for dev cost savings

  # ECS Configuration - Secondary Region
  ecs_cluster_name            = var.ecs_cluster_name
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  ecs_task_role_arn          = var.ecs_task_role_arn
  container_image_uri        = var.container_image_uri
  ecs_service_config         = var.ecs_service_config

  # Development API Gateway Configuration - Secondary Region (ECS integration)
  api_gateway_config = var.api_gateway_config

  # Development Usage Plans - Same structure as primary
  api_usage_plans = {
    premium = {
      description = "Premium tier usage plan - dev (secondary region)"
      quota = {
        limit  = 10000
        period = "DAY"
      }
      throttle = {
        burst_limit = 500
        rate_limit  = 250
      }
    }
    standard = {
      description = "Standard tier usage plan - dev (secondary region)"
      quota = {
        limit  = 1000
        period = "DAY"
      }
      throttle = {
        burst_limit = 100
        rate_limit  = 50
      }
    }
    basic = {
      description = "Basic tier usage plan - dev (secondary region)"
      quota = {
        limit  = 100
        period = "DAY"
      }
      throttle = {
        burst_limit = 20
        rate_limit  = 10
      }
    }
  }

  api_keys = var.api_keys

  # Development Monitoring Configuration - Secondary Region
  monitoring_config = {
    create_dashboard           = false # Temporarily disabled due to dashboard syntax issues
    enable_detailed_monitoring = false # Basic monitoring for dev
    log_retention_days         = 3     # Minimal retention
    alarm_email_endpoints      = var.alarm_email_endpoints
    enable_xray_tracing        = false # Disabled for dev
    enable_enhanced_monitoring = false
    cross_region_dashboards    = true # Enable for multi-region testing
  }

  # Development Optimization Settings - Secondary Region
  cost_optimization = {
    environment_based_sizing      = true
    enable_deletion_protection    = false # Disabled for dev flexibility
    enable_point_in_time_recovery = false
    backup_retention_days         = 1
    enable_cross_region_backup    = false
  }

  # Application Configuration
  use_mock_blockchain = var.use_mock_blockchain

  tags = var.additional_tags
}
