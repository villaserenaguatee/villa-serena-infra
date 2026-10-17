# EC2 bootstrap — Ansible via AWS Systems Manager

Configures the provisioned **Debian 13 ARM64** EC2 host only (not Cloudflare
Tunnel or application containers). There is **no SSH** and no SSH key.

## What the playbook changes

- Installs Docker Engine, Buildx and the Compose v2 plugin from Docker's
  official Debian `trixie` repository.
- Creates an idempotent **2048 MiB** root-owned swap file at `/swapfile`,
  persists it in `/etc/fstab`, and sets `vm.swappiness=10`.
- Enables the Docker systemd service.
- Leaves the preinstalled cloudflared service disabled.

The swap uses ~2 GiB of the 20 GiB EBS root disk. Swap helps absorb transient
memory pressure; it does **not** guarantee OOM cannot occur. Monitor memory,
disk usage and swap-in/out once PostgreSQL and Spring are running.

## Prerequisites before invoking from GitHub Actions

1. Merge and apply the **IAM/OIDC PR #6**, including the infra Ansible role.
2. Provision a **private, encrypted S3 transfer bucket** in the same AWS region
   as the instance. The `amazon.aws.aws_ssm` connection plugin uploads Ansible
   modules temporarily to S3. Configure bucket cleanup/lifecycle and block
   public access. Do **not** reuse the Terraform state bucket.
3. Give the **GitHub infra role** scoped `ssm:StartSession`, session describe/
   termination as required, plus S3 object transfer permissions to the bucket.
   Give the **EC2 instance role** access to read transferred S3 objects.
   Restrict both roles to this bucket. The current IAM PR does **not** supply
   these S3 permissions.
4. Define GitHub Actions repository variables:
   - `AWS_INFRA_ANSIBLE_ROLE_ARN`
   - `AWS_EC2_INSTANCE_ID`
   - `AWS_SSM_TRANSFER_BUCKET`
   - `AWS_REGION` (normally `us-east-1`)
5. Confirm the GitHub OIDC `sub` condition in PR #6 matches this repo's
   immutable GitHub repository ID before applying IAM.

The workflow is **manual dispatch only**, never executed on PRs or merges.
It runs from `main`; do not dispatch until prerequisites are complete.

## Local validation

```bash
python -m pip install ansible-core
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook -i 'localhost,' -c local ansible/playbooks/bootstrap.yml --syntax-check
```

## Verification on EC2 via SSM

```bash
swapon --show
free -h
sysctl vm.swappiness
docker version
docker compose version
systemctl is-enabled docker
```
