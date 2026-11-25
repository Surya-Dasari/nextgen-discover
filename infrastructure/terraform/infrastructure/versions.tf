
terraform {
  required_version = ">= 1.16.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.3.0"
    }
  }
}

