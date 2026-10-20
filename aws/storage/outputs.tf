output "private_bucket" { value = aws_s3_bucket.application["private"].id }
output "public_bucket" { value = aws_s3_bucket.application["public"].id }
output "storage_region" { value = var.aws_region }
output "public_assets_url" { value = "https://${aws_cloudfront_distribution.public.domain_name}" }
output "cloudfront_distribution_id" { value = aws_cloudfront_distribution.public.id }
output "ec2_role_name" { value = data.aws_iam_role.api.name }
output "room_type_photos_prefix" {
  description = "Object-key prefix writable by the API role in the public assets bucket."
  value       = local.room_type_photos_prefix
}
