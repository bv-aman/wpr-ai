---
name: wpremote-onboard-site
description: First-day assessment of a newly connected site via WP Remote — after the first sync, analyzes the site (health score, pending updates, vulnerabilities, hack/redirection detections) AND the fleet's existing conventions (monitoring, tags, auto-update schedules, reports, GA), then presents a curated starter pack of prepared actions the customer approves in one word. Use when a site was just added or connected, or when asked what to set up for a site.
---

# New-site onboarding — the first-day assessment

The professional's first day with a new site: assess it, compare it to how the customer runs everything else, and propose a starter pack. Every recommendation cites fleet evidence — never generic advice. Runs when add-site completes (automatic handoff) or on request.

## Procedure

1. **Confirm readiness:** first sync completed (`sync.last_sync_status: succeeded` + `backups.latest_snapshot` exists). Still syncing → say so and wait. Sync failed → stop; hand to the breakage-triage skill.
2. **Read the new site** (all reads):
   - `GET /sites/{id}` — `health.score` + `health.status` (the headline), connection, core versions, PHP, `woocommerce`, `multisite`
   - plugins / themes / core with `include_vulnerabilities=true` — pending updates; vulnerabilities with severity + virtual-patch coverage
   - `security.scanner.status` + detections summary (and `detections/redirections` when the scanner flags) — **hacked or redirection detected = urgent findings, they lead the pack**
3. **Read the fleet's conventions** (this is what makes it curated — every proposal gets its evidence here):
   - `GET /sites` aggregate — share of sites with uptime monitoring, SSL monitors, firewall, activity logs, real-time backups on
   - `GET /tags` — which tags exist (client, production, …) and which fit this site
   - `GET /auto-update-schedules` — active schedules: an `all`-scope schedule **already covers** the new site (say so); filename-scoped ones are "add to X" proposals
   - `GET /scheduled-reports` — fleet reports this site should count in
4. **Compose the starter pack:**
   - **Findings:** health score headline → pending updates (criticals first) → vulnerabilities (worst severity, VP coverage) → URGENT section if hacked/redirections → version/PHP notes.
   - **Prepared actions** (one word applies the batch):
     1. security-critical path if compromised (cleanup eligibility → its Mode 2 flow)
     2. safe update sweep if updates pending (`wpremote-updates` skill)
     3. enable uptime + SSL monitoring (+ visual if that's the fleet convention) — *cite the stat: "your other 5 sites run uptime monitoring"*
     4. tags matching convention
     5. add to filename-scoped auto-update schedules / confirm already covered
     6. add to the fleet's scheduled report
     7. GA connection if the fleet uses it — **state plainly it's dashboard-only today** (not in the public API) with where to click; never mark it done
5. **After approval:** execute the batch (monitoring/tags handled; schedule/report additions via their prepared calls; updates via the sweep skill), verify each landed, then hand the site to steady state — it appears in the briefing from now on.

## Calibration examples (the procedure handles cases beyond these)

| Situation | Resolution |
|---|---|
| "Just added shop.example.com — what should we do?" | full pack |
| add-site completed | automatic handoff into this skill |
| "Assess site X" (added long ago, never onboarded) | same procedure, framed as a catch-up audit |
| Fleet of one (no conventions exist) | recommend sensible defaults, **labeled as defaults, not fleet conventions** — this pack becomes the customer's convention |
| Fleet split on a convention (50/50 monitoring) | recommend the majority, note the split, let the word decide |
| Site arrives already hacked | urgent findings lead; cleanup flow prepared; no routine setup proposed until it's clean |

## Rules

- Every recommendation cites its evidence (fleet percentage, schedule name, tag name). No evidence → say it's a default, not a convention.
- Nothing executes before the pack approval — onboarding is the one moment everything is shown; a new site has no established policy yet, and this pack **sets** it (critical tags, hold tags, monitoring baseline).
- Findings never buried under setup items.
- Dashboard-only capabilities (GA today) are stated as such — honesty over theater.
- Generalization rule from the base skill applies throughout: anything unlisted resolves through intended outcome → minimal path → classify → prepared proposal.

## Hand-offs

`wpremote-updates` (updates, vulnerabilities, schedules) · security cleanup flow (compromised) · `wpremote-site-breakage-triage` (failed sync) · `wpremote-visual-monitoring` (monitor enablement) · briefing (steady state).
