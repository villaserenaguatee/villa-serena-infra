variable "cloudflare_account_id" {
  description = "R2 application account; authentication uses CLOUDFLARE_API_TOKEN, never tfvars secrets."
  type        = string
  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.cloudflare_account_id))
    error_message = "Provide a valid Cloudflare account ID."
  }
}
variable "cloudflare_zone_id" {
  description = "Zone in the same account, owning the public assets domain."
  type        = string
  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.cloudflare_zone_id))
    error_message = "Provide a valid Cloudflare zone ID."
  }
}
variable "public_assets_domain" {
  type    = string
  default = "assets-dev.villaserenaguate.lat"
}
variable "allowed_origins" {
  type    = list(string)
  default = ["http://localhost:3000"]
  validation {
    condition     = length(var.allowed_origins) > 0 && alltrue([for origin in var.allowed_origins : can(regex("^https?://[^/]+$", origin)) && !strcontains(origin, "*")])
    error_message = "Use explicit browser origins without wildcard or path."
  }
}
