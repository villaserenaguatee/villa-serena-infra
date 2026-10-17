# Dedicated short-lived module exchange for the Ansible amazon.aws.aws_ssm
# connection plugin. Never use the Terraform state bucket for this purpose.
locals {
  ansible_transfer_bucket_name = "villa-serena-ansible-ssm-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  ansible_transfer_object_arn  = "${aws_s3_bucket.ansible_transfer.arn}/*"
}

resource "aws_s3_bucket" "ansible_transfer" {
  bucket        = local.ansible_transfer_bucket_name
  force_destroy = false

  tags = {
    Project   = "villa-serena"
    ManagedBy = "terraform"
    Purpose   = "ansible-ssm-transfers"
  }
}

resource "aws_s3_bucket_public_access_block" "ansible_transfer" {
  bucket                  = aws_s3_bucket.ansible_transfer.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id
  rule {
    id     = "expire-ansible-artifacts"
    status = "Enabled"
    filter {
      prefix = ""
    }
    expiration {
      days = 1
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

data "aws_iam_policy_document" "ansible_transfer_bucket" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [aws_s3_bucket.ansible_transfer.arn, local.ansible_transfer_object_arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id
  policy = data.aws_iam_policy_document.ansible_transfer_bucket.json
  depends_on = [aws_s3_bucket_public_access_block.ansible_transfer]
}

data "aws_iam_policy_document" "ansible_transfer_access" {
  statement {
    sid       = "ListAnsibleTransferBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.ansible_transfer.arn]
  }
  statement {
    sid       = "TransferAnsibleModules"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [local.ansible_transfer_object_arn]
  }
}

resource "aws_iam_role_policy" "infra_ansible_transfer" {
  name   = "villa-serena-ansible-s3-transfer"
  role   = aws_iam_role.infra_ansible.id
  policy = data.aws_iam_policy_document.ansible_transfer_access.json
}

# Instance profile/role are owned by aws/compute state. An independent inline
# policy references the *existing* role by name without managing that role.
resource "aws_iam_role_policy" "ec2_ansible_transfer" {
  name   = "villa-serena-ec2-ansible-s3-transfer"
  role   = "villa-serena-prod-ec2-role"
  policy = data.aws_iam_policy_document.ansible_transfer_access.json
}
