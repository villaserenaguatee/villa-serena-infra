variable "aws_region" {
  description = "Region containing the existing Villa Serena VPC and EC2."
  type        = string
  default     = "us-east-1"
}

variable "backend_port" {
  description = "Port Spring Boot listens on inside the EC2 host."
  type        = number
  default     = 8080
  validation {
    condition     = var.backend_port >= 1 && var.backend_port <= 65535
    error_message = "backend_port must be a valid TCP port."
  }
}
