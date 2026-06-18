# Vault Setup for Episode 3

Complete commands to configure HCP Vault for this Stack's dynamic credentials. Run these
against the HCP Vault cluster referenced in `deployments.tfdeploy.hcl`
(`vault_addr = "https://ep2-demo-public-vault-..."`) with the `admin` namespace.

```shell
export VAULT_ADDR="https://ep2-demo-public-vault-d5ee5dae.29f8fcee.z1.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"
# vault login <your-token>
```

---

## 1. Enable JWT Auth (once per cluster — skip if already enabled from Ep2)

```shell
vault auth enable jwt

vault write auth/jwt/config \
  oidc_discovery_url="https://app.terraform.io" \
  bound_issuer="https://app.terraform.io"
```

---

## 2. Create Vault Policies

Each deployment gets a policy scoped to its own KV path.

```shell
vault policy write ep3-dev - <<EOF
path "secret/data/ep3-demo/dev/*" {
  capabilities = ["read"]
}
path "auth/token/create" {
  capabilities = ["create", "update"]
}
EOF

vault policy write ep3-staging - <<EOF
path "secret/data/ep3-demo/staging/*" {
  capabilities = ["read"]
}
path "auth/token/create" {
  capabilities = ["create", "update"]
}
EOF

vault policy write ep3-prod - <<EOF
path "secret/data/ep3-demo/prod/*" {
  capabilities = ["read"]
}
path "auth/token/create" {
  capabilities = ["create", "update"]
}
EOF
```

---

## 3. Create JWT Roles

HCP Terraform Stacks issue OIDC `identity_token` JWTs (configured in
`deployments.tfdeploy.hcl`). The audience is `vault.workload.identity`.

**Important:** Stacks identity tokens do NOT include a `terraform_workspace_name` claim —
that claim only exists on workspace runs. Use `user_claim="sub"` instead, which is always
present. The Stacks `sub` claim follows this format:
`organization:<org>:project:<project>:stack:<stack-name>:deployment:<deployment-name>:operation:<operation>`

```shell
vault write auth/jwt/role/hcp-terraform-ep3-dev \
  role_type="jwt" \
  bound_audiences="vault.workload.identity" \
  user_claim="sub" \
  policies="ep3-dev" \
  ttl="1h"

vault write auth/jwt/role/hcp-terraform-ep3-staging \
  role_type="jwt" \
  bound_audiences="vault.workload.identity" \
  user_claim="sub" \
  policies="ep3-staging" \
  ttl="1h"

vault write auth/jwt/role/hcp-terraform-ep3-prod \
  role_type="jwt" \
  bound_audiences="vault.workload.identity" \
  user_claim="sub" \
  policies="ep3-prod" \
  ttl="1h"
```

> **Tightening for production:** add a `bound_claims` constraint to pin the role to the
> specific Stack and deployment, using the `sub` format above with glob matching:
> `bound_claims_type="glob"` and
> `bound_claims='{"sub":"organization:<org>:project:*:stack:<stack-name>:deployment:development:operation:*"}'`

---

## 4. Enable KV v2 and Write Secrets (once per cluster — skip the `secrets enable` if already done from Ep2)

```shell
vault secrets enable -path=secret kv-v2

vault kv put secret/ep3-demo/dev/app-config \
  db_host="demo-db.internal" \
  api_key="DEMO"

vault kv put secret/ep3-demo/staging/app-config \
  db_host="demo-db-stg.internal" \
  api_key="DEMO"

vault kv put secret/ep3-demo/prod/app-config \
  db_host="demo-db-prd.internal" \
  api_key="DEMO"
```

---

## 5. Verify

After the Stack deploys its first plan successfully, confirm each deployment read its secret
by checking the run logs. Look for a Vault auth exchange followed by a KV read in the
`secrets` component's plan output — no static token should appear anywhere.

---

## Notes

- These role names (`hcp-terraform-ep3-*`) and KV paths (`secret/ep3-demo/*`) are renamed
  from Ep2's `-ep2` equivalents to avoid collision if the Ep2 workspace setup coexists in
  the same cluster.
- The `secrets enable` and `auth enable jwt` commands are idempotent to check but will error
  if the path is already mounted — that's safe to ignore.
- `vault_namespace = "admin"` is set in the deployment inputs; make sure your `VAULT_NAMESPACE`
  env var matches when running these commands.
