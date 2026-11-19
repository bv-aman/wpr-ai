# Flow 2 — Breakage triage (Christo's Test Site 2, live run)

**Date:** 2026-11-11 · **Site:** Christo's Test Site 2 (id `d052cb8d…`) · **Premise:** site reported broken/down · **Window:** 72 h (2026-11-08 12:07Z → 2026-11-11 12:07Z)

## Evidence gathered (read-only)

| Source | Call | Result |
|---|---|---|
| Activity logs | `GET /sites/{id}/activity-logs?filters[timestamp:gte/lte]` | **0 events** |
| WP Remote tasks | `GET /tasks?filters[created_at:gte]` | **0 tasks** |
| Auto-update history | `GET /auto-update-history?filters[performed_on:gte]` | **0 runs** |
| Malware cleanups | `GET /sites/{id}/security/scanner/cleanup` | **0 runs** |
| Snapshots | `GET /sites/{id}/snapshots` | **3 consecutive daily snapshots FAILED** (Nov 9, 10, 11) |
| Site state | `GET /sites/{id}` | `connection: disconnected` · uptime `down` · activity-logs feature enabled · **last sync FAILED 2026-11-07 04:32Z** |

## Verdict (skill logic)

**No tracked change caused this.** Zero updates, activations, restores, or cleanups in the window — the skill's "don't invent a culprit" branch fired. The site has been **unreachable since ~Nov 7** (sync failed, connection disconnected), which also explains the failing snapshots.

**Diagnosis:** connection/host-level failure (plugin can't reach the site or the site is down at the host), not a change-induced breakage.
**Recommended next step:** check hosting/server status and plugin reconnection — **not** a snapshot restore (nothing changed to roll back).

## Outcome

✅ End-to-end read-only triage with a defensible, evidence-ranked verdict + bonus finding (failed backups) the customer didn't know about. Works as first-step ticket triage for the support team too — same mechanics.
