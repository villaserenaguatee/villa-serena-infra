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

# Separate GitHub Actions identity for infrastructure configuration via Ansible.
# The role has no broad AWS administrator or EC2 mutation permissions.
data "aws_iam_policy_document" "infra_ansible_trust" {
  statement {
    sid     = "GitHubInfraMainOnly"
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
      values   = ["repo:villaserenaguatee@335120540/villa-serena-infra@1389591514:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "infra_ansible" {
  name               = "villa-serena-infra-ansible-role"
  description        = "GitHub Actions OIDC identity for configuration management via SSM"
  assume_role_policy = data.aws_iam_policy_document.infra_ansible_trust.json

  tags = {
    Project   = "villa-serena"
    ManagedBy = "terraform"
    Purpose   = "server-configuration"
  }
}

# Grant only session access to the managed Villa Serena instance.
# Ansible amazon.aws.aws_ssm also needs a dedicated S3 transfer bucket;
# those bucket-level permissions will be added with its configuration.
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "infra_ansible_ssm" {
  statement {
    sid       = "StartSessionToVillaSerenaCompute"
    actions   = ["ssm:StartSession"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/Name"
      values   = ["villa-serena-prod-app"]
    }
  }

  statement {
    sid       = "UseSessionManagerShell"
    actions   = ["ssm:StartSession"]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}::document/SSM-SessionManagerRunShell"]
  }

  statement {
    sid       = "ManageOwnSessions"
    actions   = ["ssm:TerminateSession", "ssm:ResumeSession"]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:*:${data.aws_caller_identity.current.account_id}:session/${aws:userid}-*"]
  }

  statement {
    sid       = "FindManagedInstance"
    actions   = ["ssm:DescribeInstanceInformation", "ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "infra_ansible_ssm" {
  name   = "villa-serena-ansible-ssm"
  role   = aws_iam_role.infra_ansible.id
  policy = data.aws_iam_policy_document.infra_ansible_ssm.json
}
