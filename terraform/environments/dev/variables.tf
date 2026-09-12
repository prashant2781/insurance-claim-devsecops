variable "aws_region" {
  description = "AWS Region for the DEV environment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for AWS resource naming"
  type        = string
  default     = "insurance-claim"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "container_image" {
  description = "Immutable ECR image URI including the sha256 digest"
  type        = string
}

variable "allowed_origins" {
  description = "Comma-separated browser origins allowed to call the Claim Service"
  type        = string
  default     = "http://insurance-portal-dev-335048986277-ap-south-1.s3-website.ap-south-1.amazonaws.com"
}
