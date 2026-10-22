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

variable "throttling_rate_limit" {
  description = "Maximum steady-state request rate (requests per second) allowed across all routes."
  type        = number
  default     = 100
  validation {
    condition     = var.throttling_rate_limit >= 1
    error_message = "throttling_rate_limit must be greater than or equal to 1."
  }
}

variable "throttling_burst_limit" {
  description = "Maximum burst request limit allowed across all routes."
  type        = number
  default     = 50
  validation {
    condition     = var.throttling_burst_limit >= 1
    error_message = "throttling_burst_limit must be greater than or equal to 1."
  }
}
