output "managed_tunnel_hostnames" {
  value = sort(keys(cloudflare_dns_record.tunnel_hostname))
}

output "tunnel_dns_target" {
  value = var.tunnel_id == "" ? null : "${var.tunnel_id}.cfargotunnel.com"
}
