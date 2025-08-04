# Account Bootstrap Configuration

# AWS Regions
aws_region       = "us-west-2"
secondary_region = "us-east-2"

# Security Services (disabled by default)
enable_guardduty              = false # Enable when ready
enable_inspector              = false # Enable when ready
enable_security_hub           = false # Enable when ready
enable_multi_region_guardduty = false # Enable for production

# Inspector Scanning Options
enable_lambda_scanning = false # Enable when Inspector is enabled
enable_ec2_scanning    = false # Not needed for serverless
enable_ecr_scanning    = false # Enable if using containers

# Retention Settings
security_findings_retention_days = 90
sbom_retention_days              = 365

# Notifications (optional)
notification_email = "" # Add email for security alerts

# GuardDuty Configuration
guardduty_finding_publishing_frequency = "FIFTEEN_MINUTES"

# Additional tags
additional_tags = {
  Owner       = "Platform Team"
  CostCenter  = "Engineering"
  Environment = "shared"
  ManagedBy   = "terraform"
}