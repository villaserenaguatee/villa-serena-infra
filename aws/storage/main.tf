data "aws_caller_identity" "current" {}
data "aws_iam_role" "api" { name = var.ec2_role_name }

locals {
  room_type_photos_prefix = "tipos/"
}

resource "aws_s3_bucket" "application" {
  for_each      = toset(["public", "private"])
  bucket        = "villa-serena-prod-${each.key}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  force_destroy = false
  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_s3_bucket_public_access_block" "application" {
  for_each                = aws_s3_bucket.application
  bucket                  = each.value.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_ownership_controls" "application" {
  for_each = aws_s3_bucket.application
  bucket   = each.value.id
  rule { object_ownership = "BucketOwnerEnforced" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "application" {
  for_each = aws_s3_bucket.application
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}
resource "aws_s3_bucket_versioning" "application" {
  for_each = aws_s3_bucket.application
  bucket   = each.value.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_lifecycle_configuration" "application" {
  for_each = aws_s3_bucket.application
  bucket   = each.value.id
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    filter { prefix = "" }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}
resource "aws_s3_bucket_cors_configuration" "application" {
  for_each = aws_s3_bucket.application
  bucket   = each.value.id
  cors_rule {
    allowed_origins = var.allowed_origins
    allowed_methods = ["GET", "HEAD"]
    expose_headers  = ["ETag", "Content-Disposition"]
    max_age_seconds = 3600
  }
}

# Public content is served through CloudFront; neither bucket is anonymous S3.
resource "aws_cloudfront_origin_access_control" "public" {
  name                              = "villa-serena-prod-public-assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
data "aws_cloudfront_cache_policy" "optimized" { name = "Managed-CachingOptimized" }
resource "aws_cloudfront_response_headers_policy" "public" {
  name = "villa-serena-prod-public-assets"
  cors_config {
    access_control_allow_credentials = false
    access_control_allow_headers { items = ["*"] }
    access_control_allow_methods { items = ["GET", "HEAD"] }
    access_control_allow_origins { items = var.allowed_origins }
    access_control_expose_headers { items = ["ETag", "Content-Disposition"] }
    access_control_max_age_sec = 3600
    origin_override            = true
  }
}
resource "aws_cloudfront_distribution" "public" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Villa Serena public assets only"
  price_class     = "PriceClass_100"
  origin {
    domain_name              = aws_s3_bucket.application["public"].bucket_regional_domain_name
    origin_id                = "public-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.public.id
  }
  default_cache_behavior {
    target_origin_id           = "public-assets"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.public.id
  }
  restrictions {
    geo_restriction { restriction_type = "none" }
  }
  viewer_certificate { cloudfront_default_certificate = true }
}

data "aws_iam_policy_document" "bucket" {
  for_each = aws_s3_bucket.application
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  dynamic "statement" {
    for_each = each.key == "public" ? [true] : []
    content {
      sid       = "CloudFrontPublicAssetsOnly"
      actions   = ["s3:GetObject"]
      resources = ["${each.value.arn}/*"]
      principals {
        type        = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "AWS:SourceArn"
        values   = [aws_cloudfront_distribution.public.arn]
      }
    }
  }
}
resource "aws_s3_bucket_policy" "application" {
  for_each   = aws_s3_bucket.application
  bucket     = each.value.id
  policy     = data.aws_iam_policy_document.bucket[each.key].json
  depends_on = [aws_s3_bucket_public_access_block.application]
}

data "aws_iam_policy_document" "api" {
  statement {
    sid       = "ReadAndWritePrivateApplicationObjects"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.application["private"].arn}/*"]
  }
  statement {
    sid       = "DetectMissingPrivateObjects"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.application["private"].arn]
  }
  statement {
    sid       = "RemoveOnlyExplicitSmokeTestObjects"
    actions   = ["s3:DeleteObject"]
    resources = ["${aws_s3_bucket.application["private"].arn}/_checks/*"]
  }
}
resource "aws_iam_role_policy" "api" {
  name   = "villa-serena-api-private-storage"
  role   = data.aws_iam_role.api.id
  policy = data.aws_iam_policy_document.api.json
}

data "aws_iam_policy_document" "room_type_photos" {
  statement {
    sid       = "ReadAndWriteRoomTypePhotos"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.application["public"].arn}/${local.room_type_photos_prefix}*"]
  }
}

resource "aws_iam_role_policy" "room_type_photos" {
  name   = "villa-serena-api-room-type-photos"
  role   = data.aws_iam_role.api.id
  policy = data.aws_iam_policy_document.room_type_photos.json
}
