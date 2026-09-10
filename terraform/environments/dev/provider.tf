provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "InsuranceClaim"
      Environment = "DEV"
      ManagedBy   = "Terraform"
      Repository  = "insurance-claim-devsecops"
    }
  }
}
