component "network" {
  source = "./modules/network"
  providers = {
    aws = provider.aws.main
  }
  inputs = {
    name     = var.cluster_name
    vpc_cidr = var.vpc_cidr
  }
}

component "cluster" {
  source = "./modules/cluster"
  providers = {
    aws       = provider.aws.main
    random    = provider.random.main
    time      = provider.time.main
    tls       = provider.tls.main
    cloudinit = provider.cloudinit.main
    null      = provider.null.main
  }
  inputs = {
    cluster_name        = var.cluster_name
    kubernetes_version  = var.kubernetes_version
    vpc_id              = component.network.vpc_id
    subnet_ids          = component.network.public_subnet_ids
  }
}

component "auth" {
  source = "./modules/app_auth"
  providers = {
    aws = provider.aws.main
  }
  inputs = {
    cluster_name = component.cluster.cluster_name
  }
}

component "app" {
  source = "./modules/app"
  providers = {
    kubernetes = provider.kubernetes.main
  }
}

# Ep2: Vault dynamic credentials — reads secrets from HCP Vault using
# the OIDC JWT issued by HCP Terraform. No static secrets in config.
# Depends on auth so IAM context is established first.
component "secrets" {
  source = "./modules/secrets"
  providers = {
    vault = provider.vault.main
  }
  inputs = {
    environment = var.environment
  }
  depends_on = [component.auth]
}

# Ep2→Ep5 bridge: expose stable facts for the Ansible handshake in Episode 5.
# These outputs mirror the 'config_facts' contract described in the series.
output "config_facts" {
  description = "Stable infrastructure metadata for downstream configuration (AAP, Ep5)"
  type = object({
    cluster_endpoint = string
    environment      = string
    region           = string
    vault_secret_ver = number
  })
  value = {
    cluster_endpoint = component.cluster.cluster_url
    environment      = var.environment
    region           = var.region
    vault_secret_ver = component.secrets.secret_version
  }
}
