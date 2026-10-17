# EC2 reads only the PostgreSQL password. The secret is created separately
# with the AWS CLI; Terraform must never store the password in its state.
data "aws_iam_policy_document" "ec2_postgres_password" {
  statement {
    sid       = "ReadPostgresPassword"
    actions   = ["ssm:GetParameter"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/villa-serena/prod/postgres/password"
    ]
  }
}

resource "aws_iam_role_policy" "ec2_postgres_password" {
  name   = "villa-serena-ec2-read-postgres-password"
  role   = "villa-serena-prod-ec2-role"
  policy = data.aws_iam_policy_document.ec2_postgres_password.json
}
