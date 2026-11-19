---
name: wpremote-site-breakage-triage
description: First-response investigation for a broken WordPress site via WP Remote — builds a timeline of everything that changed on the site in a time window (plugin/theme/core updates, activations, restores, malware cleanups, user actions) from activity logs, task history, and auto-update history, then ranks the most likely cause of the breakage. Use when the user says a site is broken, broken since a certain time, something changed/deleted itself, or asks what changed on a site.
---

# Site breakage triage — "why did my site break?"

Read-only investigation. It changes nothing; it produces a diagnosis and recommended next step.

## Inputs (ask if not given)

1. Which site (name or URL).
2. When it broke / when the problem was first noticed (be precise if possible; default window: 72 h before "now" if unknown — confirm with the user).
3. Symptoms (frontend down, white screen, specific page, admin locked out…) — optional but sharpens the verdict.

## Step 1 — Gather (read-only, all pages)

- Resolve the site via `GET /sites` (per the `wpremote` skill).
- **Activity logs**: `GET /sites/{site_id}/activity-logs?sort=timestamp,desc` with `filters[timestamp:gte]=<window_start>&filters[timestamp:lte]=<window_end>` (`perPage` up to 500). These capture WP-side changes: plugin/theme updates and activations, core updates, page/post changes, user logins — with usernames.
- **WP Remote tasks**: `GET /tasks?filters[type:eq]=wp_site_update` (+ other types if relevant) in the window — updates run through WP Remote.
- **Auto-update history**: `GET /auto-update-history?filters[performed_on:gte]=<start>` — scheduled auto-updates.
- **Malware cleanups**: `GET /sites/{site_id}/security/scanner/cleanup` — any cleanup runs.
- **Snapshots**: `GET /sites/{site_id}/snapshots` — backup trail (and restore traces).
- Current state: `GET /sites/{site_id}` — uptime status, scanner status (`hacked` changes everything), connection status.

## Step 2 — Correlate

Build one merged timeline: `time | event | what changed | actor (username/system) | source (activity log / task / auto-update / cleanup)`.

Then rank likely causes:
1. Changes closest before the breakage time (updates, activations, deactivations, deletions).
2. Any plugin/theme update — especially major-version jumps or items with `database.update_required`.
3. Malware or cleanup activity near the time.
4. If nothing changed via any source → say so plainly; cause is likely outside this site's tracked activity (hosting, DNS, external edits). Don't invent a culprit.

## Step 3 — Report and recommend

- The timeline table.
- Most likely cause(s), ranked, each with its evidence.
- Recommended next step:
  - update-related breakage → restore the most recent snapshot taken **before** the change (`POST /sites/{site_id}/backups/{snapshot_id}/restore` — offer it, never run it without an explicit request; confirm the snapshot timestamp back to the user first)
  - scanner says `hacked` → suggest a malware cleanup flow
  - nothing found → suggest checking hosting/DNS with the symptoms in hand.

**Safety**: this skill never mutates anything. Restore/cleanup follow Mode 2 ("ready, say go"): the agent prepares the exact action — correct pre-change snapshot chosen, data-loss window stated in one line ("restores to yesterday 03:00; loses changes made since") — and the customer spends one word.
