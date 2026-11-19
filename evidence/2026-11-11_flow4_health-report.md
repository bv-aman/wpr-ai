# Flow 4 — Fleet health report (live run)

**Date:** 2026-11-11 · **Sources:** `GET /sites`, `GET /sites/wp/updates`, `GET /sites/wp/plugins?include_vulnerabilities=true`, `GET /monitoring/ssl-monitors`

## Executive summary

6 sites · **1 up / 5 down** (OxyBoron up; all Cloudways test sites down/disconnected since ~Nov 7) · 1 pending core update (Test Site 5) · **every site has vulnerable plugins** · worst CVSS **9.8 on 3 sites** · 6 SSL monitors enabled · daily snapshots failing on the disconnected sites.

## Per-site table

| Site | Uptime | Pending (pl/th/core) | Vulnerable plugins (worst) | Scanner | Notes |
|---|---|---|---|---|---|
| OxyBoron | **up** | 5/1/– → **now 0/0** (after Flow 1 run) | 4 → 2 after run (9.8) | clean | updated today; see Flow 1 evidence |
| wp-1045382-5211328 | down | 6/0/– | 2 (7.2), 1 VP | clean | disconnected |
| wp-1045382-5216976 (1324) | down | 6/3/– | 1 (5.3), 0 VP | clean | disconnected |
| Christo's Test Site 2 | down | 6/3/– | 2 (9.8), 0 VP | clean | disconnected; snapshots failing (see Flow 2) |
| wp-1045382-5216976 | down | 3/0/– | 2 (9.8), 4 VP | clean | disconnected |
| Test Site 5 | down | 0/0/**core** | **15 (9.8)**, 38 VP | clean | core update pending |

## Attention list (ranked)

1. **Test Site 5 — core update pending + 15 vulnerable plugins (84 vulns, worst 9.8)** → run the update sweep
2. **Unpatched (no-VP) criticals/highs**: Christo's Test Site 2 (9.8, 0 VP), wp-5216976 (9.8, 0 VP on one), OxyBoron's Kadence Blocks PRO (no update path)
3. **5 sites disconnected** → snapshots failing fleet-wide on those sites; reconnect or remove
4. OxyBoron Gravity Forms major-jump update decision (staging recommended first)

## Outcome

✅ One-pass report from 4 API families; attention list directly actionable. (SSL certificate-expiry detail available via `certificate-details` per monitor — omitted here; monitors healthy/enabled.)
