# Ansible SSM transfer bucket

This addition belongs to the **existing** `aws/identity` Terraform state,
not a new backend. It provisions a dedicated S3 bucket and policies so the
`amazon.aws.aws_ssm` connection can exchange temporary Ansible modules.

- Bucket: `villa-serena-ansible-ssm-<account-id>-<aws-region>`.
- Default SSE-S3 encryption, blocked public access, owner-enforced object ownership.
- Transport requires HTTPS (explicit deny for insecure requests).
- Objects expire after **one day** (S3 lifecycle execution is asynchronous).
- `force_destroy = false`: safeguards against accidentally deleting live data.
- Permission grants confined to this bucket for the infra CI role and
  pre-existing EC2 role `villa-serena-prod-ec2-role`.
- The EC2 IAM role remains owned by the separate `aws/compute` state;
  this stack adds only a role policy.

## Review then apply

```bash
cd aws/identity
terraform fmt -check
terraform init
terraform validate
terraform plan -var="aws_region=us-east-1"
terraform apply -var="aws_region=us-east-1"
terraform output -raw ansible_ssm_transfer_bucket
```

Expected additions: S3 bucket + ownership, encryption, public access block,
lifecycle, bucket policy and two inline IAM policies. No EC2 replacement.

Put the bucket output in GitHub Actions repository variable
`AWS_SSM_TRANSFER_BUCKET` along with `AWS_REGION`,
`AWS_EC2_INSTANCE_ID`, and `AWS_INFRA_ANSIBLE_ROLE_ARN`.

**Important:** The SSM connection plugin's behavior and IAM permissions must
be exercised in a controlled bootstrap run before marking PR #14 ready.
The bucket is for transient code; don't upload application secrets.
