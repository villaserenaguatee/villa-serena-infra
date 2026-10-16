variable "zone_id" {
  type        = string
  description = "Cloudflare zone ID of the already onboarded domain. This root does NOT create a new zone."
  validation {
    condition     = can(regex("^[a-fA-F0-9]{32}$", var.zone_id))
    error_message = "zone_id must be a 32-character Cloudflare zone ID."
  }
}

variable "tunnel_id" {
  type        = string
  default     = ""
  description = "Existing Cloudflare Tunnel UUID. Blank leaves this root with zero managed DNS records."
  validation {
    condition     = var.tunnel_id == "" || can(regex("^[0-9a-fA-F-]{36}$", var.tunnel_id))
    error_message = "tunnel_id must be empty or a UUID."
  }
}

variable "tunnel_hostnames" {
  description = "FQDNs to CNAME to the existing tunnel. Empty by default to avoid accidental DNS changes."
  type        = set(string)
  default     = []
}
