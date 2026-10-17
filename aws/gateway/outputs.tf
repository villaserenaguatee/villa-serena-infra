output "http_api_url" {
  value       = aws_apigatewayv2_api.backend.api_endpoint
  description = "Public HTTP API endpoint; requires Spring backend to be running to respond."
}

output "http_api_id" {
  value = aws_apigatewayv2_api.backend.id
}

output "vpc_link_id" {
  value = aws_apigatewayv2_vpc_link.backend.id
}

output "cloud_map_service_arn" {
  value = aws_service_discovery_service.backend.arn
}

output "registered_backend_private_ip" {
  value = data.aws_instance.app.private_ip
}

output "custom_api_url" {
  description = "Stable public HTTPS API endpoint after ACM and DNS validation."
  value       = "https://${aws_apigatewayv2_domain_name.api.domain_name}"
}
