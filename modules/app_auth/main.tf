terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.28" }
  }
}

variable "cluster_name" { type = string }

# This data source *must* run after the cluster exists; because this runs in a later
# component, Stacks will naturally defer planning/applying at the component boundary.
data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

output "token" {
  value     = data.aws_eks_cluster_auth.this.token
  sensitive = true
}
