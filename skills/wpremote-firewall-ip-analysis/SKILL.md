---
name: wpremote-firewall-ip-analysis
description: Full analysis of a firewall-blocked IP across the user's WP Remote sites — pulls every firewall log entry and login-protection attempt for that IP, aggregates rules triggered, targeted paths, request pattern and timeline, then recommends whether to whitelist or keep it blocked (and can whitelist on confirmation). Use when the user says an IP was blocked, asks why an IP was blocked, or whether to whitelist/unblock an IP.
---

# Firewall IP analysis — blocked IP verdict

Read-only analysis; the whitelist action happens only on explicit confirmation.

## Inputs

1. The IP (full or partial, e.g. `203.0.113.4` or `203.0.113`).
2. Scope: one site or the whole account (default: whole account).
3. Window: default last 7 days.

## Step 1 — Gather (read-only)

- `GET /sites` (all pages) — site map.
- Per site in scope:
  - `GET /sites/{site_id}/security/firewall/logs?filters[ip_address:contains]=<IP>&filters[timestamp:gte]=<start>` (all pages) — every hit, blocked or allowed, with rule and request detail.
  - `GET /sites/{site_id}/security/login-protection/attempts?filters[ip_address:contains]=<IP>` — brute-force attempts against logins.
- **Rate limit discipline**: the account allows 200 requests/min. Large fleets: query sites in batches, prioritize the site(s) where the user saw the block.

## Step 2 — Aggregate

- Volume: total hits, blocked vs allowed, per site.
- What it did: top triggered rules, top targeted paths, HTTP methods, burst pattern (short burst vs sustained scanning), first/last seen.
- Login context: failed login attempts from this IP.
- Behavior read: crawling generic pages vs probing `wp-login.php`/`xmlrpc.php`/admin paths vs hammering a form.

## Step 3 — Verdict (show the evidence, then the recommendation)

- **Keep blocked** (default when in doubt): scanning/probing patterns, many rules triggered, brute-force attempts, hits across many sites it has no business with.
- **Whitelist candidate**: known service (uptime monitor, search crawler) with benign request patterns, or the user's own/office IP (low volume, normal browsing) — confirm the story with the user.
- **Ambiguous**: present the evidence table and let the user decide; never push.

## Step 4 — Action (Mode 2: ready, say go)

Whitelist per site: `POST /sites/{site_id}/security/firewall/ip-access/whitelist` with the IP. The analysis (Steps 1–3) is Mode 1 — handled, no asking. The whitelist itself arrives prepared: which sites, why the evidence supports it, how to reverse it — one line, one word to execute.

Present result: what changed, on which sites, and how to reverse it (`POST .../firewall/ip-access/delete`).
