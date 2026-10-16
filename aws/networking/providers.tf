provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "villa-serena"
      ManagedBy   = "terraform"
      Environment = "prod"
    }
  }
}
