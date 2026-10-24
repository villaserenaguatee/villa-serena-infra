output "web_cname_fqdn" {
  value       = cloudflare_dns_record.web.name
  description = "Configured FQDN for the web deployment."
}

output "web_cname_target" {
  value       = cloudflare_dns_record.web.content
  description = "Target CNAME pointing to Vercel."
}
