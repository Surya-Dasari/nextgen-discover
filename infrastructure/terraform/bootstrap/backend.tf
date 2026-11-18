terraform {
  backend "s3" {
    bucket       = "nextgen-discover-terraform-state-659071697866-us-east-2"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
