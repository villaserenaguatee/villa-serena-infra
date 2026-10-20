output "storage_endpoint" { value = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com" }
output "storage_region" { value = "auto" }
output "private_bucket" { value = cloudflare_r2_bucket.application["private"].name }
output "public_bucket" { value = cloudflare_r2_bucket.application["public"].name }
output "public_assets_url" { value = "https://${cloudflare_r2_custom_domain.public.domain}" }
