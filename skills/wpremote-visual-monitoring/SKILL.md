---
name: wpremote-visual-monitoring
description: Visual monitoring via WP Remote — enable visual monitoring on a site, refresh checks, and review visual monitoring data (change percentages, screenshots, probe history), correlating visual changes with what caused them. Use when the user asks to watch a site visually, whether a site looks broken or changed, or to review visual monitor data.
---

# Visual monitoring

Two different things — don't mix them: **update-time visual regression** runs inside update tasks (part of the `wpremote-updates` safety loop); **visual monitors** are continuous scheduled screenshot checks with a change threshold. This skill is the continuous kind.

## Enable / manage — Mode 1 for defaults

- **Default monitor (handled, logged):** `POST /monitoring/visual-monitors` with
  `{ "visual_monitor": { "site_id": "<id>", "url": "<site home URL>", "device": "desktop", "interval": 86400, "threshold": 10 } }`
  Reversible (disable/delete), no site mutation → handled without asking. Defaults: daily interval, 10% threshold, desktop.
- **Custom sets (Mode 2, prepared):** multiple URLs (cart, checkout, landing pages), mobile device, tighter intervals or thresholds — arrive as one prepared list: "Ready: monitor 4 URLs on yoursite.com, daily, desktop+mobile, alert >5%. Go?"
- Enable/disable/refresh existing: `POST /monitoring/visual-monitors/{id}/enable|disable|refresh` — handled.

## Review — Mode 1, handled

- **Status:** `GET /monitoring/visual-monitors` (+ the site's monitoring state in `GET /sites/{site_id}`).
- **Probes:** `GET /monitoring/visual-monitors/{id}/probes` → per run: timestamp, change %, status, baseline/comparison/diff screenshots.
- **Present conversationally:** "yoursite.com — last 7 daily probes ≤ 0.1% change. Tuesday 04:00 probe: 12.4% (screenshots attached) — correlates with the theme update that ran at 03:58 (activity log). Resolved itself by the next probe."
- **Correlate, don't just report:** any spike gets checked against the site's change timeline (activity logs, tasks, auto-update history) before presenting — the professional answers "what changed and why," not "something changed."

## In the briefing

Newly enabled/disabled monitors · probes that breached threshold (with screenshots and the likely cause) · monitors going stale because a site is disconnected (probes fail silently otherwise).
