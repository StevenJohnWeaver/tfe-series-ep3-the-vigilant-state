# Episode 3 Demo Talk Track
## "The Vigilant State — Drift Detection & Remediation"
**Format:** Lightboard / Demo | **Target Duration:** ~15 minutes

> **Before you record:** Stack deployed and healthy (all three deployments green), Sentinel
> policy set attached and **confirmed working against a Stack plan** (see `CLAUDE.md` —
> this is provisional until tested live), drift detection enabled per
> `drift-detection-setup.md`, and the drift injection from `drift-demo-runbook.md` rehearsed
> at least once so you know the actual time-to-amber on your configured check cadence.
>
> **Two adaptations from the original script, called out here so they don't surprise you
> mid-recording:**
> 1. The script's "Reconciling at Scale" section claims remediation passes through "the same
>    Sentinel and Cloudability governance from Episode 2." Cloudability is dropped — Run
>    Tasks don't attach to Stacks. Narrate Sentinel only.
> 2. The script's Stack Health visual shows fictional regions (US-East/EU-West/AP-South,
>    a Singapore example). This Stack's actual deployments are `dev` (us-east-1), `staging`
>    (us-east-1), `prod` (us-west-2) — narrate "multi-environment, multi-region" against the
>    real Stack rather than three literal continents. Add real additional regional
>    deployments later if you want the literal multi-continent shot.

---

## 0:00 – 2:30 | The Hook: The "Shadow Infrastructure" Problem

**On screen:** Lightboard. Write **TRUTH** (green) and **REALITY** (red) with a widening gap
labeled **DRIFT**, plus a "Day N" label.

**Say:**
> "We've spent Episodes 1 and 2 building a governed estate — one that's scalable, secure, and
> cost-aware. But the moment you click Apply, the entropic clock starts. Drift at its most
> basic level happens when someone does something like toggling a firewall rule, but in the
> bigger picture, it's the environment evolving underneath your code.
>
> Today we move from Day 1 deployment to Day N verification — closing the gap between code
> intent and cloud reality. If your Terraform state diverges from what actually runs, your
> policies are checking a fiction."

**Key point:** Drift is the silent killer of governance.

**Note (say this explicitly, it sets expectations for the rest of the episode):** "Drift is
detected for resources Terraform manages in state — things Terraform doesn't manage are
invisible to drift checks. And these checks run on a scheduled cadence, not as a real-time
stream."

---

## 2:30 – 6:30 | The Handshake Integrity: When Reality Breaks the Blueprint

**On screen:** Lightboard — the Smart Handshake diagram from Episode 1 (Network → App),
Deferred Variable arrow highlighted in orange. Then cut to HCP Terraform / AWS Console for
the live demo.

**Say:**
> "In Episode 1 we used deferred variables so the App component could reference the Network
> component's outputs — an automated handshake. If someone later changes something in that
> network layer through the console, the handshake logic is still correct, but the data it
> relies on has changed outside Terraform. On the next plan, Terraform rereads remote
> attributes and exposes the inconsistency. This is architectural drift that can ripple
> through the dependency graph."

**On screen — live demo (Demo A from `drift-demo-runbook.md`):** Open the AWS Console, find
the `dev` deployment's VPC, remove the `owner` tag.

> "Let me show you exactly how HCP Terraform catches this. I'm changing a tag directly on
> this VPC, in the console — completely outside Terraform."

*[Switch to HCP Terraform, trigger Check Health Now]*

> "Drift detection runs a scheduled refresh — essentially a `terraform plan -refresh-only` —
> on a cadence you configure. Default is every 24 hours, but you can tune it. During the
> refresh, HCP Terraform queries the cloud provider APIs and checks if resources match the
> state file. I've sped this up for the recording, but in production this happens on its own
> schedule.
>
> One important consideration: each drift check consumes cloud API calls and counts toward
> your HCP Terraform run quota. For large estates, tune the frequency to balance visibility
> against cost."

*[Stack Health flips Amber]*

> "And there it is. Stack Health just went from green to amber."

**On screen:** Show the three health states explicitly (can overlay or narrate over the UI):
- 🟢 Green — Healthy: all components match desired state
- 🟡 Amber — Drifted: review needed
- 🔴 Red — Errored: drift detection failed or hit a critical issue

> "Click into the health status and you see exactly which component drifted — here, the
> `network` component in `dev` — and a proposed remediation plan. That's a NOC-style view of
> your entire estate's health at a glance."

**On screen:** Cut to the bill-drift narration (no live demo — see `drift-demo-runbook.md`
for why).

> "Drift goes beyond just the technical — it can have a fiscal impact too. If a developer
> upsizes an instance directly in the console, there's no Terraform plan, so no policy
> evaluates it at all. You've created bill drift — unauthorized spend the governance loop
> never saw, because governance loops only run when there's a plan to evaluate."

---

## 6:30 – 10:30 | The Solution: Stack-Level Drift Detection & Single Health Status

**On screen:** Lightboard — loop diagram (HCL → Plan → Apply → State) with a radar icon
labeled "DRIFT DETECTION" scanning the state continuously. Show the Stack box containing
the three deployments.

**Say:**
> "Traditionally you'd check drift workspace-by-workspace — that's unscalable for large
> enterprise infrastructure. With HCP Terraform Stacks, drift is checked per component and
> aggregated into a single Stack Health signal.
>
> If one resource drifts anywhere in this Stack — any deployment, any component — the whole
> Stack shows amber. You're not hunting through logs. You have a single, NOC-style view of
> architectural health."

*[Back to the live UI — show the drifted component detail]*

> "Drift checks run on an ongoing schedule and via explicit health checks. When drift is
> detected, you trigger a targeted remediation — it plans only the affected component, not
> the entire Stack."

**Note:** "Remediation doesn't auto-apply by default. It produces a plan for review and
approval, same as any other change — unless you've explicitly automated the apply."

---

## 10:30 – 13:30 | Reconciling at Scale: The Shared Blueprint Advantage

**On screen:** Lightboard — the shared component definition at the top, arrows promoting a
change Dev → Staging → Prod.

**Say:**
> "Reconciliation at scale is where the platform architect advantage really shows up. In a
> fragmented world, fixing drift across dozens of environments means dozens of manual
> interventions.
>
> But with Stacks, you fix it once in the shared component definition, and that governed
> change is ready to promote across every deployment that uses it. Stacks know exactly which
> components and deployments need updating."

*[Approve the targeted remediation plan from earlier; show it apply and Stack Health return
to green]*

> "Critically, this remediation plan was evaluated by the same governance boundary we
> established in Episode 2 — Sentinel. Watch: the plan that restores the `owner` tag still
> passes `require-tags` cleanly. Fixing drift can't quietly reintroduce a policy violation."

---

## 13:30 – 15:00 | Summary & The Bridge to Episode 4

**On screen:** Lightboard — circle "REMEDIATION", write "EPISODE 4: THE REACTIVE FABRIC".

**Say:**
> "We've built the engine, the brakes, and now the radar. We can detect when reality deviates
> from our blueprint and reconcile it across the estate with policy controls intact. But some
> fixes need coordination beyond a Terraform apply — rotating credentials, restarting
> services, notifying owners. Next time: Terraform Actions and the Reactive Fabric that ties
> infrastructure events to the rest of your business.
>
> One more note: we focused on drift detection here — checking whether resources match their
> configuration. Continuous Validation is a related but separate feature that runs custom
> validation rules against live infrastructure — things like 'is the SSL certificate still
> valid?' We'll cover that in a future deep dive."

**Call to action:** "Enable drift detection on your production Stacks today, and reclaim the
integrity of your infrastructure handshake."

---

## Timing Reference

| Section | Duration |
|---|---|
| The Hook | 2:30 |
| Handshake Integrity (incl. live drift demo) | 4:00 |
| Stack-Level Drift Detection | 4:00 |
| Reconciling at Scale | 3:00 |
| Summary & Bridge | 1:30 |
| **Total** | **~15:00** |

---

## Recording Tips

- Rehearse the drift injection (`drift-demo-runbook.md`, Demo A) at least once before
  recording so you know exactly how long it takes your configured check cadence to flip
  Stack Health to amber — cut to a "fast-forward" or pre-recorded segment if the real wait is
  long
- Have the AWS Console and HCP Terraform UI both open in separate tabs/windows ahead of time
- Don't claim Cloudability caught anything in this episode — it isn't attached to this Stack
- If Sentinel hasn't been confirmed working against a Stack plan by recording time, cut the
  Sentinel-pass line in the Reconciling section and end that beat on the remediation apply
  alone
