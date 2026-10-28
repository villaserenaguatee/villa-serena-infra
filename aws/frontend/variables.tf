variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_access_token" {
  description = "Token de GitHub para conectar Amplify con villa-serena-web."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "domain_name" {
  type    = string
  default = "villaserenaguate.lat"
}
