# Episode 3 Demo: The Vigilant State — Drift Detection & Remediation

This repo extends the Episode 1/2 Stack with **Day N verification**: scheduled drift
detection rolled up into a single Stack Health signal, plus targeted, policy-governed
remediation.

The underlying Stack (VPC → EKS → Kubernetes App across dev/staging/prod) is unchanged.
Vault dynamic credentials and Sentinel policy-as-code carry over from Episode 2's governance
layer. Every addition in this repo is at the **health/drift** layer.

> **Why Stacks, and not the Episode 2 workspace repo?** Stack Health — a single rollup status
> aggregating per-component drift across every deployment — only exists on Stacks. See
> `CLAUDE.md` for the full architecture rationale, including the known gap (Run Tasks /
> Cloudability don't attach to Stacks) that this repo deliberately works around.

---

## What's New vs Episode 2

| Layer | What it adds |
|---|---|
| Stack Health (HCP Terraform UI setting) | Scheduled refresh-only drift checks, rolled up into one Green/Amber/Red signal per Stack |
| `docs/drift-detection-setup.md` | How to enable and tune the drift-check schedule |
| `docs/drift-demo-runbook.md` | Concrete, reversible steps to inject real drift and trigger a targeted remediation plan |
| Sentinel policies | Same two policies as Episode 2, with a `sprintf` fix and an operator-precedence fix applied (see `CLAUDE.md`) |

**Dropped from Episode 2:** the Cloudability Run Task — it doesn't attach to Stacks. Vault and
Sentinel are the carried-over governance pillars here.

---

## Prerequisites

- Terraform CLI 1.14+ (optional — can run entirely in the HCP Terraform UI)
- HCP Terraform org with **Stacks** and **Sentinel** enabled, and **Stack Health / drift
  detection** available
- AWS OIDC trust for HCP Terraform (same as Episodes 1/2)
- HCP Vault cluster with JWT auth method enabled

---

## Quick Start

### 1. Connect the Stack

1. Create a Stack in HCP Terraform, connected to this repo
2. Verify `role_arn` values in `deployments.tfdeploy.hcl` match your AWS account

### 2. Configure Vault JWT Auth

This repo uses new role/path names (`-ep3` instead of `-ep2`) to avoid colliding with
Episode 2's Vault config:

```shell
vault write auth/jwt/role/hcp-terraform-ep3-dev \
  role_type="jwt" \
  bound_audiences="vault.workload.identity" \
  user_claim="terraform_workspace_name" \
  policies="ep3-dev" \
  ttl="1h"
# repeat for -staging and -prod

vault kv put secret/ep3-demo/dev/app-config db_host="demo-db.internal" api_key="DEMO"
vault kv put secret/ep3-demo/staging/app-config db_host="demo-db-stg.internal" api_key="DEMO"
vault kv put secret/ep3-demo/prod/app-config db_host="demo-db-prd.internal" api_key="DEMO"
```

### 3. Attach Sentinel Policies

1. In HCP Terraform → **Policies** → **Policy Sets** → **Create Policy Set**
2. Connect this repo, set the path to `sentinel/`
3. Scope to this Stack

### 4. Enable Drift Detection

Follow `docs/drift-detection-setup.md` — Stack Settings → Health, no HCL involved.

### 5. Rehearse the Drift Demo

Follow `docs/drift-demo-runbook.md` for the exact, reversible steps to inject drift and
trigger a targeted remediation plan before recording.

---

## Structure

```
.
├── components.tfcomponent.hcl   # Stack components (network, cluster, auth, app, secrets)
├── deployments.tfdeploy.hcl     # Three deployments + two OIDC identity tokens
├── providers.tfcomponent.hcl    # AWS, Kubernetes, Vault providers
├── variables.tfcomponent.hcl    # All Stack input variables
├── modules/
│   ├── network/                 # VPC
│   ├── cluster/                 # EKS
│   ├── app_auth/                # EKS auth
│   ├── app/                     # Kubernetes app
│   └── secrets/                 # Vault KV read via OIDC
├── sentinel/
│   ├── sentinel.hcl              # Policy set config (Stack-compatible format)
│   ├── allowed-instance-types.sentinel
│   └── require-tags.sentinel
└── docs/
    ├── drift-detection-setup.md  # Enabling/tuning Stack Health drift checks
    ├── drift-demo-runbook.md     # Reversible steps to inject drift for the recording
    └── demo-talk-track.md        # Timestamped recording script
```
