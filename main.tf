terraform {
  required_version = ">= 1.14.0"

  # These mirror your stack-level providers to help Core init in the prepare phase.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
