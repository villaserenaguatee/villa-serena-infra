# AWS IAM identity — Villa Serena

This Terraform root configures **only** GitHub Actions federation and the
`villa-serena-api-deploy-role`. It does not create EC2, VPC, or deployment
permissions yet.

## Trust boundary

- OIDC issuer: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`
- Repo: `villaserenaguatee/villa-serena-api`
- Immutable org ID: `335120540`
- Immutable repo ID: `1389591619`
- Authorized branch: `main` (configurable with `deployment_branch`)

The role has **no AWS permissions attached yet**. SSM permissions will be
added when the instance and command document are defined.

## Before applying

1. Configure an AWS identity with permissions to manage IAM resources.
2. This root uses the existing Cloudflare R2 bucket `villa-serena-terraform-state`,
   with its own state key `aws/identity/terraform.tfstate`. Confirm the bucket
   and keep any existing `github/terraform.tfstate` unchanged.
3. If this AWS account already has an OIDC provider for GitHub Actions,
   import its ARN into `aws_iam_openid_connect_provider.github_actions`
   instead of creating a second provider.
4. Confirm the API repository's actual OIDC `sub` claim matches the
   immutable format above before first deployment. Workflows using
   GitHub Environments have a different subject format.

## R2 backend setup

The backend is deliberately **partially configured**. Copy `r2.tfbackend.example`
to a **private location outside the repository**, set the R2 endpoint and
backend credentials there, and keep that file out of version control.
This prevents R2 credentials from accidentally replacing AWS provider
credentials. Backend credentials may still be cached locally under
`.terraform/` or inside Terraform plan files: secure those artifacts.

Use a separate authenticated AWS profile (or AWS SSO / temporary AWS
credentials) for the AWS provider; the R2 credentials are only for the
state backend.

```bash
cd terraform/aws/identity
terraform init -backend-config=/private/path/r2.tfbackend
terraform fmt -check
terraform validate
terraform plan -var='aws_region=us-east-1'
```

Do not use `-migrate-state` or `-force-copy` to reuse the existing GitHub
state. This identity stack must start with its own empty state. Check
whether the GitHub OIDC provider already exists in the target AWS account
before applying; if it does, import it into this **new** state.

R2 S3 endpoint configuration follows the Cloudflare Terraform backend
guide: https://developers.cloudflare.com/terraform/advanced-topics/remote-backend/

The region in that example is only illustrative; select the actual AWS
region before planning. Review the plan before any `terraform apply`.

Do not enable deployment workflows until SSM permissions and instance
scoping have been reviewed.
