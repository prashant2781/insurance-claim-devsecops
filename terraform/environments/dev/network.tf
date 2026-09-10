data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  resource_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_vpc" "dev" {
  # checkov:skip=CKV2_AWS_11:VPC Flow Logs will be enabled with centralized logging in QA and PROD
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.resource_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "dev" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "${local.resource_prefix}-igw"
  }
}

resource "aws_subnet" "public_a" {
  # checkov:skip=CKV_AWS_130:Public IP assignment is intentional for the cost-aware DEV Fargate design without a NAT Gateway
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.resource_prefix}-public-a"
    Tier = "Public"
  }
}

resource "aws_subnet" "public_b" {
  # checkov:skip=CKV_AWS_130:Public IP assignment is intentional for the cost-aware DEV Fargate design without a NAT Gateway
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.resource_prefix}-public-b"
    Tier = "Public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "${local.resource_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev.id
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_default_security_group" "dev" {
  vpc_id = aws_vpc.dev.id

  ingress = []
  egress  = []

  tags = {
    Name = "${local.resource_prefix}-default-sg-restricted"
  }
}
