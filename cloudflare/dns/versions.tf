terraform {
  required_version = ">= 1.10.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    profile = "r2-terraform"
    bucket  = "villa-serena-terraform-state"
    key     = "cloudflare/dns/terraform.tfstate"
    region  = "auto"

    endpoints = {
      s3 = "https://cb137b9c4110407eeed3317b9d2579b3.r2.cloudflarestorage.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true
  }
}

provider "cloudflare" {
  # Uses CLOUDFLARE_API_TOKEN; keep it out of Git and tfstate.
}
