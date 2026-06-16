# Episode 3: The Vigilant State — Drift Detection & Remediation

## Series context
Part of "Mastering Infrastructure Lifecycle Management with Terraform" — 9-episode series.
Audience: Practitioners & Enterprise Architects (intermediate/advanced). ~15 min lightboard format.

## This episode
Goal: move from Day 1 deployment to Day N verification. Demonstrate HCP Terraform Stacks'
drift detection — scheduled refresh checks rolled up into a single Stack Health signal
(Green/Amber/Red) across multiple deployments — and targeted remediation that's still
governed by Sentinel policy-as-code.

## Architecture decision: Stacks, not workspaces (the opposite of Episode 2)
Episode 2 deliberately pivoted **off** Stacks onto plain HCP Terraform workspaces, because
Run Tasks aren't supported on Stacks at all, and Sentinel results never reliably appeared
against Stack plans in that round of testing. Episode 3 goes back to Stacks anyway, because
the entire narrative — one Stack Health rollup across multiple components/deployments,
targeted remediation scoped to just the drifted component, a single blueprint promoted across
environments — **only exists on Stacks**. There's no workspace equivalent of "Stack Health."

This repo is forked from `stacks-demo-ep2-tfe-series` (the archived Stacks attempt from
Episode 2's first pass), not from the live `tfe-series-ep2-guarding-the-estate` workspace repo.
Same underlying VPC → EKS → K8s App infrastructure, three deployments (dev, staging in
us-east-1; prod in us-west-2).

**Known, unfixed platform gap — don't re-debug this:** Run Tasks (Cloudability) do not attach
to Stacks. This repo carries forward **Vault** (dynamic credentials, zero static secrets) and
**Sentinel** (policy-as-code) from Episode 2's governance layer, but drops Cloudability
entirely. Episode 3's script claims remediation passes through "the same Sentinel and
Cloudability governance from Episode 2" — that claim is **adjusted in the actual recording**
to Sentinel only. Don't reintroduce a Cloudability/Run Task doc into this repo.

**Sentinel-on-Stacks status: provisional, pending live confirmation.** The original Stacks
attempt had `sentinel.hcl` wrapped in a `policy_set` block, which is the workspace-era format —
already fixed (wrapper removed) in the commit history this repo was forked from. Whether
Sentinel policy results now actually appear against a Stack plan needs to be confirmed live
in HCP Terraform before claiming it works on camera. If it still doesn't work, the
"Reconciling at Scale" section's governance-continuity claim needs to drop Sentinel too, and
become purely about reconciling state across deployments from one blueprint — without a
policy-evaluation payoff.

## Status: scaffolded, pending live Stack validation
- Stack components/deployments/Sentinel policies are in place (copied + renamed from the
  `-ep2` to `-ep3` naming convention — see Setup reference below)
- Not yet deployed to HCP Terraform under this repo
- Drift detection has not yet been enabled (it's a Stack-level UI setting, not HCL —
  see `docs/drift-detection-setup.md`)
- Demo flow not yet rehearsed live

## Setup reference
- Create a Stack in HCP Terraform connected to this repo (`tfe-series-ep3-the-vigilant-state`)
- AWS dynamic credentials: same OIDC issuer/role pattern as Episode 1/2 (`identity_token "aws"`
  in `deployments.tfdeploy.hcl`), trust policy already scoped to
  `organization:...:workspace:*:run_phase:*` from prior episodes — verify it still matches
- Vault dynamic credentials: this repo expects Vault JWT roles named
  `hcp-terraform-ep3-{dev,staging,prod}` (renamed from Episode 2's `-ep2` roles to avoid
  confusion/collision) and a KV path at `secret/ep3-demo/{environment}/app-config`. **These
  need to be created in Vault** — they don't exist yet under these names; see
  `tfe-series-ep2-guarding-the-estate`'s `CLAUDE.md` / README for the original `vault write`
  commands and substitute the new names
- Sentinel policy set: scope `sentinel/` from this repo to the new Stack
- Drift detection: enable per `docs/drift-detection-setup.md` — do this before rehearsing,
  the schedule cadence matters for how long you wait between drift injection and the health
  check flipping amber on camera

## Known gotchas (carried over from Episode 2's Stacks debugging — don't re-debug these)
- Sentinel has no `sprintf()` builtin — use `+` string concatenation and `string()` for
  scalar conversion (no list support). **Already fixed** in both
  `sentinel/allowed-instance-types.sentinel` and `sentinel/require-tags.sentinel` in this
  repo — don't reintroduce `sprintf` if editing these.
- Sentinel: `not x contains y` parses as `(not x) contains y` — always parenthesize:
  `not (x contains y)`. Same precedence trap applies to `and`/`or` mixing — `a and b or c`
  parses as `(a and b) or c`. **Already fixed** in `allowed-instance-types.sentinel`'s
  `node_groups` filter, which originally matched any resource type with an "update" action,
  not just `aws_eks_node_group` (the `and` and unparenthesized `or` mixed).
- Sentinel: multi-line function call argument lists can break the parser — keep calls on
  one line
- Sentinel policy set config (`sentinel/sentinel.hcl`) must NOT use the `policy_set { }`
  wrapper on Stacks — that's the workspace-era format. Bare `policy "name" { ... }` blocks
  at the top level, as this repo already has, is the Stack-compatible format (per the
  same-day fix this repo was forked from — still needs live confirmation it actually works)
- Stack outputs require an explicit `type` (already satisfied by `config_facts`)
- Component modules can't have inline `provider` blocks — providers must be declared at the
  Stack level via `providers.tfcomponent.hcl`
- `ephemeral = true` is not allowed on module outputs (only on variables) — the EKS auth
  token (`component.auth`, sourced from `modules/app_auth`) expires in ~15 minutes, so approve plans promptly rather than
  relying on marking anything ephemeral
- `.terraform.lock.hcl` generated on macOS lacks `linux_amd64` hashes HCP Terraform needs —
  regenerate with `terraform providers lock -platform=linux_amd64` from a plain
  `providers.tf` if this needs rebuilding. The `terraform stacks providers lock` command and
  `terraform stacks validate` both currently fail locally with a stacksplugin signature-auth
  error — Stack-level HCL can only be validated by actually pushing to HCP Terraform, not
  locally
- HCP Terraform workspace/Stack dynamic-credential env vars or identity tokens must be
  configured correctly per the Stack's deployment inputs, not bolted on after — easy to
  mis-categorize

## Demo flow (recording guide — see docs/demo-talk-track.md for full timestamps)
1. **The Hook** — Code Intent vs Cloud Reality, the "Drift" gap, Day 1 vs Day N
2. **Handshake Integrity** — inject real drift (`docs/drift-demo-runbook.md`), explain the
   refresh-only mechanism and the API-quota cost tradeoff, introduce Stack Health
3. **Stack-Level Drift Detection** — Stack Health rollup across all three deployments,
   targeted remediation (not auto-apply)
4. **Reconciling at Scale** — fix once in the shared component, promote across
   dev → staging → prod; remediation still passes Sentinel
5. **Bridge to Episode 4** — Terraform Actions / Reactive Fabric next; explicitly defer
   Continuous Validation to a future episode (it's a separate feature, out of scope here)

## Ep3→Ep5 handshake
`output.config_facts` (in `components.tfcomponent.hcl`) is unchanged from Episode 2's
contract and still feeds Episode 5's Ansible/AAP handshake. Keep it stable.
