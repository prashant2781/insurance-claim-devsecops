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

resource "aws_security_group" "claim_service" {
  # checkov:skip=CKV2_AWS_5:Security group will be attached to the ECS service in the deployment milestone
  name        = "claim-service-sg"
  description = "Security group for the Insurance Claim Service"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow outbound HTTPS for approved external AWS service access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "claim-service-sg"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
