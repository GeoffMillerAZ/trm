# Account Bootstrap - Outputs

# GuardDuty Outputs
output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "guardduty_enabled" {
  description = "Whether GuardDuty is enabled"
  value       = var.enable_guardduty
}

output "guardduty_findings_bucket" {
  description = "S3 bucket for GuardDuty findings"
  value       = aws_s3_bucket.security_findings.id
}

# Inspector Outputs
output "inspector_enabled" {
  description = "Whether Inspector v2 is enabled"
  value       = var.enable_inspector
}

output "inspector_lambda_scanning_enabled" {
  description = "Whether Lambda scanning is enabled in Inspector"
  value       = var.enable_inspector && var.enable_lambda_scanning
}

output "sbom_export_bucket" {
  description = "S3 bucket for SBOM exports"
  value       = aws_s3_bucket.sbom_exports.id
}

# Security Buckets
output "security_findings_bucket_arn" {
  description = "ARN of the security findings bucket"
  value       = aws_s3_bucket.security_findings.arn
}

output "sbom_exports_bucket_arn" {
  description = "ARN of the SBOM exports bucket"
  value       = aws_s3_bucket.sbom_exports.arn
}

output "security_reports_bucket_arn" {
  description = "ARN of the security reports bucket"
  value       = aws_s3_bucket.security_reports.arn
}

# IAM Roles
output "security_scanner_role_arn" {
  description = "ARN of the security scanner role for cross-service access"
  value       = (var.enable_inspector || var.enable_codeguru) ? aws_iam_role.security_scanner[0].arn : null
}

output "inspector_lambda_role_arn" {
  description = "ARN of the role for Inspector Lambda integration"
  value       = var.enable_inspector ? aws_iam_role.inspector_lambda[0].arn : null
}

# KMS Keys
output "security_kms_key_arn" {
  description = "ARN of the KMS key for security services"
  value       = aws_kms_key.security.arn
}

output "security_kms_key_alias" {
  description = "Alias of the KMS key for security services"
  value       = aws_kms_alias.security.name
}

# SNS Topics
output "security_alerts_topic_arn" {
  description = "ARN of the SNS topic for security alerts"
  value       = var.notification_email != "" ? aws_sns_topic.security_alerts[0].arn : null
}

# Account Information
output "account_id" {
  description = "AWS Account ID"
  value       = local.account_id
}

output "primary_region" {
  description = "Primary region for security services"
  value       = var.primary_region
}

output "secondary_region" {
  description = "Secondary region for security services"
  value       = var.secondary_region
}

# Integration Information
output "security_services_config" {
  description = "Configuration summary for security services"
  value = {
    guardduty_enabled            = var.enable_guardduty
    inspector_enabled            = var.enable_inspector
    security_hub_enabled         = var.enable_security_hub
    lambda_scanning_enabled      = var.enable_lambda_scanning
    multi_region_enabled         = var.enable_multi_region_guardduty
    findings_retention_days      = var.security_findings_retention_days
    sbom_retention_days          = var.sbom_retention_days
    finding_publishing_frequency = var.guardduty_finding_publishing_frequency
  }
}

# DNS Outputs
output "main_hosted_zone_id" {
  description = "Route53 hosted zone ID for production (trm.geoffmiller.cloud)"
  value       = aws_route53_zone.main.zone_id
}

output "main_hosted_zone_name" {
  description = "Route53 hosted zone name for production"
  value       = aws_route53_zone.main.name
}

output "main_hosted_zone_nameservers" {
  description = "Nameservers for trm.geoffmiller.cloud - add these to Namecheap"
  value       = aws_route53_zone.main.name_servers
}

output "dev_hosted_zone_id" {
  description = "Route53 hosted zone ID for development"
  value       = var.create_dev_zone ? aws_route53_zone.dev[0].zone_id : null
}

output "dev_hosted_zone_name" {
  description = "Route53 hosted zone name for development"
  value       = var.create_dev_zone ? aws_route53_zone.dev[0].name : null
}

output "staging_hosted_zone_id" {
  description = "Route53 hosted zone ID for staging"
  value       = var.create_staging_zone ? aws_route53_zone.staging[0].zone_id : null
}

output "dns_configuration" {
  description = "DNS configuration summary"
  value = {
    root_domain       = var.root_domain
    subdomain_prefix  = var.subdomain_prefix
    production_domain = "${var.subdomain_prefix}.${var.root_domain}"
    dev_domain        = var.create_dev_zone ? "dev.${var.subdomain_prefix}.${var.root_domain}" : null
    staging_domain    = var.create_staging_zone ? "staging.${var.subdomain_prefix}.${var.root_domain}" : null
  }
}

output "namecheap_configuration_instructions" {
  description = "Instructions for configuring Namecheap"
  value       = <<-EOT
    To complete DNS setup in Namecheap:
    
    1. Log in to Namecheap
    2. Go to Domain List > Manage for ${var.root_domain}
    3. Click on "Advanced DNS" tab
    4. Add these NS records:
       
       Host: ${var.subdomain_prefix}
       Type: NS
       Value: Add each nameserver below on a separate NS record:
       ${join("\n       ", aws_route53_zone.main.name_servers)}
    
    5. Save changes and wait 24-48 hours for propagation
    
    Test with: dig NS ${var.subdomain_prefix}.${var.root_domain}
  EOT
}