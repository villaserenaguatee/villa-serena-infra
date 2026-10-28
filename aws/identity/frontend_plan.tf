# GitHub OIDC role dedicated to read-only Terraform plans for Amplify.
data "aws_iam_policy_document" "frontend_plan_trust" {
  statement {
    sid     = "GitHubInfraFrontendPlan"
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

    # GitHub immutable subject includes organization and repository IDs.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:villaserenaguatee@335120540/villa-serena-infra@1389591514:pull_request",
        "repo:villaserenaguatee@335120540/villa-serena-infra@1389591514:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "frontend_plan" {
  name               = "villa-serena-frontend-plan-role"
  description        = "Read-only GitHub Actions OIDC role for Amplify Terraform plans"
  assume_role_policy = data.aws_iam_policy_document.frontend_plan_trust.json

  tags = {
    Project   = "villa-serena"
    ManagedBy = "terraform"
    Purpose   = "frontend-plan"
  }
}

data "aws_iam_policy_document" "frontend_plan" {
  statement {
    sid = "AmplifyReadOnly"
    actions = [
      "amplify:GetApp",
      "amplify:GetBranch",
      "amplify:GetDomainAssociation",
      "amplify:ListApps",
      "amplify:ListBranches",
      "amplify:ListDomainAssociations",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "frontend_plan" {
  name   = "villa-serena-frontend-plan-read"
  role   = aws_iam_role.frontend_plan.id
  policy = data.aws_iam_policy_document.frontend_plan.json
}
