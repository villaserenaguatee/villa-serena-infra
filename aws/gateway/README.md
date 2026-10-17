# Villa Serena — AWS HTTP API Gateway (private integration)

Creates a small HTTP API Gateway that connects to the **existing** EC2's
private IPv4 through a VPC Link and AWS Cloud Map HTTP service discovery.

## Components

- HTTP API Gateway with the `$default` stage and route.
- VPC Link in the existing VPC and subnet.
- A dedicated VPC Link SG with egress restricted to TCP 8080 of the EC2 SG.
- One ingress rule on the existing EC2 SG allowing TCP 8080 **only from
  the VPC Link SG**. It does not allow traffic from the Internet.
- Cloud Map HTTP namespace, service and a registration using the **private**
  EC2 IPv4 and backend port.
- Separate R2 Terraform state key: `aws/gateway/terraform.tfstate`.

No NAT Gateway, load balancer, VPC interface endpoint, public EC2 backend
ingress or Cloudflare Tunnel is created.

## Important limitations

- **Run Spring Boot listening on host port 8080 before testing the API**.
  Until then the API endpoint will return an error. PostgreSQL must not
  expose a public port.
- The initial gateway is a **transport proxy**, not JWT-protected.
  Routes are publicly invocable; Spring Security must enforce authentication
  and authorization. Add a native JWT authorizer only once the actual issuer
  and audience are confirmed; protect relevant routes, not public endpoints.
- The `$default` route passes requests to Spring; WebSockets are NOT
  transparently supported through this HTTP API integration.
- The VPC Link uses the existing **single AZ** subnet. This suits the
  project's current budget but offers no AZ redundancy.
- Terraform queries one *running* EC2 by tag. Re-apply this stack after any
  EC2 replacement/private IP change to refresh Cloud Map registration.
- API Gateway VPC Link ENIs are managed by AWS and may take minutes to
  become available. AWS can mark unused links INACTIVE after 60 days.
- While the instance is on a public subnet, this integration addresses its
  private IPv4 only. No direct backend access is allowed from the Internet.

## Review / deploy

```bash
cd aws/gateway
terraform init
terraform fmt -check
terraform validate
terraform plan -var='aws_region=us-east-1'
```

Inspect the plan before `apply`; confirm no changes to existing EC2,
VPC, subnet or instance profile. Gateway adds one SG ingress rule on the
already existing EC2 security group.

```bash
terraform apply -var='aws_region=us-east-1'
terraform output -raw http_api_url
```

Test a **public** endpoint after Spring is running. Do not assume the
endpoint is protected by JWT until an authorizer is explicitly configured.
