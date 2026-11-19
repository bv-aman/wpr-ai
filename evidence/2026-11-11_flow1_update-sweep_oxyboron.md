# Flow 1 — Vulnerability-aware update sweep (OxyBoron, live run)

**Date:** 2026-11-11 · **Site:** OxyBoron (https://oxyboron.com, id `5bb980b1…`) · **Scope:** OxyBoron only (per instruction) · **Options:** `backup: true`, `visual_regression: true`

## Phase 1 — Audit (read-only)

Account-wide: 6 sites, every site has vulnerable plugins; 3 sites worst-CVSS 9.8. OxyBoron: 4 vulnerable plugins / 31 vulns / 24 VP-applied / worst 9.8. Pending: 5 plugins + 1 theme, core current.

## Phase 2 — Risk assessment and scope decision

| Item | Jump | DB flag | Vulnerable | Decision |
|---|---|---|---|---|
| gravityforms 2.5.16 → 3.2.2 | **MAJOR (2→3)** | no | 23 vulns (all VP-applied) | **HELD — sandbox trigger fired** |
| kadence-blocks 3.7.9.1 → 3.9.0 | minor | no | 5 vulns, **VP not applied** | update (clears all) |
| woocommerce 11.0.1 → 11.2.2 | minor | no | 2 vulns, 1 **not VP'd** | update (patches it) |
| wordpress-importer 0.9.6 → 0.9.7 | patch | no | no | update |
| post-types-order 2.5.1 → 2.5.9 | minor | no | no | update |
| theme kadence 1.5.2 → 1.6.0 | minor | — | no | update |

Sandbox plan-check: **no feature-flag introspection exists in the public API** (platform gap). Staging feature confirmed accessible (`GET /staging-sites` → 200). Per instruction: sandbox-required item mentioned and stopped — not executed, no staging created.

Baseline snapshot before run: `6af44ceb…` (2026-11-11 11:09 UTC, succeeded).

## Phase 3 — Execute

`POST /sites/wp/updates/perform` — 4 plugins + 1 theme, `options: {backup: true, visual_regression: true}`, `override_lock: false`. → Task `1be7b4ea8b60364ed462928feaf24e00` (created 12:10:01Z).

## Phase 4 — Track

Poll `GET /tasks/{id}` every ~12 s: running (0%) → 27% → 64% → 71% → **completed at 12:12:31Z (~2.5 min)**. Full step chain, all green:

`pre_snapshot` → `update_plugin` ×4 (Importer, Kadence Blocks 3.9.0, Post Types Order, WooCommerce 11.2.2) → `update_plugin_db` (WooCommerce migration) → `update_theme` (Kadence 1.6.0) → `post_snapshot` → `purge_cache` → **`visual_regression`** → `wp_test` → `finalize_manage`

**Visual regression result:** https://oxyboron.com — before/after/diff screenshots produced, `percentage_change: 0.0`, status succeeded. (Confirms this plan supports VR.)

## Phase 5 — Post-check (read-only)

- Versions: woocommerce 11.2.2, kadence-blocks 3.9.0, importer 0.9.7, post-types-order 2.5.9, theme kadence 1.6.0 — all off the pending list.
- Vulnerability state: woocommerce and kadence-blocks **cleared**. Still flagged:
  - Gravity Forms v2.5.16 — 23 vulns, **all VP-applied** (protected) — awaiting sandbox/staging decision
  - Kadence Blocks **PRO** Extension v1.6.1 — 1 vuln, **no VP, no update available** → the "report, never force" case
- Snapshot trail: new pre-update backup `6af45b19…` (12:10:01Z, succeeded) — backup-first verified in the trail.

## Outcome

✅ End-to-end: audit → risk rules → hold → safe execute (backup + VR + post-snapshot + wp_test) → track → verify. **POC-proven.**

Follow-up for customer: (a) Gravity Forms 2→3 major jump — recommend staging test (`POST /staging-sites` from latest snapshot) before production update; awaiting go-ahead. (b) Kadence Blocks PRO needs its license-side update (no API path).
