resource "aws_amplify_app" "web" {
  name                     = "villa-serena-web"
  repository               = "https://github.com/villaserenaguatee/villa-serena-web"
  access_token             = var.github_access_token
  platform                 = "WEB_COMPUTE"
  enable_branch_auto_build = true

  build_spec = <<-YAML
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - corepack enable
            - pnpm install --frozen-lockfile
        build:
          commands:
            - pnpm build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
          - .next/cache/**/*
  YAML
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.web.id
  branch_name = "main"
  stage       = "PRODUCTION"
  framework   = "Next.js - SSR"
}

resource "aws_amplify_domain_association" "web" {
  app_id                = aws_amplify_app.web.id
  domain_name           = var.domain_name
  wait_for_verification = false

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "web"
  }
}

output "amplify_default_domain" {
  value = aws_amplify_app.web.default_domain
}

output "domain_verification_dns_record" {
  value = aws_amplify_domain_association.web.certificate_verification_dns_record
}
