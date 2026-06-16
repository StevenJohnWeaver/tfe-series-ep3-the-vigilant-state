# Drift Demo Runbook

The point of this runbook is to produce **real, visible drift** safely and reversibly, so
the recording shows an actual Stack Health flip instead of a staged screenshot.

> **Important caveat (this *is* the lesson, not a limitation to work around):** drift
> detection only re-checks resources Terraform already has in state. A brand-new resource
> created entirely outside Terraform (e.g. a new security group rule nobody declared) is
> invisible to it — there's nothing in state to compare against. To get a real drift signal,
> the manual change has to modify an **attribute of a resource Terraform already manages**.
> This is worth saying out loud on camera; it's exactly the "Terraform doesn't manage what it
> doesn't manage" point the script's Hook section makes.

---

## Demo A (primary): Tag drift on the VPC — ties straight into Sentinel governance

This is the most reliable option: tags are a core tracked attribute on every resource
Terraform manages via `default_tags`, so the drift always shows up, it's impossible to break
connectivity by changing a tag, and it pays off the "Reconciling at Scale" section's claim
that remediation still passes through Sentinel (`require-tags`).

1. **Confirm baseline:** Stack is healthy (Green), all three deployments applied cleanly.
2. **Inject drift:** In the AWS Console, open the `dev` deployment's VPC (`stacks-demo-dev-ep3`
   — find it via the `network` component's `vpc_id` output) → **Tags** tab → remove the
   `owner` tag (or edit its value to something obviously wrong, e.g. `unknown`).
3. **Trigger the check:** In HCP Terraform, open the Stack → **Check Health Now** (see
   `drift-detection-setup.md`).
4. **On camera:** Stack Health flips from Green to **Amber**. Click in — the `network`
   component for `development` shows the drift: `tags.owner` differs between state and
   live reality.
5. **Remediate:** From the drifted component, start a **targeted remediation plan** — note
   it only plans the `network` component for the `dev` deployment, not all nine
   component/deployment pairs across the Stack.
6. **Show the plan:** Terraform proposes restoring `owner = "platform"` (from `default_tags`).
   Sentinel's `require-tags` policy evaluates this plan and passes cleanly — proving
   remediation can't silently reintroduce a tagging violation.
7. **Approve and apply.** Stack Health returns to Green.
8. **Revert:** Nothing to revert — the apply already restored the correct tag.

---

## Demo B (optional, for visual variety): Security group rule description drift

Mirrors the Hook section's "toggling a firewall rule" line more literally. Slightly more
fragile to set up than Demo A — use only if you want a second drift example on camera.

1. In the AWS Console, find the **node security group** for the `dev` EKS cluster
   (`component.cluster` output `node_security_group_id`, or look it up by the
   `stacks-demo-dev-ep3` cluster name in the EC2 console).
2. Edit an **existing** inbound rule's description field (not its CIDR/port — leave actual
   access unchanged) to something like `"manually edited"`.
3. Trigger an on-demand health check as in Demo A.
4. Stack Health flips Amber; the `cluster` component shows the description drift.
5. Targeted remediation plan reverts the description to its declared value. Approve and apply.

**Do not** add a brand-new security group rule for this demo — per the caveat above, an
entirely new, untracked rule won't be detected as drift at all, which undercuts the point.

---

## What NOT to demo live: instance-type "bill drift"

The script's fiscal-drift beat (upsizing a node's instance type directly in the console,
bypassing any plan-based cost gate) is real, but EKS managed node groups in this Stack use
direct `instance_types` (see `modules/cluster/main.tf:52`), not a launch template — changing
the instance type isn't a console-editable in-place action, it requires replacing the node
group. **Narrate this one instead of demoing it live**: explain that *any* governance built
around a Terraform plan — Sentinel included — is blind to a change that never produced a
plan. Don't claim Cloudability would have caught it in the Terraform-based path either;
Cloudability/Run Tasks aren't attached to this Stack (Run Tasks are a known, unsupported
combination with Stacks — see `CLAUDE.md`).

---

## Recovery

If anything looks wrong after the demo, the fastest reset is: re-run a normal plan/apply on
the affected deployment to reconcile state back to declared config, then re-run the health
check to confirm Stack Health returns to Green before moving to the next section.
