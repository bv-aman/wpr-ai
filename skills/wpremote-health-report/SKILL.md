---
name: wpremote-health-report
description: Fleet health report via WP Remote — one pass across all sites producing an executive summary (uptime, pending updates incl. WordPress core, vulnerabilities, malware status, last backup, SSL expiry, PHP versions) with a per-site table and a ranked attention list. Use when the user asks for a health report, status of all their sites, a weekly report, or how their sites are doing.
---

# Fleet health report

Read-only. One pass, one report.

## Step 1 — Gather (read-only)

1. `GET /sites` (all pages) — per site: `uptime.status`, `wp.core` (current/latest/update_available), `security.scanner.status`, `backups.latest_snapshot` + `available_snapshots`, `server.php_version`, `connection.status`, `locked`, tags.
2. `GET /sites/wp/updates` — pending plugin/theme update counts per site.
3. `GET /sites/wp/plugins?include_vulnerabilities=true` — vulnerable plugin count per site with worst severity (skip gracefully if the plan doesn't enrich; fall back to the flat `vulnerable` flag).
4. `GET /monitoring/ssl-monitors` (+ `certificate-details` per monitor) — certificate expiry dates.

## Step 2 — Report

**Executive summary** (numbers first): N sites · X up / Y down · Z with pending core updates · W with vulnerable plugins (worst severity) · any malware flags · SSL certs expiring <14 days · sites with stale backups (>7 days since last snapshot).

**Per-site table**:
`site (URL) | uptime | core | pending plugins/themes | vulnerable (worst) | scanner | last backup | PHP | SSL expiry`

**Attention list**, ranked:
1. malware flagged / site down
2. critical/high vulnerabilities without virtual patch
3. expired or soon-expiring SSL
4. stale or missing backups
5. pending core updates

**Trend note**: if the user runs this weekly, compare against the previous report if they still have it — otherwise offer to save this one as a markdown file they can diff next week.

Scheduling/sending (Mode 2 — "ready, say go"): recurring emails or scheduled reports are prepared ("weekly summary to ops@… — go?") and executed on one word; generating/saving/diffing reports is Mode 1.
