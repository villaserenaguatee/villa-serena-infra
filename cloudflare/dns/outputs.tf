output "web_cname_fqdn" {
  value = cloudflare_dns_record.web.name
}

output "web_cname_target" {
  value = cloudflare_dns_record.web.content
}
