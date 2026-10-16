# AWS networking — Villa Serena

Independent Terraform root and Cloudflare R2 state key: `aws/networking/terraform.tfstate`.

Single VPC (10.20.0.0/16), one public IPv4 subnet (10.20.1.0/24), Internet Gateway, default route to internet and one EC2 Security Group with **no ingress**. Egress is deliberately unrestricted during bootstrap to support SSM, package registries and Cloudflare Tunnel; review later.

No NAT Gateway, Elastic IP, EC2 or SSH rules. Public IPv4 addresses incur AWS hourly charges. Availability zone is the first available in the selected region; confirm instance type capacity before apply.

The existing Cloudflare R2 backend requires local R2 credentials. Configure AWS provider credentials separately.

```bash
cd terraform/aws/networking
terraform init
terraform fmt -check
terraform validate
terraform plan
```

**Review plan before apply. No resources have been applied by this PR.**
