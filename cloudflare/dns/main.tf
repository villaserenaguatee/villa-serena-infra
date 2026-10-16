# The Cloudflare zone must already exist. We intentionally do not take over
# apex, MX, SPF, DKIM, DMARC, or other existing records.
#
# Cloudflare Tunnel DNS routing does not depend on EC2's public IPv4 address.
resource "cloudflare_dns_record" "tunnel_hostname" {
  for_each = var.tunnel_id == "" ? toset([]) : var.tunnel_hostnames

  zone_id = var.zone_id
  name    = each.value
  type    = "CNAME"
  content = "${var.tunnel_id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
  comment = "Managed by Terraform: Villa Serena Cloudflare Tunnel"
}
