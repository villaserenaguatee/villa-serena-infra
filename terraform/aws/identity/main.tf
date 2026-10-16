# This OIDC provider is account-wide. If it already exists, import it
# into this state instead of attempting to create a duplicate.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "api_deploy_trust" {
  statement {
    sid     = "GitHubApiBranchOnly"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Immutable GitHub subject format for repos created since 2026-07-15.
    # org ID: 335120540; api repo ID: 1389591619.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:villaserenaguatee@335120540/villa-serena-api@1389591619:ref:refs/heads/${var.deployment_branch}"]
    }
  }
}

resource "aws_iam_role" "api_deploy" {
  name               = "villa-serena-api-deploy-role"
  description        = "GitHub Actions OIDC role for villa-serena-api deployments"
  assume_role_policy = data.aws_iam_policy_document.api_deploy_trust.json

  tags = {
    Project   = "villa-serena"
    ManagedBy = "terraform"
    Purpose   = "api-deployment"
  }
}

# Intentionally no permission policies yet: SSM Run Command permissions
# will be scoped to the future EC2 instance and approved SSM document.
