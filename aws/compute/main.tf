# Network resources belong to the independent networking Terraform root.
# Tag lookups require networking to be applied first, in the same AWS region.
data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["villa-serena-prod-public-1"]
  }
}
data "aws_security_group" "compute" {
  filter {
    name   = "group-name"
    values = ["villa-serena-prod-compute"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_subnet.public.vpc_id]
  }
}

# Debian Cloud Team official image owner; ARM64 image selected per region.
data "aws_ami" "debian13" {
  most_recent = true
  owners      = ["136693071363"]
  filter {
    name   = "name"
    values = ["debian-13-arm64-*"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "instance_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "instance" {
  name               = "villa-serena-prod-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.instance_trust.json
}
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
data "aws_iam_policy_document" "tunnel_token" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.cloudflare_tunnel_parameter_name}"]
  }
}
resource "aws_iam_role_policy" "tunnel_token" {
  name   = "read-cloudflare-tunnel-token"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.tunnel_token.json
}
resource "aws_iam_instance_profile" "instance" {
  name = "villa-serena-prod-ec2-profile"
  role = aws_iam_role.instance.name
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.debian13.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.public.id
  vpc_security_group_ids      = [data.aws_security_group.compute.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.instance.name
  monitoring                  = false

  # No SSH key. Administrative access is exclusively through SSM.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = false
  }

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    aws_region         = var.aws_region
    cloudflare_param   = var.cloudflare_tunnel_parameter_name
    enable_cloudflared = var.enable_cloudflared
  })

  lifecycle {
    ignore_changes = [ami]
  }
  tags = { Name = "villa-serena-prod-app" }
}
