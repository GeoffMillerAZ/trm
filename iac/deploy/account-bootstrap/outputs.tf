# Account Bootstrap Outputs

# GuardDuty Outputs
output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.account_bootstrap.guardduty_detector_id
}

output "guardduty_enabled" {
  description = "Whether GuardDuty is enabled"
  value       = module.account_bootstrap.guardduty_enabled
}

output "guardduty_findings_bucket" {
  description = "S3 bucket for GuardDuty findings"
  value       = module.account_bootstrap.guardduty_findings_bucket
}

# Inspector Outputs
output "inspector_enabled" {
  description = "Whether Inspector v2 is enabled"
  value       = module.account_bootstrap.inspector_enabled
}

output "inspector_lambda_scanning_enabled" {
  description = "Whether Lambda scanning is enabled in Inspector"
  value       = module.account_bootstrap.inspector_lambda_scanning_enabled
}

output "sbom_export_bucket" {
  description = "S3 bucket for SBOM exports"
  value       = module.account_bootstrap.sbom_export_bucket
}

# Security Buckets
output "security_findings_bucket_arn" {
  description = "ARN of the security findings bucket"
  value       = module.account_bootstrap.security_findings_bucket_arn
}

output "sbom_exports_bucket_arn" {
  description = "ARN of the SBOM exports bucket"
  value       = module.account_bootstrap.sbom_exports_bucket_arn
}

output "security_reports_bucket_arn" {
  description = "ARN of the security reports bucket"
  value       = module.account_bootstrap.security_reports_bucket_arn
}

# IAM Roles
output "security_scanner_role_arn" {
  description = "ARN of the security scanner role for cross-service access"
  value       = module.account_bootstrap.security_scanner_role_arn
}

output "inspector_lambda_role_arn" {
  description = "ARN of the role for Inspector Lambda integration"
  value       = module.account_bootstrap.inspector_lambda_role_arn
}

# KMS Keys
output "security_kms_key_arn" {
  description = "ARN of the KMS key for security services"
  value       = module.account_bootstrap.security_kms_key_arn
}

output "security_kms_key_alias" {
  description = "Alias of the KMS key for security services"
  value       = module.account_bootstrap.security_kms_key_alias
}

# SNS Topics
output "security_alerts_topic_arn" {
  description = "ARN of the SNS topic for security alerts"
  value       = module.account_bootstrap.security_alerts_topic_arn
}

# Account Information
output "account_id" {
  description = "AWS Account ID"
  value       = module.account_bootstrap.account_id
}

output "primary_region" {
  description = "Primary region for security services"
  value       = module.account_bootstrap.primary_region
}

output "secondary_region" {
  description = "Secondary region for security services"
  value       = module.account_bootstrap.secondary_region
}

# Integration Information
output "security_services_config" {
  description = "Configuration summary for security services"
  value       = module.account_bootstrap.security_services_config
}

# DNS Outputs
output "main_hosted_zone_id" {
  description = "Route53 hosted zone ID for production (trm.geoffmiller.cloud)"
  value       = module.account_bootstrap.main_hosted_zone_id
}

output "main_hosted_zone_nameservers" {
  description = "Nameservers to configure in Namecheap for trm.geoffmiller.cloud"
  value       = module.account_bootstrap.main_hosted_zone_nameservers
}

output "dev_hosted_zone_id" {
  description = "Route53 hosted zone ID for development"
  value       = module.account_bootstrap.dev_hosted_zone_id
}

output "dns_configuration" {
  description = "DNS configuration summary"
  value       = module.account_bootstrap.dns_configuration
}

output "namecheap_setup_instructions" {
  description = "Instructions for configuring Namecheap"
  value       = module.account_bootstrap.namecheap_configuration_instructions
}