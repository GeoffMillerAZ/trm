# DNS Infrastructure for TRM Project
# This creates the hosted zones for the project subdomain delegation

# Main hosted zone for trm.geoffmiller.cloud (used for production)
resource "aws_route53_zone" "main" {
  name = "${var.subdomain_prefix}.${var.root_domain}"

  tags = merge(local.common_tags, {
    Name        = "${var.subdomain_prefix}.${var.root_domain}"
    Environment = "production"
    Purpose     = "Main DNS zone for TRM project"
  })
}

# Separate hosted zone for dev environment
resource "aws_route53_zone" "dev" {
  count = var.create_dev_zone ? 1 : 0
  name  = "dev.${var.subdomain_prefix}.${var.root_domain}"

  tags = merge(local.common_tags, {
    Name        = "dev.${var.subdomain_prefix}.${var.root_domain}"
    Environment = "development"
    Purpose     = "Development DNS zone"
  })
}

# NS records in main zone to delegate to dev zone
resource "aws_route53_record" "dev_ns" {
  count   = var.create_dev_zone ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "dev.${var.subdomain_prefix}.${var.root_domain}"
  type    = "NS"
  ttl     = 172800 # 48 hours for stability
  records = aws_route53_zone.dev[0].name_servers
}

# Optional: Staging hosted zone for future use
resource "aws_route53_zone" "staging" {
  count = var.create_staging_zone ? 1 : 0
  name  = "staging.${var.subdomain_prefix}.${var.root_domain}"

  tags = merge(local.common_tags, {
    Name        = "staging.${var.subdomain_prefix}.${var.root_domain}"
    Environment = "staging"
    Purpose     = "Staging DNS zone"
  })
}

# NS records in main zone to delegate to staging zone
resource "aws_route53_record" "staging_ns" {
  count   = var.create_staging_zone ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "staging.${var.subdomain_prefix}.${var.root_domain}"
  type    = "NS"
  ttl     = 172800
  records = aws_route53_zone.staging[0].name_servers
}

# CAA records for the main domain to specify allowed certificate authorities
resource "aws_route53_record" "main_caa" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.subdomain_prefix}.${var.root_domain}"
  type    = "CAA"
  ttl     = 3600

  records = [
    "0 issue \"amazon.com\"",
    "0 issue \"amazontrust.com\"",
    "0 issue \"awstrust.com\"",
    "0 issue \"amazonaws.com\""
  ]
}

# TXT record for domain verification
resource "aws_route53_record" "main_txt" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.subdomain_prefix}.${var.root_domain}"
  type    = "TXT"
  ttl     = 300

  records = [
    "v=spf1 -all", # No email sending from this domain
    "trm-project-domain-verification"
  ]
}

# Optional: Create a health check endpoint record
resource "aws_route53_record" "health" {
  count   = var.create_health_check_record ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "health.${var.subdomain_prefix}.${var.root_domain}"
  type    = "A"
  ttl     = 60

  records = ["127.0.0.1"] # Placeholder - will be updated by actual deployments
}