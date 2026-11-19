---
name: wpremote
description: Manage the user's WordPress sites through their WP Remote account (via the WP Remote connector) — sites, updates, backups, security, monitoring, WP users, reports, one-click logins. Use whenever the user mentions their sites, WP Remote, pending updates, backups, uptime, malware, logging into a site, or asks to manage WordPress sites in bulk.
---

# WP Remote — site fleet operations

The user manages WordPress sites with WP Remote. This skill talks to their account over the official REST API. It also defines the **operating system every WP Remote flow runs on**: two action modes, controls, and the briefing.

- Base URL: `https://api.blogvault.net/api/v6`
- Full reference: https://docs.blogvault.net/api/v6

## Authorization

Authorization is handled by the **WP Remote connector** the customer configured — their API token lives there, never in this conversation. Never ask the customer for the token; never print, log, or store it. If calls fail with `401`, tell the customer to regenerate the token in the dashboard (**My Account → API Credentials**) and update the connector.

## Calling WP Remote

Use the connected **WP Remote tools** (they appear once the connector is added). Tool names mirror the API: `list_sites`, `get_site`, plugin/theme/core listings with vulnerability detail, the update-execution tool, `get_task`, snapshots, restore, migrate, activity logs, firewall logs, SSO login URL, and the rest of the full surface.

**Where any skill references an API endpoint (e.g. `GET /sites/{id}/activity-logs?filters[...]`), call the equivalent WP Remote tool with the same path/query/body parameters as tool arguments — the shapes are identical.**

- Credential-bearing arguments (FTP/SFTP/database credentials, connection keys) are secrets: pass them straight into the tool call; never echo them in replies.
- Pagination: list results return `{ <items>, meta: { pagination: { page, perPage, totalPages, totalItems } } }` — aggregate every page before analyzing. List tools also accept `sort`, `timezone`, and `filters` (e.g. `timestamp:gte`, `ip_address:contains`, `tags:in`).

## Resolving sites

Users speak in site names/URLs; the API uses site IDs. Start from `GET /sites` (all pages) and build the name/URL ↔ id mapping. Before any Mode 2 action, state which site (title + URL) will be affected so the user can catch mismatches.

## Quick action — one-click WordPress login

"Log me into X": resolve the site from `GET /sites` (name/URL → id; ambiguous → list and ask), then `GET /sites/{site_id}/wp/users/sso-login-url` (staging: `GET /staging-sites/{id}/wp/users/sso-login-url`). Return the link as clickable, saying which site and user it logs in as. **The URL is a signed, time-limited credential** — deliver it directly, never store it in files or logs. If the site's `connection.status` isn't connected, say so plainly (a disconnected plugin can't serve SSO).

## Async tasks (all mutations)

Mutating POSTs (updates, restores, migrations, cleanups, syncs) start background tasks and return task info. Poll `GET /tasks/{task_id}` (envelope `{ "task": { ... } }`) every 5–10 seconds. Statuses: `initializing`, `running` → in flight; `completed`, `failed`, `cancelled`, `aborted` → terminal. Cancel with `POST /tasks/{task_id}/cancel` — only on user request. Never report success before the task completes; report failures with the task's error details.

## Operating system — the two modes (every flow, every action)

Classify every contemplated action before executing it:

**Mode 1 — "Handled" (act autonomously, log to briefing).** Requires ALL of: reversible (rollback path exists), inside the verification loop (backup-first + visual regression + health test where the operation supports it), routine (no major-version jump, no business-critical component, no failed history, not locked, not tagged `wpr-ai:hold`), within the change budget (default 20 sites/window).

**Mode 2 — "Ready, say go" (prepare everything, wait for one word).** Everything else — including anything unclassified. The agent completes ALL preparation (analysis, checks, staging + verification where applicable, consequence mapping, final backup before destructive steps) and presents a one-line prepared action with a recommendation. The user authorizes; the user never analyzes. **Unclassified → Mode 2 with your best-prepared recommendation — never improvise a mutation.**

### Unmapped situations — the generalization rule (applies to every WP Remote skill)

Any request that matches no skill and no example still resolves through the same procedure:

1. Translate the request into an intended outcome ("undo X", "know Y", "make Z stop").
2. Find the minimal API-supported way to observe or achieve it — prefer reads over writes; verify endpoint and parameter names against the reference; **never improvise**.
3. Classify the action Mode 1 / Mode 2 with the same criteria — **unknown ⇒ Mode 2**.
4. If changing anything: smallest scope that covers the intent, backup-first where the platform supports it, and a prepared one-line proposal stating exactly what will be touched and what will not.
5. Report what you did — and what you deliberately did not cover.

Scenario lists inside skills are **calibration examples for the procedure, never its boundary**.

### Controls (always on)

1. **Irreversibility floor:** deletes, credential operations (passwords/2FA/security keys), money, anything leaving the account (emails) → always Mode 2 with mandatory prep. Not configurable away.
2. **Backup-first invariant:** every mutation runs inside a task that snapshots first; **auto-rollback** when verification fails (`wp_test` failed or visual regression >10% → restore the pre-action snapshot, freeze that item fleet-wide, report in briefing; 2–10% → hold + attach diff screenshots; ≤2% → pass).
3. **Canary waves + stop-on-repeat:** fleet actions run least-critical sites first in small waves with verification between; the same item failing twice freezes it everywhere.
4. **Rate budget:** 200 req/min account-wide — batch and throttle.
5. **Audit trail:** retain task IDs, snapshot IDs, screenshots; the briefing is the review surface.

### The briefing (single reporting surface — weekly and on-demand)

> **Handled:** aggregate + exceptions + auto-rollbacks and why.
> **Ready for your go (≤5):** one-line prepared actions with recommendations.
> Full log on request — never dumped by default.

## Error handling

- `401` → token missing/invalid/expired. Tell the user to regenerate at My Account → API Credentials and update `WPR_API_KEY`.
- `403` → plan may not include the feature; report plainly.
- `404` → wrong ID; re-resolve from `GET /sites`.
- `429` → rate limited: wait ~30 s, retry, then slow the polling cadence.
- `5xx` → wait 10 s, retry once, then report.

## Most-used endpoints

| Purpose | Call |
|---|---|
| List sites — rich state per site (core/updates, backups, uptime, malware, PHP version, tags) | `GET /sites` |
| Site detail | `GET /sites/{site_id}` |
| Pending updates across sites | `GET /sites/wp/updates` |
| Perform updates (bulk, per-site targeting) | `POST /sites/wp/updates/perform` |
| Plugins / themes (list, install, activate, lock…) | `GET/POST /sites/wp/plugins`, `/sites/wp/themes` |
| Vulnerable plugins/themes/core — severity (CVSS) + virtual-patch status | `GET /sites/wp/plugins?include_vulnerabilities=true` (also `/sites/wp/themes`, `/sites/wp/wordpress-core`; plan-gated) |
| Snapshots | `GET /sites/{site_id}/snapshots` |
| Restore | `POST /sites/{site_id}/backups/{snapshot_id}/restore` |
| Uptime / SSL / domain monitors | `GET /monitoring/uptime-monitors`, `/ssl-monitors`, `/domain-monitors` |
| Malware summary | `GET /sites/{site_id}/security/scanner/detections/summary` |
| One-click WP login | `GET /sites/{site_id}/wp/users/sso-login-url` |
| Task status | `GET /tasks/{task_id}` |
| Tags (policy persistence) | `GET/POST /tags`, `POST /tags/{tag_id}/assign` |

For any endpoint not listed here, consult the reference at https://docs.blogvault.net/api/v6 — do not improvise parameter names.
