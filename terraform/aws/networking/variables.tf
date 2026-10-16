variable "aws_region" {
  type        = string
  description = "AWS region for networking and compute (must match)."
  default     = "us-east-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "public_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}
