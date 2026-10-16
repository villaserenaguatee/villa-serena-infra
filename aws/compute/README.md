# AWS compute — Villa Serena

**Requires PR #7 networking to be merged AND applied first** in the same
AWS account and region. Data sources discover the subnet and zero-ingress
Security Group through their stable names.

- EC2 `t4g.small` (ARM64) using the latest official Debian 13 image
  published by owner `136693071363`
- 20 GB encrypted gp3 root EBS, retained on termination
- IMDSv2 mandatory, hop limit 2, public dynamic IPv4
- No SSH key; `AmazonSSMManagedInstanceCore` attached to instance role
- cloud-init installs SSM Agent (not preinstalled on Debian) and
  cloudflared. Docker/Compose and application containers are intentionally
  excluded; Ansible will manage them separately.
- Cloudflare tunnel token expected as an existing SSM `SecureString`,
  read by the instance role only; no token value enters Terraform state.
- Tunnel service defaults to disabled until the token is created externally
  and the setup has been reviewed (`enable_cloudflared=true`).
- SSM Run Command permissions for GitHub Actions are NOT part of this PR.
- Independent Cloudflare R2 state key: `aws/compute/terraform.tfstate`.

**Review points:** IAM minimum permissions, correct region, AMI match,
SSM Agent bootstrap on Debian 13, cloudflared download URL,
Cloudflare Tunnel token existence, and external data backups. Retaining
root EBS on termination avoids accidental deletion but will continue
incurring charges and requires cleanup/recovery management.

```bash
cd aws/compute
terraform init
terraform fmt -check
terraform validate
terraform plan
```

The commands above have not been executed in AWS. Do not apply until the
network resources exist and the bootstrap has been validated. Public IPv4
and EBS usage are billable.
