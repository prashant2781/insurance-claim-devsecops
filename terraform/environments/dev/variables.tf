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
