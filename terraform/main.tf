terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "insecure_claim_service" {
  name        = "insecure-claim-service-sg"
  description = "Controlled insecure security group for Checkov testing"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Insecure public SSH access for controlled testing"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "insecure-claim-service-sg"
    Environment = "security-testing"
    ManagedBy   = "Terraform"
  }
}
