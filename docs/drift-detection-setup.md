# Drift Detection Setup

## Overview

HCP Terraform Stacks support scheduled drift detection: a `terraform plan -refresh-only`
equivalent runs on a cadence you configure, queries the cloud provider APIs for each
component's actual state, and rolls the result up into a single **Stack Health** signal
(Green / Amber / Red) instead of a per-workspace status you'd have to hunt for individually.

> This is a Stack-level setting configured in the HCP Terraform UI — there's no HCL for it.

---

## Step 1: Enable Drift Detection on the Stack

1. Navigate to **Projects & Workspaces** → find the `tfe-series-ep3` Stack
2. Click **Settings** → **Health**
3. Toggle **Drift Detection** on
4. Set the check cadence (default is every 24 hours — for the recording, a shorter interval
   like every 1–2 hours makes it practical to demo without a long wait)

---

## Step 2: Understand the Cost Tradeoff

Each drift check is a refresh-only run against every component in every deployment. It:

- Consumes cloud provider API calls (rate limits matter at scale)
- Counts toward your HCP Terraform run quota

For a 3-deployment demo Stack this is trivial. Call out in the recording that for a real
estate with hundreds of Stacks, the cadence is a deliberate visibility-vs-cost dial, not a
"set to maximum and forget it" setting.

---

## Step 3: Reading Stack Health

| State | Meaning |
|---|---|
| 🟢 Green — Healthy | All components match their desired state. No drift detected. |
| 🟡 Amber — Drifted | One or more resources have drifted from state. Review needed. |
| 🔴 Red — Errored | Drift detection failed, or a critical issue was detected. |

Click into the health status from the Stack overview to see which **components** (not just
which deployment) drifted, and to open the proposed remediation plan.

---

## Step 4: Triggering an On-Demand Health Check

You don't have to wait for the schedule during the recording:

1. From the Stack overview, click **Check Health Now** (or equivalent — verify exact label
   in your HCP Terraform version)
2. This runs the refresh-only check immediately across all deployments

Use this right after the manual drift injection in `drift-demo-runbook.md` so the amber
status appears on camera within seconds rather than waiting for the schedule.

---

## Notes

- Drift detection only sees resources Terraform actually manages in state. Anything created
  outside Terraform entirely is invisible to it — drift detection catches *changed* resources,
  not *unmanaged* ones.
- Remediation plans triggered from a drifted component are **not auto-applied** by default.
  They produce a plan for review/approval like any other run — unless you've explicitly
  configured auto-apply on the Stack.
