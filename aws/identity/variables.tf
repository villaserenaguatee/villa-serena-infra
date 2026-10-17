variable "aws_region" {
  description = "AWS region used by the provider. IAM and OIDC resources are account-global."
  type        = string
}

variable "deployment_branch" {
  description = "Only this villa-serena-api branch can assume the deployment role."
  type        = string
  default     = "main"
}
