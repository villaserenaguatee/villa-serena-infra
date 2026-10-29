variable "zone_id" {
  type        = string
  description = "Cloudflare zone ID for villaserenaguate.lat."
  validation {
    condition     = can(regex("^[a-fA-F0-9]{32}$", var.zone_id))
    error_message = "zone_id must be a 32-character Cloudflare zone ID."
  }
}

variable "web_subdomain" {
  type    = string
  default = "web.villaserenaguate.lat"
}

variable "amplify_cname_target" {
  type        = string
  description = "Destino CNAME exacto indicado por AWS Amplify para el subdominio web."
}

variable "certificate_validation_name" {
  type        = string
  description = "Nombre CNAME de validación de certificado que entrega AWS Amplify, sin modificar."
  default     = ""
}

variable "certificate_validation_target" {
  type        = string
  description = "Destino CNAME de validación de certificado que entrega AWS Amplify, sin modificar."
  default     = ""
}
