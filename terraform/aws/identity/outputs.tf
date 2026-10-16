output "api_deploy_role_arn" {
  description = "Use as role-to-assume in villa-serena-api GitHub Actions."
  value       = aws_iam_role.api_deploy.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}
