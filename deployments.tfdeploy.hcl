# Ep1: HCP Terraform issues an OIDC JWT for AWS authentication
identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# Ep2: A second OIDC JWT scoped to Vault — same issuer, different audience.
# This demonstrates that HCP Terraform can issue multiple fine-grained tokens
# from the same OIDC provider, each trusted only by its intended audience.
identity_token "vault" {
  audience = ["vault.workload.identity"]
}

deployment "development" {
  inputs = {
    region             = "us-east-1"
    role_arn           = "arn:aws:iam::314146291426:role/stacks-steve-weaver-demo-org-Stacks"
    identity_token     = identity_token.aws.jwt
    default_tags       = { environment = "dev", owner = "platform" }
    cluster_name       = "stacks-demo-dev-ep3"
    kubernetes_version = "1.30"
    vpc_cidr           = "10.100.0.0/16"
    environment        = "dev"
    # Carried over from Ep2: Vault dynamic credentials
    vault_addr           = "https://ep2-demo-public-vault-d5ee5dae.29f8fcee.z1.hashicorp.cloud:8200"
    vault_namespace      = "admin"
    vault_role           = "hcp-terraform-ep3-dev"
    vault_identity_token = identity_token.vault.jwt
  }
}

deployment "staging" {
  inputs = {
    region             = "us-east-1"
    role_arn           = "arn:aws:iam::314146291426:role/stacks-steve-weaver-demo-org-Stacks"
    identity_token     = identity_token.aws.jwt
    default_tags       = { environment = "staging", owner = "platform" }
    cluster_name       = "stacks-demo-stg-ep3"
    kubernetes_version = "1.30"
    vpc_cidr           = "10.101.0.0/16"
    environment        = "staging"
    # Carried over from Ep2: Vault dynamic credentials
    vault_addr           = "https://ep2-demo-public-vault-d5ee5dae.29f8fcee.z1.hashicorp.cloud:8200"
    vault_namespace      = "admin"
    vault_role           = "hcp-terraform-ep3-staging"
    vault_identity_token = identity_token.vault.jwt
  }
}

deployment "production" {
  inputs = {
    region             = "us-west-2"
    role_arn           = "arn:aws:iam::314146291426:role/stacks-steve-weaver-demo-org-Stacks"
    identity_token     = identity_token.aws.jwt
    default_tags       = { environment = "prod", owner = "platform" }
    cluster_name       = "stacks-demo-prd-ep3"
    kubernetes_version = "1.30"
    vpc_cidr           = "10.102.0.0/16"
    environment        = "prod"
    # Carried over from Ep2: Vault dynamic credentials
    vault_addr           = "https://ep2-demo-public-vault-d5ee5dae.29f8fcee.z1.hashicorp.cloud:8200"
    vault_namespace      = "admin"
    vault_role           = "hcp-terraform-ep3-prod"
    vault_identity_token = identity_token.vault.jwt
  }
}
