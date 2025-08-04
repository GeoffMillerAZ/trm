# Production Environment - Global Configuration

# Project Configuration
project_name = "trm-blockexplorer"
environment  = "prod"

# Regional Configuration
primary_region   = "us-west-2"
secondary_region = "us-east-2"

# Domain Configuration
# IMPORTANT: Update these values for your production domain
domain_name        = "trm.geoffmiller.cloud" # Your production domain
hosted_zone_id     = null                    # Set this if using existing hosted zone
create_hosted_zone = true                    # Set to false if using existing hosted zone

# Multi-Region Configuration
enable_multi_region  = true # Enable for production active-active
health_check_regions = ["us-west-2", "us-east-1", "eu-west-1"]

# Alarm Configuration
# IMPORTANT: Add production alert emails
alarm_email_endpoints = [
  # "ops-team@example.com",
  # "on-call@example.com"
]

# Additional Tags
additional_tags = {
  Owner              = "Platform Team"
  CostCenter         = "Production"
  Purpose            = "BlockExplorer"
  Automation         = "terraform"
  Environment        = "prod"
  CriticalSystem     = "true"
  BackupSchedule     = "daily"
  ComplianceScope    = "SOC2"
  DataClassification = "internal"
}