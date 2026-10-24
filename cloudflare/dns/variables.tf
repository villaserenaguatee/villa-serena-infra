variable "zone_id" {
  type        = string
  description = "Cloudflare zone ID for villaserenaguate.lat."
  validation {
    condition     = can(regex("^[a-fA-F0-9]{32}$", var.zone_id))
    error_message = "zone_id must be a 32-character Cloudflare zone ID."
  }
}

variable "web_subdomain" {
  type        = string
  default     = "web.villaserenaguate.lat"
  description = "Subdomain for Vercel frontend deployment."
}

variable "vercel_cname_target" {
  type        = string
  default     = "cname.vercel-dns.com"
  description = "Vercel CNAME target hostname."
}
