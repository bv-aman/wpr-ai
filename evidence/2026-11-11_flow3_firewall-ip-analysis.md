# Flow 3 — Firewall IP analysis (account-wide, live run)

**Date:** 2026-11-11 · **Scope:** all 6 sites · **Data:** 822 firewall log entries aggregated

## Schema learned (live)

`GET /sites/{id}/security/firewall/logs` → `{ logs: [...], meta }`; entry fields: `id, timestamp, ip_address, country_code, method, path, user_agent, response_code, status, reason, category`. Stats endpoint returns request trends (allowed/blocked) over ~14 days.

## Account reality

**Zero blocked events and zero login-protection attempts exist on this test account** — every logged request was `allowed`. Analysis demonstrated on the most active IPs (the machinery is identical for a blocked IP; only the verdict input differs).

## Top-IP profile (verdict demo)

**`127.0.0.1` — 509 hits, 4 sites, Oct 28 → Nov 11**
- Status: 509 allowed, 0 blocked · categories: `whitelisted` ×343, `private_ip` ×166
- Methods: POST ×464, GET ×45 · Paths: `/wp-cron.php` ×430, `/` ×45, `/wp-admin/admin-ajax.php` ×32
- UAs: cloudways monitoring + WordPress cron
- **Verdict: benign internal/monitoring traffic, already whitelisted — no action.**

Runners-up (realistic future demo targets):
- `159.223.223.72` — 65 hits in a **2-minute burst** (Nov 10 20:34–20:36Z), single site → classic scanning pattern → would recommend **keep blocked**
- `64.227.7.169` — 152 hits over ~20 h sustained, single site → crawling/profiling → evidence-first verdict

## Outcome

✅ End-to-end: account sweep → per-IP aggregation (sites, timeline, methods, paths, rules, categories, UAs, countries, codes) → evidence-backed verdict → (whitelist action available on confirmation; not triggered — nothing to whitelist). Rate-limit discipline observed (822 entries across ~7 calls).
