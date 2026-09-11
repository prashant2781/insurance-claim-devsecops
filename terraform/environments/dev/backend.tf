terraform {
  backend "s3" {
    key          = "insurance-claim/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
