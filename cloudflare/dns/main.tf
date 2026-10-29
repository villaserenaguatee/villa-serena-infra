resource "cloudflare_dns_record" "web" {
  zone_id = var.zone_id
  name    = var.web_subdomain
  type    = "CNAME"
  content = var.amplify_cname_target
  ttl     = 1
  proxied = false
  comment = "Villa Serena web frontend hosted on AWS Amplify"
}

# DNS-only validation record returned by Amplify/ACM.
resource "cloudflare_dns_record" "amplify_certificate_validation" {
  count   = var.certificate_validation_name != "" && var.certificate_validation_target != "" ? 1 : 0
  zone_id = var.zone_id
  name    = var.certificate_validation_name
  type    = "CNAME"
  content = var.certificate_validation_target
  ttl     = 1
  proxied = false
  comment = "AWS Amplify managed certificate DNS validation"
}
