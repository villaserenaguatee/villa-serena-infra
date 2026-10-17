# GitHub Actions only sends SSM Run Command to the existing application EC2.
# Instance IAM is used to fetch application config from Parameter Store.
data "aws_instance" "api_deploy_target" {
  filter {
    name   = "tag:Name"
    values = ["villa-serena-prod-app"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_iam_policy_document" "api_deploy_commands" {
  statement {
    sid       = "SendShellScriptToVillaSerena"
    actions   = ["ssm:SendCommand"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}::document/AWS-RunShellScript",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${data.aws_instance.api_deploy_target.id}"
    ]
  }

  statement {
    sid       = "ReadDeploymentCommandStatus"
    actions   = ["ssm:GetCommandInvocation"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "api_deploy_commands" {
  name   = "villa-serena-api-deploy-ssm"
  role   = aws_iam_role.api_deploy.id
  policy = data.aws_iam_policy_document.api_deploy_commands.json
}

data "aws_iam_policy_document" "ec2_api_runtime_parameters" {
  statement {
    sid       = "ReadApiParameterPath"
    actions   = ["ssm:GetParametersByPath", "ssm:GetParameter"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/villa-serena/prod/api",
      "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/villa-serena/prod/api/*"
    ]
  }
}

resource "aws_iam_role_policy" "ec2_api_runtime_parameters" {
  name   = "villa-serena-ec2-read-api-config"
  role   = "villa-serena-prod-ec2-role"
  policy = data.aws_iam_policy_document.ec2_api_runtime_parameters.json
}
