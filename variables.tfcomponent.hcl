variable "region"            { type = string }
variable "role_arn"          { type = string }
variable "identity_token" {
  type        = string
  description = "HCP Terraform OIDC JWT for AWS authentication"
  sensitive   = true
  ephemeral   = true
}
variable "default_tags"       { type = map(string) }
variable "cluster_name"       { type = string }
variable "kubernetes_version"  { type = string }
variable "vpc_cidr"           { type = string }
variable "environment"        {
  type        = string
  description = "Deployment environment label (dev, staging, prod)"
}

# Ep2: Vault dynamic credentials
variable "vault_addr" {
  type        = string
  description = "HCP Vault cluster address (e.g. https://xxx.vault.hashicorp.cloud)"
}
variable "vault_namespace" {
  type        = string
  description = "HCP Vault namespace"
  default     = "admin"
}
variable "vault_role" {
  type        = string
  description = "Vault JWT auth role configured for HCP Terraform OIDC"
}
variable "vault_identity_token" {
  type        = string
  description = "HCP Terraform OIDC JWT for Vault authentication"
  sensitive   = true
  ephemeral   = true
}
