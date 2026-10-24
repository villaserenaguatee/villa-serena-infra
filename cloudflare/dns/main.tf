# CNAME record pointing web.villaserenaguate.lat to Vercel
resource "cloudflare_dns_record" "web" {
  zone_id = var.zone_id
  name    = var.web_subdomain
  type    = "CNAME"
  content = var.vercel_cname_target
  ttl     = 1
  proxied = false
  comment = "Villa Serena web frontend custom domain for Vercel deployment"
}
