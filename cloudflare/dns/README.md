# Cloudflare DNS — Villa Serena

Draft Terraform root to provision **only explicitly selected DNS hostnames**
as proxied CNAME records pointing to an **existing** Cloudflare Tunnel.

**No assumption about the Villa Serena production domain or zone ID.**
This deliberately does **not** create a Cloudflare zone, purchase or transfer
a domain, configure a Cloudflare Tunnel, or alter any apex, MX, SPF, DKIM,
DMARC, NS, or other DNS records. It also does not expose the EC2 public IPv4.

## Requirements

- Existing domain onboarded to Cloudflare and its `zone_id`.
- `CLOUDFLARE_API_TOKEN` with Zone DNS Edit permission for that zone.
- An existing tunnel UUID for DNS; this is **not** the secret tunnel token.
- Local R2 S3 credentials in the AWS shared profile `r2-terraform`.
- Terraform >= 1.10.

Use a local ignored `terraform.tfvars` (or environment variables) to specify
`zone_id`, `tunnel_id` and `tunnel_hostnames`. Example placeholders:

```hcl
zone_id = "0123456789abcdef0123456789abcdef"
tunnel_id = "11111111-2222-3333-4444-555555555555"
tunnel_hostnames = ["api.example.com"]
```

Choose actual zone and hostname values and inspect existing records
before applying. A CNAME can conflict with an existing record; **import
existing matching records into Terraform state rather than overwriting them**.

```bash
cd cloudflare/dns
terraform init
terraform fmt -check
terraform validate
terraform plan
```

The R2 state key is `cloudflare/dns/terraform.tfstate`. No Terraform
apply has been performed. Enabling a DNS record alone does not configure
the Cloudflare Tunnel public hostname/ingress routes: configure those
separately before publishing a working API endpoint.
