variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "ec2_role_name" {
  description = "Existing role managed by aws/compute, never recreated here."
  type        = string
  default     = "villa-serena-prod-ec2-role"
}
variable "allowed_origins" {
  type    = list(string)
  default = ["https://web.villaserenaguate.lat"]
  validation {
    condition     = length(var.allowed_origins) > 0 && alltrue([for origin in var.allowed_origins : can(regex("^https://[^/]+$", origin)) && !strcontains(origin, "*")])
    error_message = "Production browser origins must be explicit HTTPS origins without wildcard or path."
  }
}
