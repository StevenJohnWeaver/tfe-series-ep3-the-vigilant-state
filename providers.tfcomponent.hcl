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
  # Ep2: Vault provider for dynamic secret management
  vault = {
    source  = "hashicorp/vault"
    version = "~> 4.0"
  }
  # Missing providers required by the EKS module
  time      = { source = "hashicorp/time",     version = "~> 0.9" }
  tls       = { source = "hashicorp/tls",      version = "~> 4.0" }
  cloudinit = { source = "hashicorp/cloudinit", version = "~> 2.3" }
  null      = { source = "hashicorp/null",      version = "~> 3.2" }
}

provider "aws" "main" {
  config {
    region = var.region

    assume_role_with_web_identity {
      role_arn           = var.role_arn
      web_identity_token = var.identity_token
    }

    default_tags { tags = var.default_tags }
  }
}

# Smart Handshake: provider wired to EKS outputs from the 'cluster' component.
# Stacks will defer planning/applying 'app' until these are known.
provider "kubernetes" "main" {
  config {
    host                   = component.cluster.cluster_url
    cluster_ca_certificate = component.cluster.cluster_ca
    token                  = component.auth.token
  }
}

# Ep2: Vault provider — configured per-component in modules/secrets/main.tf.
# Authentication uses the OIDC JWT from HCP Terraform (vault identity_token),
# so no static Vault token ever appears in configuration.
# The provider block at the Stack level declares the requirement only;
# the actual auth_login_jwt config lives inside the secrets module.
provider "vault" "main" {
  config {
    address   = var.vault_addr
    namespace = var.vault_namespace

    auth_login_jwt {
      role = var.vault_role
      jwt  = var.vault_identity_token
    }
  }
}

provider "random" "main" {}
provider "time" "main" {}
provider "tls" "main" {}
provider "cloudinit" "main" {}
provider "null" "main" {}
