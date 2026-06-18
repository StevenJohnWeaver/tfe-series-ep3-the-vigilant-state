# Identity tokens kept for the destroy run — AWS and Vault auth still required during destroy.
identity_token "aws" {
  audience = ["aws.workload.identity"]
}

identity_token "vault" {
  audience = ["vault.workload.identity"]
}

# All deployment blocks removed to trigger destroy plans in HCP Terraform.
# Episode 3 is now recorded from tfe-series-ep2-guarding-the-estate (workspace-based)
# because Stack Health (the core Ep3 narrative) is workspace-only as of this recording.
#
# Once HCP Terraform has approved and applied all destroy plans and the Stack shows
# no live infrastructure, delete the Stack from the HCP Terraform UI and archive this repo.
