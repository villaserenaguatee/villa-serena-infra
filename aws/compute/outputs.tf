output "instance_id" { value = aws_instance.app.id }
output "instance_private_ip" { value = aws_instance.app.private_ip }
output "instance_public_ip" { value = aws_instance.app.public_ip }
output "instance_profile_name" { value = aws_iam_instance_profile.instance.name }
output "debian_ami_id" { value = data.aws_ami.debian13.id }
