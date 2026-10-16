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
2. Decide which AWS account and Terraform state backend will own these
   account-global IAM resources. Do not put secrets in Terraform state.
3. If this AWS account already has an OIDC provider for GitHub Actions,
   import its ARN into `aws_iam_openid_connect_provider.github_actions`
   instead of creating a second provider.
4. Confirm the API repository's actual OIDC `sub` claim matches the
   immutable format above before first deployment. Workflows using
   GitHub Environments have a different subject format.

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -var='aws_region=us-east-1'
```

The region in that example is only illustrative; select the actual AWS
region before planning. Review the plan before any `terraform apply`.

Do not enable deployment workflows until SSM permissions and instance
scoping have been reviewed.
