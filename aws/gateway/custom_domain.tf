# API public name: a single stable hostname for BFF and mobile clients.
# Keep TLS validation and hostname mapping in this gateway state to avoid
# cross-state output coupling. Cloudflare remains DNS-only for this hostname.
locals {
  api_domain = "api.villaserenaguate.lat"
}

data "cloudflare_zone" "villa_serena" {
  filter = {
    name = "villaserenaguate.lat"
  }
}

resource "aws_acm_certificate" "api" {
  domain_name       = local.api_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# This certificate covers exactly one hostname (no SAN entries).
resource "cloudflare_dns_record" "acm_validation" {
  zone_id = data.cloudflare_zone.villa_serena.id
  name    = one(aws_acm_certificate.api.domain_validation_options).resource_record_name
  type    = one(aws_acm_certificate.api.domain_validation_options).resource_record_type
  content = one(aws_acm_certificate.api.domain_validation_options).resource_record_value
  ttl     = 60
  proxied = false
  comment = "ACM DNS validation for Villa Serena API"
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [cloudflare_dns_record.acm_validation.name]
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = local.api_domain
  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.backend.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.default.name
}

# DNS-only until end-to-end API and origin TLS are validated.
# Cloudflare proxy may be enabled later with SSL/TLS Full (strict).
resource "cloudflare_dns_record" "api" {
  zone_id = data.cloudflare_zone.villa_serena.id
  name    = local.api_domain
  type    = "CNAME"
  content = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
  ttl     = 1
  proxied = false
  comment = "Villa Serena AWS API Gateway custom domain"
}
