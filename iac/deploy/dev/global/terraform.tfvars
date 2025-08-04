# Development Environment - Global Configuration

# Project Configuration
project_name = "trm-blockexplorer"
environment  = "dev"

# Regional Configuration
primary_region   = "us-west-2"
secondary_region = "us-east-2"

# Domain Configuration
domain_name        = "dev.trm.geoffmiller.cloud"
hosted_zone_id     = null # Set this if using existing hosted zone
create_hosted_zone = true # Set to false if using existing hosted zone

# Multi-Region Configuration
enable_multi_region  = false # Temporarily disabled to fix deployment
health_check_regions = ["us-east-1", "us-west-1", "eu-west-1"]

# Alarm Configuration
alarm_email_endpoints = [] # Add email addresses for alarms

# Additional Tags
additional_tags = {
  Owner       = "Development Team"
  CostCenter  = "Engineering"
  Purpose     = "Development"
  Automation  = "terraform"
  Environment = "dev"
}