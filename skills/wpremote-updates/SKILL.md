---
name: wpremote-updates
description: The update brain for WP Remote — everything about updates. Fleet-wide vulnerability-aware sweeps ("update everything safely"), targeted updates ("update WooCommerce everywhere / on these sites"), update audits and vulnerability reports, and native auto-update schedules (set up, view, review what a schedule run did). Routine safe updates run autonomously with backup, visual regression, health test, and auto-rollback; risky items arrive fully prepared for one word. Use for any plugin/theme/core update, vulnerability, or auto-update schedule request.
---

# Updates — one brain, every scope

Two entry scopes, one classification, one safety loop, one briefing:

- **Proactive sweep** — nobody named a target: audit everything (pending updates + vulnerabilities across all sites), prioritize, handle the safe, prepare the risky.
- **Targeted run** — the customer named it: "update all plugins", "update X everywhere", "update X on sites A and B". **An explicit instruction is the authorization for that exact scope.** What still comes back for one word is anything they didn't know when they asked.

Plus the **always-on layer**: native auto-update schedules (last section).

## First run — onboarding (once)

Ask briefly (defaults in parentheses):
1. Which sites are production-critical or ecommerce? (infer: WooCommerce flag, uptime history) → tag `wpr-ai:critical`
2. Maintenance window? (off-hours)
3. Anything that should always wait for a go-ahead even if routine? (locks are honored regardless) → tag `wpr-ai:hold`
4. Change budget and visual-regression sensitivity? (20 sites/window; pass ≤2%, rollback >10%)

Persist via `POST /tags` + assign. Never re-ask.

## Classify — the axes are the procedure

Situations not named below don't need new rules: every item resolves through **reversibility, jump size, failed-update history, site criticality, and budget**. When genuinely ambiguous, treat as Mode 2 with the smaller proposed scope and say what it doesn't cover.

**Mode 1 — handled (no pre-approval):** patch/minor updates where the item is not locked, has no failed history, is not a major-version jump, is not a business-critical component on a `wpr-ai:critical` site, and is within budget. Vulnerable-but-VP-protected items can wait for the next sweep; unpatched (no VP) criticals jump the queue.

**Mode 2 — ready, say go (the surprises):**
- **Major-version jumps:** do the prep yourself — create a staging copy from the latest snapshot (`POST /staging-sites`), update there, verify, then: *"Ready: X 2.5→3.2 on 12 sites, staging-verified clean. (a) roll out (b) non-production first (c) hold."*
- **Locked items:** consequences prepared ("locked by your rule; the update clears critical 9.8 — ready to override on site X").
- **Beyond-budget batches:** one prepared batch, one word.
- **No update package available** (license-side, repo-missing): report with the reason; never force.

Already-current targets: listed as "current", no action, no noise.

## Audit (sweep scope)

`GET /sites` (map, connected state) · `GET /sites/wp/updates` · plugins/themes/core with `include_vulnerabilities=true`. Urgency = `severity × unprotected (no VP) × site criticality × fix availability`. Disconnected sites can't be updated — list as FYI, don't retry forever.

## Execute — verified waves

1. Sort sites least-critical first; wave 1 = 1–3 non-critical sites.
2. `POST /sites/wp/updates/perform` per wave — `options: { "backup": true, "visual_regression": true }`, `override_lock: false`, `target_version` = the patched version for vulnerability-driven items, or the customer's named version.
3. After each task, inspect `details.sites[].steps`: `wp_test` failed or visual regression **>10%** → restore the pre-update snapshot (`POST /sites/{id}/backups/{snapshot_id}/restore`), freeze the item fleet-wide, notify. **2–10%** → hold the item everywhere + attach the diff screenshots. **≤2%** → pass.
4. **Stop-on-repeat:** the same item breaking twice → out of all remaining waves, escalated.
5. Poll ~10 s cadence; respect the 200 req/min budget.

## Auto-update schedules — the always-on layer

Schedules run even when the agent isn't running. Set them up once, review their results in the briefing. Judgment cases (major jumps, business-critical components) are not schedule material.

**View — handled:** `GET /auto-update-schedules` (name, status, next run, scope, options). Run results: `GET /auto-update-history?filters[auto_update_schedule_id:eq]=<id>` (+ `performed_on` window, `status:in`) — present conversationally ("the nightly ran Tue 02:30 — 41 updates on 12 sites, 2 failed: reasons").

**Create / change — fully prepared, one go.** Body shape (defaults in parentheses):

```json
{ "auto_update_schedule": {
    "name": "Nightly — trusted plugins", "schedule": "weekly_on_day",
    "started_at": "<off-peak>", 
    "scope": { "sites": { "selection": "all" },
               "updates": { "wordpress_core": true, "plugins": { "selection": "all" } } },
    "options": { "backup": true, "visual_regression": true }
} }
```

Preparation rules: always `backup` + `visual_regression` on; off-peak `started_at`; **warn honestly** that `plugins.selection: "all"` also applies major jumps when they appear (no patch-only filter exists) — for risk-averse customers propose a curated filename allowlist instead, so major jumps keep flowing to Mode 2. Actions: create `POST /auto-update-schedules`; change/pause/resume `POST /auto-update-schedules/{id}/update|enable|disable`; delete `DELETE /auto-update-schedules/{id}` (Mode 2, coverage summarized first).

## Briefing (always end here)

> **Handled:** N updates across M sites — checks passed. Auto-rollbacks + why. Schedule runs (pass/fail counts, failures detailed).
> **Ready for your go (≤5):** the prepared Mode 2 items, one line each, with recommendations.
> **FYI:** disconnected sites, exposures cleared, no-update-path vulnerabilities, major jumps excluded by the allowlist.
> Full log on request.
