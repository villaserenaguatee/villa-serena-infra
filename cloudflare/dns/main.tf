resource "cloudflare_dns_record" "web" {
  zone_id = var.zone_id
  name    = var.web_subdomain
  type    = "CNAME"
  content = var.amplify_cname_target
  ttl     = 1
  proxied = false
  comment = "Villa Serena web frontend hosted on AWS Amplify"
}
