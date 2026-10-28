output "api_deploy_role_arn" {
  description = "Use as role-to-assume in villa-serena-api GitHub Actions."
  value       = aws_iam_role.api_deploy.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}

output "infra_ansible_role_arn" {
  description = "Role assumed by the villa-serena-infra workflow for SSM-based Ansible."
  value       = aws_iam_role.infra_ansible.arn
}

output "ansible_ssm_transfer_bucket" {
  description = "Use as the AWS_SSM_TRANSFER_BUCKET Actions variable for Ansible."
  value       = aws_s3_bucket.ansible_transfer.bucket
}

output "frontend_plan_role_arn" {
  description = "OIDC role ARN for automatic frontend Terraform plans."
  value       = aws_iam_role.frontend_plan.arn
}
