# Application objects are separate from the existing Terraform state bucket.
resource "cloudflare_r2_bucket" "application" {
  for_each      = toset(["public", "private"])
  account_id    = var.cloudflare_account_id
  name          = "villa-serena-dev-${each.key}"
  storage_class = "Standard"
  lifecycle {
    prevent_destroy = true
  }
}
resource "cloudflare_r2_managed_domain" "disabled" {
  for_each    = cloudflare_r2_bucket.application
  account_id  = var.cloudflare_account_id
  bucket_name = each.value.name
  enabled     = false
}
resource "cloudflare_r2_custom_domain" "public" {
  account_id  = var.cloudflare_account_id
  bucket_name = cloudflare_r2_bucket.application["public"].name
  zone_id     = var.cloudflare_zone_id
  domain      = var.public_assets_domain
  enabled     = true
  min_tls     = "1.2"
}
resource "cloudflare_r2_bucket_cors" "application" {
  for_each    = cloudflare_r2_bucket.application
  account_id  = var.cloudflare_account_id
  bucket_name = each.value.name
  rules = [{
    id = "browser-downloads"
    allowed = {
      origins = var.allowed_origins
      methods = ["GET", "HEAD"]
    }
    expose_headers  = ["ETag", "Content-Disposition"]
    max_age_seconds = 3600
  }]
}
