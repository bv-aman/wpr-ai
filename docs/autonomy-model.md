# Autonomy Model v2 — two modes, universal

**Decisions:** v1 (2026-11-12, four lanes + probation) → **v2 (2026-11-12, same day — Aman review):** probation removed; Lanes 3 and 4 dissolved; the model is a pure combination of autonomous handling (old Lane 1) and prepared-go (old Lane 2). This OS applies to **every flow the agent will ever run** — updates, restores, malware, firewall, reports, site management.

## The customer's entire experience — two states

1. **"Handled."** — Routine, reversible work executed autonomously inside the verification loop, logged to the briefing. No ask, no ping.
2. **"Ready — go?"** — The agent completed ALL the work (analysis, checks, staging, consequence mapping, final backup where relevant) and presents a one-line prepared action. The customer spends one word. Never an open-ended question, never a menu to analyze.

**Design rule:** the customer authorizes; they never analyze. If a flow would require the customer to think, the agent hasn't finished preparing.

## Where the old lanes went

- Old Lane 3 (human decides first) → its *protection* is preserved by Mode 2 mechanics: irreversible/costly/credential/external actions are **always Mode 2 with mandatory preparation** (target verified, consequences mapped, final backup taken). This floor is not configurable away — but the interaction is always "ready, say go," never homework.
- Old Lane 4 (notify) → dissolved into the **briefing**: a single periodic, pull-based report of everything handled and everything awaiting a word. Awareness without interruption.

## Classification (every contemplated action, every flow)

Mode 1 requires ALL of: reversible (rollback path exists), inside the verification loop, routine (no major-version jump / no business-critical component / no failed history / not locked / not on the never-list), within the change budget.
Everything else → Mode 2. **Unclassified → Mode 2 with the agent's best-prepared recommendation.** Unknown never means improvise.

## Controls (replace probation; set at onboarding, adjustable anytime)

1. **Irreversibility floor** — deletes, credential operations (passwords/2FA/security keys), money, anything sent outside the account: always Mode 2, always with prep.
2. **Change budget** — max sites/actions per window (default ~20 sites/night). Larger scopes arrive as one prepared batch.
3. **Never-list** — components/sites that always take Mode 2 even if routine; persisted as `wpr-ai:hold` tags on sites.
4. **Verification gates (always on)** — backup-first invariant on every mutation; visual regression + `wp_test`; auto-rollback thresholds (wp_test fail or VR >10% → rollback + fleet freeze; 2–10% → hold + screenshots; ≤2% pass); canary waves; stop-on-repeat (same item breaks twice → frozen fleet-wide); 200 req/min budget.
5. **Audit trail** — every task, backup, screenshot retained; briefing = reviewable evidence.

## Mode map per flow (the universality proof)

| Flow | Mode 1 — Handled | Mode 2 — Ready → go |
|---|---|---|
| Updates | patch/minor updates in verified waves, auto-rollback | major jumps (staged + verified first), lock overrides, beyond-budget batches |
| Backup restore | snapshot listing, selection analysis, diff of what would be lost | the restore — snapshot pre-picked, data-loss window stated in one line |
| Malware | scans, detection analysis, eligibility checks | cleanup run — backup-first, affected files listed |
| Firewall | full IP analysis, pattern aggregation | whitelist/unblock on named sites |
| Reports | generate, save, week-over-week diff | scheduling/emailing (recurring external send) |
| Sites | SSO login URLs, staging create/refresh, tag hygiene | site add/delete, connection keys, anything costing money |
| Login (flow 5) | SSO URL generation (serves the requester only) | — |

## The briefing (single reporting surface)

Weekly and on-demand ("standup"):
> **Handled:** aggregate + notable exceptions + auto-rollbacks and why.
> **Ready for your go (≤5):** one line each, prepared action stated, recommendation included.
> Everything else: full log on request, never dumped.

## Onboarding (once, ~4 questions)

1. Which sites are production-critical / ecommerce? (inferred starts; persisted as `wpr-ai:critical`)
2. Maintenance window? (off-hours)
3. Never-touch list? (`wpr-ai:hold` tags)
4. Change budget and visual-regression sensitivity? (defaults: 20 sites/night; 2%/10%)

No probation, no autonomy dial — controls are the safety story, set once and adjustable.

## Platform gaps (unchanged feedback)

Feature-flag introspection; webhooks (standing watch is poll/schedule-based); on-demand snapshot trigger; restore endpoint verification (required before auto-rollback ships — last unverified primitive).
