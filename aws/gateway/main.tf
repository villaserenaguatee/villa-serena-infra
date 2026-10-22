# Reference existing infrastructure without managing its state.
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["villa-serena-prod-vpc"]
  }
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["villa-serena-prod-public-1"]
  }
  vpc_id = data.aws_vpc.main.id
}

data "aws_security_group" "compute" {
  filter {
    name   = "group-name"
    values = ["villa-serena-prod-compute"]
  }
  vpc_id = data.aws_vpc.main.id
}

data "aws_instance" "app" {
  filter {
    name   = "tag:Name"
    values = ["villa-serena-prod-app"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

resource "aws_security_group" "vpc_link" {
  name        = "villa-serena-prod-apigw-vpc-link"
  description = "Outbound connections to the Villa Serena Spring backend."
  vpc_id      = data.aws_vpc.main.id

  tags = { Name = "villa-serena-prod-apigw-vpc-link" }
}

resource "aws_vpc_security_group_egress_rule" "to_backend" {
  security_group_id            = aws_security_group.vpc_link.id
  referenced_security_group_id = data.aws_security_group.compute.id
  ip_protocol                  = "tcp"
  from_port                    = var.backend_port
  to_port                      = var.backend_port
  description                  = "Only Spring Boot via the compute security group"
}

# Add one narrowly scoped ingress rule to the existing compute SG.
# The compute SG remains owned by aws/networking Terraform state.
resource "aws_vpc_security_group_ingress_rule" "from_vpc_link" {
  security_group_id            = data.aws_security_group.compute.id
  referenced_security_group_id = aws_security_group.vpc_link.id
  ip_protocol                  = "tcp"
  from_port                    = var.backend_port
  to_port                      = var.backend_port
  description                  = "Spring backend access from API Gateway VPC Link only"
}

resource "aws_apigatewayv2_vpc_link" "backend" {
  name               = "villa-serena-prod-vpc-link"
  subnet_ids         = [data.aws_subnet.public.id]
  security_group_ids = [aws_security_group.vpc_link.id]
  tags               = { Project = "villa-serena", ManagedBy = "terraform" }
}

# HTTP namespace: discovery by API, no Route53 private hosted zone required.
resource "aws_service_discovery_http_namespace" "backend" {
  name        = "villa-serena.internal"
  description = "HTTP service discovery for Villa Serena API Gateway"
}

resource "aws_service_discovery_service" "backend" {
  name         = "spring-api"
  namespace_id = aws_service_discovery_http_namespace.backend.id
}

# One manually managed EC2 instance: register the private address and host port.
# Replace/update this registration if the EC2 private IP changes.
resource "aws_service_discovery_instance" "backend" {
  instance_id = data.aws_instance.app.id
  service_id  = aws_service_discovery_service.backend.id
  attributes = {
    AWS_INSTANCE_IPV4 = data.aws_instance.app.private_ip
    AWS_INSTANCE_PORT = tostring(var.backend_port)
  }
}

resource "aws_apigatewayv2_api" "backend" {
  name          = "villa-serena-prod-http-api"
  protocol_type = "HTTP"
  description   = "Public HTTP API with private VPC Link integration"
  tags          = { Project = "villa-serena", ManagedBy = "terraform" }
}

resource "aws_apigatewayv2_integration" "backend" {
  api_id                 = aws_apigatewayv2_api.backend.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.backend.id
  integration_uri        = aws_service_discovery_service.backend.arn
  payload_format_version = "1.0"

  # Don't forward stage prefix to Spring.
  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

# Initial transport-only gateway: Spring Security remains the security boundary.
# Add JWT authorizer and explicitly scoped routes when auth contracts are settled.
resource "aws_apigatewayv2_route" "backend" {
  api_id    = aws_apigatewayv2_api.backend.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.backend.id
  name        = "$default"
  auto_deploy = true
  tags        = { Project = "villa-serena", ManagedBy = "terraform" }

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }
}
