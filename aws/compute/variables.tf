variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "instance_type" {
  type    = string
  default = "t4g.small"
}
variable "root_volume_size" {
  type    = number
  default = 20
}
variable "cloudflare_tunnel_parameter_name" {
  description = "Name of a SecureString created separately (token is never stored in Terraform state)."
  type        = string
  default     = "/villa-serena/prod/cloudflare/tunnel-token"
}
variable "enable_cloudflared" {
  description = "Enable cloudflared at boot only after the SecureString token exists."
  type        = bool
  default     = false
}
