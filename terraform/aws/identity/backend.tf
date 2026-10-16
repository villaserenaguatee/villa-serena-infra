# Terraform state is stored in the existing Cloudflare R2 bucket.
# Keep AWS provider credentials separate from R2 backend credentials.
terraform {
  backend "s3" {
    bucket = "villa-serena-terraform-state"
    key    = "aws/identity/terraform.tfstate"
    region = "auto"

    use_lockfile                = true
    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true

    # Set endpoints.s3 and R2 credentials through an untracked
    # -backend-config file or other secure backend configuration.
  }
}
