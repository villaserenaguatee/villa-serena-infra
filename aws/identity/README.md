# AWS IAM identity — Villa Serena

This Terraform root configures GitHub Actions OIDC and **two separate roles**:
`villa-serena-api-deploy-role` (future API deployments, no permissions yet)
and `villa-serena-infra-ansible-role` (SSM access for server configuration).
It does not create EC2 or VPC.

## Trust boundary

- OIDC issuer: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`
- Repo: `villaserenaguatee/villa-serena-api`
- Immutable org ID: `335120540`
- Immutable repo ID: `1389591619`
- Authorized branch: `main` (configurable with `deployment_branch`)

The API deployment role has **no AWS permissions attached yet**.
The infrastructure Ansible role can open SSM sessions to instances tagged
`Name=villa-serena-prod-app` and inspect the EC2/SSM inventory. The `aws_ssm`
connection plugin also requires a dedicated S3 transfer bucket, which this
PR does **not** create or authorize yet. Do not run Ansible until this is
configured. The trust policy assumes a `main` branch workflow without a
GitHub Environment subject override.

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

The existing Cloudflare R2 bucket and endpoint are configured in `backend.tf`.
The identity stack uses `aws/identity/terraform.tfstate`, **not** the
existing `github/terraform.tfstate`.

Provide **R2-only** access key credentials for the backend securely.
Do not commit the keys or Terraform local cache / plan files to Git.
Keep credentials for the AWS provider separate from R2 credentials.

```bash
cd aws/identity
terraform init
terraform fmt -check
terraform validate
terraform plan -var='aws_region=us-east-1'
```

Do not migrate or force-copy the GitHub state. This identity stack starts
with an independent state key. Import an existing GitHub OIDC IAM provider
if your AWS account already has one.

The region in that example is only illustrative; select the actual AWS
region before planning. Review the plan before any `terraform apply`.

Do not enable deployment workflows until SSM permissions and instance
scoping have been reviewed.
