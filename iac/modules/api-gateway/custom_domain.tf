# Custom Domain Configuration for API Gateway

# Custom Domain Name
resource "aws_api_gateway_domain_name" "custom" {
  count = var.custom_domain_name != null && var.certificate_arn != null ? 1 : 0

  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(local.common_tags, {
    Name = var.custom_domain_name
  })
}

# Base Path Mapping
resource "aws_api_gateway_base_path_mapping" "custom" {
  count = var.custom_domain_name != null && var.certificate_arn != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.custom[0].domain_name
}

# Route 53 Record for Custom Domain
resource "aws_route53_record" "custom_domain" {
  count = var.custom_domain_name != null && var.certificate_arn != null && var.hosted_zone_id != null ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.custom_domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.custom[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.custom[0].regional_zone_id
    evaluate_target_health = false
  }
}