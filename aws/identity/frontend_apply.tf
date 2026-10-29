# Dedicated deployment identity; only main may assume this role.
data "aws_iam_policy_document" "frontend_apply_trust" {
  statement {
    sid     = "GitHubInfraProtectedEnvironment"
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

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:villaserenaguatee@335120540/villa-serena-infra@1389591514:environment:frontend-production"]
    }
  }
}

resource "aws_iam_role" "frontend_apply" {
  name               = "villa-serena-frontend-apply-role"
  description        = "GitHub OIDC role for approved Amplify frontend Terraform applies on main"
  assume_role_policy = data.aws_iam_policy_document.frontend_apply_trust.json

  tags = {
    Project   = "villa-serena"
    ManagedBy = "terraform"
    Purpose   = "frontend-apply"
  }
}

data "aws_iam_policy_document" "frontend_apply" {
  statement {
    sid = "ManageVillaSerenaAmplify"
    actions = [
      "amplify:CreateApp",
      "amplify:UpdateApp",
      "amplify:DeleteApp",
      "amplify:GetApp",
      "amplify:ListApps",
      "amplify:CreateBranch",
      "amplify:UpdateBranch",
      "amplify:DeleteBranch",
      "amplify:GetBranch",
      "amplify:ListBranches",
      "amplify:CreateDomainAssociation",
      "amplify:UpdateDomainAssociation",
      "amplify:DeleteDomainAssociation",
      "amplify:GetDomainAssociation",
      "amplify:ListDomainAssociations",
      "amplify:TagResource",
      "amplify:UntagResource",
      "amplify:ListTagsForResource",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DiscoverRoute53HostedZonesForAmplify"
    actions   = ["route53:ListHostedZones"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "frontend_apply" {
  name   = "villa-serena-frontend-apply"
  role   = aws_iam_role.frontend_apply.id
  policy = data.aws_iam_policy_document.frontend_apply.json
}
