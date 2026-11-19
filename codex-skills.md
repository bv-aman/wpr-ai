# WP Remote — AI Site Professional (skills bundle for Codex)

Append this file to `~/.codex/AGENTS.md` (global) or your project's `AGENTS.md`. These skills manage the user's WordPress sites through the WP Remote API. Prerequisite: API token in env var `WPR_API_KEY` (see SETUP.md). The first skill below (`wpremote`) is the foundation the others build on — keep it first.

<!-- ===== SKILL: wpremote ===== -->

---
name: wpremote
description: Manage the user's WordPress sites through their WP Remote account (REST API v6) â€” sites, updates, backups, security, monitoring, WP users, reports, one-click logins. Use whenever the user mentions their sites, WP Remote, pending updates, backups, uptime, malware, logging into a site, or asks to manage WordPress sites in bulk.
---

# WP Remote â€” site fleet operations

The user manages WordPress sites with WP Remote. This skill talks to their account over the official REST API. It also defines the **operating system every WP Remote flow runs on**: two action modes, controls, and the briefing.

- Base URL: `https://api.blogvault.net/api/v6`
- Full reference: https://docs.blogvault.net/api/v6

## Authentication

- The API token is in the environment variable `WPR_API_KEY` (the user generates it in the WP Remote dashboard: **My Account â†’ API Credentials**).
- Send it on every call as `Authorization: Bearer <token>`.
- **Never print, echo, log, or write the token value anywhere.** Reference it from the env var only:
  - PowerShell: `$env:WPR_API_KEY`
  - bash/zsh: `$WPR_API_KEY`

## Calling conventions

Use `curl` (present on macOS, Linux, Windows 10+; on Windows PowerShell use `curl.exe` explicitly â€” plain `curl` is an alias for Invoke-WebRequest there).

For POST bodies, always write the JSON to a temp file and use `-d @file` â€” this avoids all shell-quoting problems:

PowerShell:
```powershell
@'
{ "sites": [ ... ] }
'@ | Set-Content -Path "$env:TEMP\wpr_body.json" -Encoding UTF8
curl.exe -s -X POST "https://api.blogvault.net/api/v6/sites/wp/updates/perform" `
  -H "Authorization: Bearer $env:WPR_API_KEY" -H "Content-Type: application/json" `
  -d "@$env:TEMP\wpr_body.json"
```

bash:
```bash
cat > /tmp/wpr_body.json <<'EOF'
{ "sites": [ ... ] }
EOF
curl -s -X POST "https://api.blogvault.net/api/v6/sites/wp/updates/perform" \
  -H "Authorization: Bearer $WPR_API_KEY" -H "Content-Type: application/json" \
  -d @/tmp/wpr_body.json
```

- GETs need only the auth header. Responses are JSON â€” parse them directly; do not require `jq` or any other tool.

## Pagination

List endpoints return `{ <items>, meta: { pagination: { page, perPage, totalPages, totalItems } } }`; default `perPage` is 100. Fetch every page with `?page=1&perPage=100`, `?page=2`, â€¦ and **aggregate before analyzing**. Some list endpoints also accept `sort`, `timezone`, and deepObject `filters` (e.g. `filters[timestamp:gte]=â€¦`, `filters[ip_address:contains]=â€¦`, `filters[tags:in]=428`).

## Resolving sites

Users speak in site names/URLs; the API uses site IDs. Start from `GET /sites` (all pages) and build the name/URL â†” id mapping. Before any Mode 2 action, state which site (title + URL) will be affected so the user can catch mismatches.

## Quick action â€” one-click WordPress login

"Log me into X": resolve the site from `GET /sites` (name/URL â†’ id; ambiguous â†’ list and ask), then `GET /sites/{site_id}/wp/users/sso-login-url` (staging: `GET /staging-sites/{id}/wp/users/sso-login-url`). Return the link as clickable, saying which site and user it logs in as. **The URL is a signed, time-limited credential** â€” deliver it directly, never store it in files or logs. If the site's `connection.status` isn't connected, say so plainly (a disconnected plugin can't serve SSO).

## Async tasks (all mutations)

Mutating POSTs (updates, restores, migrations, cleanups, syncs) start background tasks and return task info. Poll `GET /tasks/{task_id}` (envelope `{ "task": { ... } }`) every 5â€“10 seconds. Statuses: `initializing`, `running` â†’ in flight; `completed`, `failed`, `cancelled`, `aborted` â†’ terminal. Cancel with `POST /tasks/{task_id}/cancel` â€” only on user request. Never report success before the task completes; report failures with the task's error details.

## Operating system â€” the two modes (every flow, every action)

Classify every contemplated action before executing it:

**Mode 1 â€” "Handled" (act autonomously, log to briefing).** Requires ALL of: reversible (rollback path exists), inside the verification loop (backup-first + visual regression + health test where the operation supports it), routine (no major-version jump, no business-critical component, no failed history, not locked, not tagged `wpr-ai:hold`), within the change budget (default 20 sites/window).

**Mode 2 â€” "Ready, say go" (prepare everything, wait for one word).** Everything else â€” including anything unclassified. The agent completes ALL preparation (analysis, checks, staging + verification where applicable, consequence mapping, final backup before destructive steps) and presents a one-line prepared action with a recommendation. The user authorizes; the user never analyzes. **Unclassified â†’ Mode 2 with your best-prepared recommendation â€” never improvise a mutation.**

### Unmapped situations â€” the generalization rule (applies to every WP Remote skill)

Any request that matches no skill and no example still resolves through the same procedure:

1. Translate the request into an intended outcome ("undo X", "know Y", "make Z stop").
2. Find the minimal API-supported way to observe or achieve it â€” prefer reads over writes; verify endpoint and parameter names against the reference; **never improvise**.
3. Classify the action Mode 1 / Mode 2 with the same criteria â€” **unknown â‡’ Mode 2**.
4. If changing anything: smallest scope that covers the intent, backup-first where the platform supports it, and a prepared one-line proposal stating exactly what will be touched and what will not.
5. Report what you did â€” and what you deliberately did not cover.

Scenario lists inside skills are **calibration examples for the procedure, never its boundary**.

### Controls (always on)

1. **Irreversibility floor:** deletes, credential operations (passwords/2FA/security keys), money, anything leaving the account (emails) â†’ always Mode 2 with mandatory prep. Not configurable away.
2. **Backup-first invariant:** every mutation runs inside a task that snapshots first; **auto-rollback** when verification fails (`wp_test` failed or visual regression >10% â†’ restore the pre-action snapshot, freeze that item fleet-wide, report in briefing; 2â€“10% â†’ hold + attach diff screenshots; â‰¤2% â†’ pass).
3. **Canary waves + stop-on-repeat:** fleet actions run least-critical sites first in small waves with verification between; the same item failing twice freezes it everywhere.
4. **Rate budget:** 200 req/min account-wide â€” batch and throttle.
5. **Audit trail:** retain task IDs, snapshot IDs, screenshots; the briefing is the review surface.

### The briefing (single reporting surface â€” weekly and on-demand)

> **Handled:** aggregate + exceptions + auto-rollbacks and why.
> **Ready for your go (â‰¤5):** one-line prepared actions with recommendations.
> Full log on request â€” never dumped by default.

## Error handling

- `401` â†’ token missing/invalid/expired. Tell the user to regenerate at My Account â†’ API Credentials and update `WPR_API_KEY`.
- `403` â†’ plan may not include the feature; report plainly.
- `404` â†’ wrong ID; re-resolve from `GET /sites`.
- `429` â†’ rate limited: wait ~30 s, retry, then slow the polling cadence.
- `5xx` â†’ wait 10 s, retry once, then report.

## Most-used endpoints

| Purpose | Call |
|---|---|
| List sites â€” rich state per site (core/updates, backups, uptime, malware, PHP version, tags) | `GET /sites` |
| Site detail | `GET /sites/{site_id}` |
| Pending updates across sites | `GET /sites/wp/updates` |
| Perform updates (bulk, per-site targeting) | `POST /sites/wp/updates/perform` |
| Plugins / themes (list, install, activate, lockâ€¦) | `GET/POST /sites/wp/plugins`, `/sites/wp/themes` |
| Vulnerable plugins/themes/core â€” severity (CVSS) + virtual-patch status | `GET /sites/wp/plugins?include_vulnerabilities=true` (also `/sites/wp/themes`, `/sites/wp/wordpress-core`; plan-gated) |
| Snapshots | `GET /sites/{site_id}/snapshots` |
| Restore | `POST /sites/{site_id}/backups/{snapshot_id}/restore` |
| Uptime / SSL / domain monitors | `GET /monitoring/uptime-monitors`, `/ssl-monitors`, `/domain-monitors` |
| Malware summary | `GET /sites/{site_id}/security/scanner/detections/summary` |
| One-click WP login | `GET /sites/{site_id}/wp/users/sso-login-url` |
| Task status | `GET /tasks/{task_id}` |
| Tags (policy persistence) | `GET/POST /tags`, `POST /tags/{tag_id}/assign` |

For any endpoint not listed here, consult the reference at https://docs.blogvault.net/api/v6 â€” do not improvise parameter names.


<!-- ===== SKILL: wpremote-add-site ===== -->

---
name: wpremote-add-site
description: Connect a new WordPress site to WP Remote â€” five-step onboarding combining API v6 and WP-CLI (register the site, install+activate the BlogVault plugin, fetch the connection key, set it via WP-CLI, start the first sync/backup). Use when the user asks to add or connect a site to WP Remote.
---

# Add a site (API + WP-CLI) â€” Mode 2 end-to-end

Everything prepared, one "go", five verified steps, one report. Per the base skill's irreversibility floor this is always a prepared action â€” the customer authorizes, never analyzes.

## What the customer provides (one message, only what they alone know)

1. **The site URL.**
2. **How the agent can reach WP-CLI on that site** â€” one of:
   - an SSH alias or command (`ssh sg-shop`, path `/www/shopxyz/public`) â€” works when they already have key-based SSH set up; the agent uses their existing access, **never ask for SSH passwords in chat**
   - a local path for dev sites (`~/sites/dev-example`)
   - "no shell access" â†’ **manual-mode fallback** below
3. *Only if applicable:* HTTP basic-auth credentials for the site (â†’ `connection.http_auth` in the API call, not logged), sticky-IP requirement, agency assignment ("add to client X, tag Production").

Everything else â€” registration, plugin, key handling, first sync â€” is the agent's job.

## Prerequisites (verify before proposing)

- **WP-CLI reachability:** verify with a benign call first (`wp --info`, `wp plugin list`) over the access the customer described.
- The site is a live WordPress install reachable at its URL.
- **Not already connected:** `GET /sites`, match by URL. If present â†’ don't re-add; offer `POST /sites/{id}/sync` or key-reset recovery instead.

## Manual-mode fallback (no shell access)

Preferred: **plugin self-connect** â€” guide the customer to install "BlogVault real-time backup" from the Plugins page in wp-admin and use the plugin's built-in connect/sign-in to their existing WP Remote account (zero pastes, zero secrets; if the plugin supports a one-click account connect, prefer that over key paste).

Otherwise the agent performs steps 1, 3, and 5 over the API and hands the customer a two-paste card: (1) install "BlogVault real-time backup" from the plugin repo in wp-admin (or two ready-made commands for their host's terminal), (2) paste the connection key into the plugin's settings page. Customer effort: one message â†’ two pastes; everything else stays automated.

**Never** automate via the customer's wp-admin credentials (platform-logging-into-wp-admin style) â€” no channel that requires the customer to hand over wp-admin passwords.

## Prepare, then one line

After the checks: *"Ready to connect https://X â€” register in WP Remote, install + activate the BlogVault plugin, set the connection key, run the first backup. Go?"* â€” wait for the word.

## Execute (after "go") â€” five steps, verify each

1. **Register:** `POST /sites` with `{ "site": { "url": "https://X" } }` â€” add `connection.http_auth` / `sticky_ip` only if the site sits behind basic auth or a sticky origin. **Save the returned `site_id`.**
2. **Plugin:** `wp plugin install blogvault-real-time-backup --activate` (already installed â†’ `wp plugin activate blogvault-real-time-backup`). Verify with `wp plugin list`.
3. **Connection key:** `GET /sites/{site_id}/key` â†’ `{ "key": "..." }`. **The key is a secret** â€” capture it into a shell variable; never print, echo, or log it; never leave it in shell history or files.
4. **Set the key (value referenced, never printed):**
   - bash: `KEY=$(...); wp blogvault setkey --key="$KEY"`
   - PowerShell: `$k = (...).key; wp blogvault setkey --key="$k"`
5. **First sync:** `POST /sites/{site_id}/sync` â†’ `{ "sync": { "snapshot_id": "...", "in_progress": true } }` â€” track via `GET /sites/{id}/snapshots` until the first backup completes; report snapshot id + status.

## Failure handling

- Plugin step fails (repo unreachable, permissions) â†’ report the exact WP-CLI error; the site stays registered; resume from step 2 after fixing.
- Sync fails â†’ check the key was accepted and the plugin can reach the platform; report the snapshot/task error verbatim.
- **Never re-register to "start over"** â€” state exactly which steps completed and resume from the first failed one.

## After connection

Report: site_id, first snapshot id/status. Then hand off to the **`wpremote-onboard-site` skill** â€” the first-day assessment: site analysis + fleet conventions â†’ a curated starter pack of prepared actions the customer approves in one word.


<!-- ===== SKILL: wpremote-firewall-ip-analysis ===== -->

---
name: wpremote-firewall-ip-analysis
description: Full analysis of a firewall-blocked IP across the user's WP Remote sites â€” pulls every firewall log entry and login-protection attempt for that IP, aggregates rules triggered, targeted paths, request pattern and timeline, then recommends whether to whitelist or keep it blocked (and can whitelist on confirmation). Use when the user says an IP was blocked, asks why an IP was blocked, or whether to whitelist/unblock an IP.
---

# Firewall IP analysis â€” blocked IP verdict

Read-only analysis; the whitelist action happens only on explicit confirmation.

## Inputs

1. The IP (full or partial, e.g. `203.0.113.4` or `203.0.113`).
2. Scope: one site or the whole account (default: whole account).
3. Window: default last 7 days.

## Step 1 â€” Gather (read-only)

- `GET /sites` (all pages) â€” site map.
- Per site in scope:
  - `GET /sites/{site_id}/security/firewall/logs?filters[ip_address:contains]=<IP>&filters[timestamp:gte]=<start>` (all pages) â€” every hit, blocked or allowed, with rule and request detail.
  - `GET /sites/{site_id}/security/login-protection/attempts?filters[ip_address:contains]=<IP>` â€” brute-force attempts against logins.
- **Rate limit discipline**: the account allows 200 requests/min. Large fleets: query sites in batches, prioritize the site(s) where the user saw the block.

## Step 2 â€” Aggregate

- Volume: total hits, blocked vs allowed, per site.
- What it did: top triggered rules, top targeted paths, HTTP methods, burst pattern (short burst vs sustained scanning), first/last seen.
- Login context: failed login attempts from this IP.
- Behavior read: crawling generic pages vs probing `wp-login.php`/`xmlrpc.php`/admin paths vs hammering a form.

## Step 3 â€” Verdict (show the evidence, then the recommendation)

- **Keep blocked** (default when in doubt): scanning/probing patterns, many rules triggered, brute-force attempts, hits across many sites it has no business with.
- **Whitelist candidate**: known service (uptime monitor, search crawler) with benign request patterns, or the user's own/office IP (low volume, normal browsing) â€” confirm the story with the user.
- **Ambiguous**: present the evidence table and let the user decide; never push.

## Step 4 â€” Action (Mode 2: ready, say go)

Whitelist per site: `POST /sites/{site_id}/security/firewall/ip-access/whitelist` with the IP. The analysis (Steps 1â€“3) is Mode 1 â€” handled, no asking. The whitelist itself arrives prepared: which sites, why the evidence supports it, how to reverse it â€” one line, one word to execute.

Present result: what changed, on which sites, and how to reverse it (`POST .../firewall/ip-access/delete`).


<!-- ===== SKILL: wpremote-health-report ===== -->

---
name: wpremote-health-report
description: Fleet health report via WP Remote â€” one pass across all sites producing an executive summary (uptime, pending updates incl. WordPress core, vulnerabilities, malware status, last backup, SSL expiry, PHP versions) with a per-site table and a ranked attention list. Use when the user asks for a health report, status of all their sites, a weekly report, or how their sites are doing.
---

# Fleet health report

Read-only. One pass, one report.

## Step 1 â€” Gather (read-only)

1. `GET /sites` (all pages) â€” per site: `uptime.status`, `wp.core` (current/latest/update_available), `security.scanner.status`, `backups.latest_snapshot` + `available_snapshots`, `server.php_version`, `connection.status`, `locked`, tags.
2. `GET /sites/wp/updates` â€” pending plugin/theme update counts per site.
3. `GET /sites/wp/plugins?include_vulnerabilities=true` â€” vulnerable plugin count per site with worst severity (skip gracefully if the plan doesn't enrich; fall back to the flat `vulnerable` flag).
4. `GET /monitoring/ssl-monitors` (+ `certificate-details` per monitor) â€” certificate expiry dates.

## Step 2 â€” Report

**Executive summary** (numbers first): N sites Â· X up / Y down Â· Z with pending core updates Â· W with vulnerable plugins (worst severity) Â· any malware flags Â· SSL certs expiring <14 days Â· sites with stale backups (>7 days since last snapshot).

**Per-site table**:
`site (URL) | uptime | core | pending plugins/themes | vulnerable (worst) | scanner | last backup | PHP | SSL expiry`

**Attention list**, ranked:
1. malware flagged / site down
2. critical/high vulnerabilities without virtual patch
3. expired or soon-expiring SSL
4. stale or missing backups
5. pending core updates

**Trend note**: if the user runs this weekly, compare against the previous report if they still have it â€” otherwise offer to save this one as a markdown file they can diff next week.

Scheduling/sending (Mode 2 â€” "ready, say go"): recurring emails or scheduled reports are prepared ("weekly summary to ops@â€¦ â€” go?") and executed on one word; generating/saving/diffing reports is Mode 1.


<!-- ===== SKILL: wpremote-migrate ===== -->

---
name: wpremote-migrate
description: Website migration via WP Remote â€” move a site to another server (external, pushed over FTP/SFTP/FTPS + direct database import, no plugin needed on the destination) or onto another site already in the account (internal, over HTTP). Always fully prepared â€” destination verified, rollback point recorded, cutover plan stated â€” for one-word approval. Use when the user asks to migrate, move, or clone a site to a new host/server or another site.
---

# Website migration â€” always Mode 2

Migration overwrites the **destination**. Always a prepared action; the customer authorizes, never analyzes.

## Choosing the way (the procedure, not a table)

The type is decided by **where the destination lives** â€” a site on this account â‡’ internal; any other server â‡’ external. Everything else follows the same preparation procedure below. Requests that are really "copy for testing" belong to the staging skill; "selective component copy" belongs to the restore skill (paths scope) â€” recognize the intent and route there.

Reference for the two ways:

| | **Internal** (`type: "internal"`) | **External** (`type: "external"`) |
|---|---|---|
| Destination | a site already added on this account | any server, anywhere |
| Transport | `connection.method: "http"` (only) | `connection.method: "ftp"` + FTP/SFTP/FTPS server credentials + **database credentials (required)** |
| Destination needs plugin? | yes â€” must be `connected` | **no** â€” files pushed via FTP, DB imported directly |
| Typical use | copy/rebuild between your own sites, push to a staging-linked site | host migration, moving servers |

For "spin up a copy to test on" â€” that's the staging skill (`POST /staging-sites`), not a migration. Use this skill when the destination is a real site.

## 1. Gather inputs

- Source site (name/URL â†’ id) and snapshot to migrate from (default: latest succeeded; point-in-time via `options.real_time_events: { enabled: true, until: <ts> }` when near-zero-loss cutover matters).
- Destination: internal â†’ which account site; external â†’ destination URL + server credentials (`protocol: ftp|sftp|ftps, host, username, password | private_key, path, port`) + database credentials (`host, username, password, name`), optional `http_auth` if the destination web server is protected.
- Scope: default full (`include_files: true, include_database: true`); `paths`/`tables` for partial.

## 2. Prepare (before the go)

1. **Source:** snapshot exists, status `succeeded`; state its timestamp.
2. **Destination â€” internal:** resolve via `GET /sites` URL match; must be `connected`; **record its latest snapshot id as the rollback point** (that's how you undo this migration); state plainly that the destination will be overwritten.
3. **Destination â€” external:** TCP pre-flight to host:port from the customer's machine; credential format checks (SFTP: password or private key, not both required); remind that destination DB will be imported into directly.
4. **Options to propose:**
   - `retain_latest_posts` / `retain_latest_woocommerce_orders` â€” keep newer content at the destination (merge-style migration)
   - `preserve_permissions: true`
   - `options.server: { ip, name_server }` â€” destination server metadata (helps routing during cutover)
   - `real_time_events.until` â€” capture source changes past the snapshot up to a cutoff (near-zero-downtime cutover)

## 3. The one line

> "Ready: migrate yoursite.com (snapshot Nov 11 11:09 UTC) â†’ https://new.example.com over SFTP + DB import. Destination will be overwritten. Rollback: destination snapshot `6af45â€¦` recorded. DNS cutover stays yours. Go?"

## 4. Execute and track

- `POST /sites/{site_id}/backups/{snapshot_id}/migrate` â€” body via temp file (contains credentials: never print, delete after). Envelope `{ migration: { destination_url, type, scope, connection?, options } }`.
- Poll `GET /tasks/{id}`; migrations are long â€” progress on request.
- **Post-migration:**
  - internal â†’ verify destination (`GET /sites/{dest_id}` sync status), report.
  - external â†’ the platform cannot flip DNS: remind the customer of the cutover step; once DNS points at the new server, offer the **add-site skill** to register the new site in WP Remote so protection continues.

## 5. Failure handling

- Report the failing step + error verbatim (connection refused / auth failed / DB import error / disk full).
- Safe to re-run the same migration (idempotent re-push); never silently change destination or snapshot on retry â€” re-confirm.
- Credentials never echoed in chat, logs, or the briefing.

## Connection testing (same reality as restore)

No dry-run test endpoint exists today. Pre-flight = TCP reachability + format checks + account-side state; the task's first steps are the real credential test and **fail fast before destination writes begin**.


<!-- ===== SKILL: wpremote-onboard-site ===== -->

---
name: wpremote-onboard-site
description: First-day assessment of a newly connected site via WP Remote â€” after the first sync, analyzes the site (health score, pending updates, vulnerabilities, hack/redirection detections) AND the fleet's existing conventions (monitoring, tags, auto-update schedules, reports, GA), then presents a curated starter pack of prepared actions the customer approves in one word. Use when a site was just added or connected, or when asked what to set up for a site.
---

# New-site onboarding â€” the first-day assessment

The professional's first day with a new site: assess it, compare it to how the customer runs everything else, and propose a starter pack. Every recommendation cites fleet evidence â€” never generic advice. Runs when add-site completes (automatic handoff) or on request.

## Procedure

1. **Confirm readiness:** first sync completed (`sync.last_sync_status: succeeded` + `backups.latest_snapshot` exists). Still syncing â†’ say so and wait. Sync failed â†’ stop; hand to the breakage-triage skill.
2. **Read the new site** (all reads):
   - `GET /sites/{id}` â€” `health.score` + `health.status` (the headline), connection, core versions, PHP, `woocommerce`, `multisite`
   - plugins / themes / core with `include_vulnerabilities=true` â€” pending updates; vulnerabilities with severity + virtual-patch coverage
   - `security.scanner.status` + detections summary (and `detections/redirections` when the scanner flags) â€” **hacked or redirection detected = urgent findings, they lead the pack**
3. **Read the fleet's conventions** (this is what makes it curated â€” every proposal gets its evidence here):
   - `GET /sites` aggregate â€” share of sites with uptime monitoring, SSL monitors, firewall, activity logs, real-time backups on
   - `GET /tags` â€” which tags exist (client, production, â€¦) and which fit this site
   - `GET /auto-update-schedules` â€” active schedules: an `all`-scope schedule **already covers** the new site (say so); filename-scoped ones are "add to X" proposals
   - `GET /scheduled-reports` â€” fleet reports this site should count in
4. **Compose the starter pack:**
   - **Findings:** health score headline â†’ pending updates (criticals first) â†’ vulnerabilities (worst severity, VP coverage) â†’ URGENT section if hacked/redirections â†’ version/PHP notes.
   - **Prepared actions** (one word applies the batch):
     1. security-critical path if compromised (cleanup eligibility â†’ its Mode 2 flow)
     2. safe update sweep if updates pending (`wpremote-updates` skill)
     3. enable uptime + SSL monitoring (+ visual if that's the fleet convention) â€” *cite the stat: "your other 5 sites run uptime monitoring"*
     4. tags matching convention
     5. add to filename-scoped auto-update schedules / confirm already covered
     6. add to the fleet's scheduled report
     7. GA connection if the fleet uses it â€” **state plainly it's dashboard-only today** (not in the public API) with where to click; never mark it done
5. **After approval:** execute the batch (monitoring/tags handled; schedule/report additions via their prepared calls; updates via the sweep skill), verify each landed, then hand the site to steady state â€” it appears in the briefing from now on.

## Calibration examples (the procedure handles cases beyond these)

| Situation | Resolution |
|---|---|
| "Just added shop.example.com â€” what should we do?" | full pack |
| add-site completed | automatic handoff into this skill |
| "Assess site X" (added long ago, never onboarded) | same procedure, framed as a catch-up audit |
| Fleet of one (no conventions exist) | recommend sensible defaults, **labeled as defaults, not fleet conventions** â€” this pack becomes the customer's convention |
| Fleet split on a convention (50/50 monitoring) | recommend the majority, note the split, let the word decide |
| Site arrives already hacked | urgent findings lead; cleanup flow prepared; no routine setup proposed until it's clean |

## Rules

- Every recommendation cites its evidence (fleet percentage, schedule name, tag name). No evidence â†’ say it's a default, not a convention.
- Nothing executes before the pack approval â€” onboarding is the one moment everything is shown; a new site has no established policy yet, and this pack **sets** it (critical tags, hold tags, monitoring baseline).
- Findings never buried under setup items.
- Dashboard-only capabilities (GA today) are stated as such â€” honesty over theater.
- Generalization rule from the base skill applies throughout: anything unlisted resolves through intended outcome â†’ minimal path â†’ classify â†’ prepared proposal.

## Hand-offs

`wpremote-updates` (updates, vulnerabilities, schedules) Â· security cleanup flow (compromised) Â· `wpremote-site-breakage-triage` (failed sync) Â· `wpremote-visual-monitoring` (monitor enablement) Â· briefing (steady state).


<!-- ===== SKILL: wpremote-restore ===== -->

---
name: wpremote-restore
description: Backup restore via WP Remote â€” full or selective, over HTTP or FTP/SFTP/FTPS. Resolves any restore request â€” "restore the plugins from my 2pm task", "undo the WooCommerce update", "bring back the uploads folder", "put the site back to last Tuesday" â€” into the minimal correct scope against the right snapshot, fully prepared for one-word approval. Use when the user asks to restore, roll back, undo an update/change, or recover anything from a backup.
---

# Backup restore â€” always Mode 2

Restore overwrites whatever it touches: irreversibility floor, **always** a prepared action. The customer authorizes; they never analyze.

## The resolution procedure (this is the skill â€” it handles requests this file never mentions)

Every restore request, known or novel, resolves through these five steps:

1. **Translate the words into an intended outcome.** What changed, what's broken, what should become true again. ("Restore the plugins from my 2pm task" â†’ *the code of exactly those plugins, as it was before that task.*)
2. **Find the change source** â€” the event that made "now" wrong: an update task (`GET /tasks` â€” its `input` is a manifest of exactly what changed), an auto-update run, a malware cleanup, an import, a deletion, an edit. Sources: task manifests, `auto-update-history`, cleanup reports, activity logs. No source found â†’ fall back to the customer's time reference.
3. **Resolve to the minimal scope that fully covers the intent** â€” component â†’ `paths`/`tables` via the live catalogs (below). Smaller is safer, but never so small it half-fixes; when torn between two scopes, propose the smaller one **and state what it does not cover**.
4. **Pick the snapshot**: latest *succeeded* before the change (or the named point in time). State id + timestamp.
5. **Package the one line**: loss statement scoped to what's touched, loss-reducers where they apply, method chosen by site state, cautions where they apply. One word executes it.

## Resolution mechanics (never guess)

- **Task-driven chains:** `GET /tasks?filters[type:eq]=wp_site_update` (+ window) â†’ `input.sites[].plugins[].filename` / `.themes[].filename` = exactly what was updated; `details.sites[].steps` gives the `pre_snapshot` timing and flags `update_plugin_db` (DB caveat below). Auto-updates resolve via `GET /auto-update-history` â†’ its task.
- **Component â†’ scope:** plugin `filename: "woocommerce/woocommerce.php"` â†’ `./wp-content/plugins/woocommerce/`; theme â†’ `./wp-content/themes/<stylesheet>/`; core â†’ `./wp-admin/` + `./wp-includes/` (+ root core files). Tables â†’ **real names from the site's catalog**.
- **Catalog validation (authoritative):** `GET /sites/{id}/files` â†’ `{ files: [{ path, type, status }] }`; `GET /sites/{id}/tables` â†’ `{ tables: [{ name, rows, status }] }`. Every path/table in the scope must exist there; correct mismatches before proposing.
- **Loss-reducers:** `retain_latest_posts`, `retain_latest_woocommerce_orders` (site has `woocommerce: true`), `real_time_events: { enabled: true, until: <ts> }` for point-in-time (real-time backups required).
- **Method:** HTTP (omit `connection`) when the site is connected; FTP/SFTP/FTPS (`connection.method: "ftp"` + server creds + **required** database creds) when it's down/disconnected or the customer wants direct server write; `http_auth` when behind basic auth. Pre-flight: TCP reachability + format + catalog checks â€” the task's first steps are the real credential test (fail-fast before writes).

## Standing cautions (apply whenever their condition is true, listed or not)

- **DB-migration caveat:** rolling back a plugin files-only when its update ran `update_plugin_db` leaves newer schema under older code. State it; offer files-only / +tables (loss warning) / full restore / staging test.
- **Old-snapshot caution:** full-files restore brings back that era's `wp-config.php` â€” flag if hosting/DB credentials changed since.
- **Granularity honesty:** DB restores are per-table, not per-row/per-page. When the customer asks for finer granularity than the API has, say so and propose the nearest scope plus loss-reducers.
- **Inclusion-only:** scope has no excludes. If the intent needs "everything except X", say it's not expressible; propose the nearest alternative (targeted restores of what matters, or full restore â€” noting current uploads etc. remain in a snapshot either way).

## Worked examples (calibration for the procedure â€” not an exhaustive list)

| Request | Resolution |
|---|---|
| "Restore the plugins from my 2pm task" | task manifest â†’ plugin dirs â†’ pre-update snapshot â†’ files-only |
| "Undo the update" (whole run) | every component the task touched; core â†’ core paths |
| "Undo the WooCommerce update" (no task named) | find its `update_plugin` step â†’ snapshot before it |
| "Restore the theme but keep my settings" | theme dir only â€” settings live in DB, untouched |
| "Restore the database only" | `include_database: true`, no files |
| "Undo what the import did to my posts" | posts + postmeta tables + `retain_latest_posts` |
| "Bring back the deleted uploads folder" | paths restore of that folder |
| "Put the site back to last Tuesday" | pre-Tuesday snapshot + `real_time_events.until` Tuesday EOD |
| "Undo the malware cleanup" | cleanup report's file list â†’ pre-cleanup snapshot |
| "Restore subsite X" (multisite) | `subsite_ids` |

## The one line (shape, for any scope)

> "Ready: restore **<exact scope>** on <site> from snapshot `<id>` (<timestamp> â€” <why this one>). Touches: <what>. Doesn't touch: <what>. <Cautions if any>. Go?"

## Execute and track

- `POST /sites/{site_id}/backups/{snapshot_id}/restore` â€” body via temp file (credentials possible: never print, delete after). Envelope `{ restore: { scope, connection?, options } }`.
- Poll `GET /tasks/{id}` â€” progress on request. Verify `GET /sites/{id}` after. Offer a visual check (visual-monitoring skill refresh) for anything user-visible.

## Failure handling

- Report the failing **step** and error verbatim.
- Retry the same snapshot + scope is safe; **never silently change snapshot or scope** â€” re-confirm.
- Credentials never echoed in chat, logs, or the briefing.

## Notes

- "Push staging to production" belongs to the migrate/staging skills, not this one.
- Not available today: exclude lists in scope (`exclude_paths`) and a dry-run credential-test endpoint.


<!-- ===== SKILL: wpremote-site-breakage-triage ===== -->

---
name: wpremote-site-breakage-triage
description: First-response investigation for a broken WordPress site via WP Remote â€” builds a timeline of everything that changed on the site in a time window (plugin/theme/core updates, activations, restores, malware cleanups, user actions) from activity logs, task history, and auto-update history, then ranks the most likely cause of the breakage. Use when the user says a site is broken, broken since a certain time, something changed/deleted itself, or asks what changed on a site.
---

# Site breakage triage â€” "why did my site break?"

Read-only investigation. It changes nothing; it produces a diagnosis and recommended next step.

## Inputs (ask if not given)

1. Which site (name or URL).
2. When it broke / when the problem was first noticed (be precise if possible; default window: 72 h before "now" if unknown â€” confirm with the user).
3. Symptoms (frontend down, white screen, specific page, admin locked outâ€¦) â€” optional but sharpens the verdict.

## Step 1 â€” Gather (read-only, all pages)

- Resolve the site via `GET /sites` (per the `wpremote` skill).
- **Activity logs**: `GET /sites/{site_id}/activity-logs?sort=timestamp,desc` with `filters[timestamp:gte]=<window_start>&filters[timestamp:lte]=<window_end>` (`perPage` up to 500). These capture WP-side changes: plugin/theme updates and activations, core updates, page/post changes, user logins â€” with usernames.
- **WP Remote tasks**: `GET /tasks?filters[type:eq]=wp_site_update` (+ other types if relevant) in the window â€” updates run through WP Remote.
- **Auto-update history**: `GET /auto-update-history?filters[performed_on:gte]=<start>` â€” scheduled auto-updates.
- **Malware cleanups**: `GET /sites/{site_id}/security/scanner/cleanup` â€” any cleanup runs.
- **Snapshots**: `GET /sites/{site_id}/snapshots` â€” backup trail (and restore traces).
- Current state: `GET /sites/{site_id}` â€” uptime status, scanner status (`hacked` changes everything), connection status.

## Step 2 â€” Correlate

Build one merged timeline: `time | event | what changed | actor (username/system) | source (activity log / task / auto-update / cleanup)`.

Then rank likely causes:
1. Changes closest before the breakage time (updates, activations, deactivations, deletions).
2. Any plugin/theme update â€” especially major-version jumps or items with `database.update_required`.
3. Malware or cleanup activity near the time.
4. If nothing changed via any source â†’ say so plainly; cause is likely outside this site's tracked activity (hosting, DNS, external edits). Don't invent a culprit.

## Step 3 â€” Report and recommend

- The timeline table.
- Most likely cause(s), ranked, each with its evidence.
- Recommended next step:
  - update-related breakage â†’ restore the most recent snapshot taken **before** the change (`POST /sites/{site_id}/backups/{snapshot_id}/restore` â€” offer it, never run it without an explicit request; confirm the snapshot timestamp back to the user first)
  - scanner says `hacked` â†’ suggest a malware cleanup flow
  - nothing found â†’ suggest checking hosting/DNS with the symptoms in hand.

**Safety**: this skill never mutates anything. Restore/cleanup follow Mode 2 ("ready, say go"): the agent prepares the exact action â€” correct pre-change snapshot chosen, data-loss window stated in one line ("restores to yesterday 03:00; loses changes made since") â€” and the customer spends one word.


<!-- ===== SKILL: wpremote-updates ===== -->

---
name: wpremote-updates
description: The update brain for WP Remote â€” everything about updates. Fleet-wide vulnerability-aware sweeps ("update everything safely"), targeted updates ("update WooCommerce everywhere / on these sites"), update audits and vulnerability reports, and native auto-update schedules (set up, view, review what a schedule run did). Routine safe updates run autonomously with backup, visual regression, health test, and auto-rollback; risky items arrive fully prepared for one word. Use for any plugin/theme/core update, vulnerability, or auto-update schedule request.
---

# Updates â€” one brain, every scope

Two entry scopes, one classification, one safety loop, one briefing:

- **Proactive sweep** â€” nobody named a target: audit everything (pending updates + vulnerabilities across all sites), prioritize, handle the safe, prepare the risky.
- **Targeted run** â€” the customer named it: "update all plugins", "update X everywhere", "update X on sites A and B". **An explicit instruction is the authorization for that exact scope.** What still comes back for one word is anything they didn't know when they asked.

Plus the **always-on layer**: native auto-update schedules (last section).

## First run â€” onboarding (once)

Ask briefly (defaults in parentheses):
1. Which sites are production-critical or ecommerce? (infer: WooCommerce flag, uptime history) â†’ tag `wpr-ai:critical`
2. Maintenance window? (off-hours)
3. Anything that should always wait for a go-ahead even if routine? (locks are honored regardless) â†’ tag `wpr-ai:hold`
4. Change budget and visual-regression sensitivity? (20 sites/window; pass â‰¤2%, rollback >10%)

Persist via `POST /tags` + assign. Never re-ask.

## Classify â€” the axes are the procedure

Situations not named below don't need new rules: every item resolves through **reversibility, jump size, failed-update history, site criticality, and budget**. When genuinely ambiguous, treat as Mode 2 with the smaller proposed scope and say what it doesn't cover.

**Mode 1 â€” handled (no pre-approval):** patch/minor updates where the item is not locked, has no failed history, is not a major-version jump, is not a business-critical component on a `wpr-ai:critical` site, and is within budget. Vulnerable-but-VP-protected items can wait for the next sweep; unpatched (no VP) criticals jump the queue.

**Mode 2 â€” ready, say go (the surprises):**
- **Major-version jumps:** do the prep yourself â€” create a staging copy from the latest snapshot (`POST /staging-sites`), update there, verify, then: *"Ready: X 2.5â†’3.2 on 12 sites, staging-verified clean. (a) roll out (b) non-production first (c) hold."*
- **Locked items:** consequences prepared ("locked by your rule; the update clears critical 9.8 â€” ready to override on site X").
- **Beyond-budget batches:** one prepared batch, one word.
- **No update package available** (license-side, repo-missing): report with the reason; never force.

Already-current targets: listed as "current", no action, no noise.

## Audit (sweep scope)

`GET /sites` (map, connected state) Â· `GET /sites/wp/updates` Â· plugins/themes/core with `include_vulnerabilities=true`. Urgency = `severity Ã— unprotected (no VP) Ã— site criticality Ã— fix availability`. Disconnected sites can't be updated â€” list as FYI, don't retry forever.

## Execute â€” verified waves

1. Sort sites least-critical first; wave 1 = 1â€“3 non-critical sites.
2. `POST /sites/wp/updates/perform` per wave â€” `options: { "backup": true, "visual_regression": true }`, `override_lock: false`, `target_version` = the patched version for vulnerability-driven items, or the customer's named version.
3. After each task, inspect `details.sites[].steps`: `wp_test` failed or visual regression **>10%** â†’ restore the pre-update snapshot (`POST /sites/{id}/backups/{snapshot_id}/restore`), freeze the item fleet-wide, notify. **2â€“10%** â†’ hold the item everywhere + attach the diff screenshots. **â‰¤2%** â†’ pass.
4. **Stop-on-repeat:** the same item breaking twice â†’ out of all remaining waves, escalated.
5. Poll ~10 s cadence; respect the 200 req/min budget.

## Auto-update schedules â€” the always-on layer

Schedules run even when the agent isn't running. Set them up once, review their results in the briefing. Judgment cases (major jumps, business-critical components) are not schedule material.

**View â€” handled:** `GET /auto-update-schedules` (name, status, next run, scope, options). Run results: `GET /auto-update-history?filters[auto_update_schedule_id:eq]=<id>` (+ `performed_on` window, `status:in`) â€” present conversationally ("the nightly ran Tue 02:30 â€” 41 updates on 12 sites, 2 failed: reasons").

**Create / change â€” fully prepared, one go.** Body shape (defaults in parentheses):

```json
{ "auto_update_schedule": {
    "name": "Nightly â€” trusted plugins", "schedule": "weekly_on_day",
    "started_at": "<off-peak>", 
    "scope": { "sites": { "selection": "all" },
               "updates": { "wordpress_core": true, "plugins": { "selection": "all" } } },
    "options": { "backup": true, "visual_regression": true }
} }
```

Preparation rules: always `backup` + `visual_regression` on; off-peak `started_at`; **warn honestly** that `plugins.selection: "all"` also applies major jumps when they appear (no patch-only filter exists) â€” for risk-averse customers propose a curated filename allowlist instead, so major jumps keep flowing to Mode 2. Actions: create `POST /auto-update-schedules`; change/pause/resume `POST /auto-update-schedules/{id}/update|enable|disable`; delete `DELETE /auto-update-schedules/{id}` (Mode 2, coverage summarized first).

## Briefing (always end here)

> **Handled:** N updates across M sites â€” checks passed. Auto-rollbacks + why. Schedule runs (pass/fail counts, failures detailed).
> **Ready for your go (â‰¤5):** the prepared Mode 2 items, one line each, with recommendations.
> **FYI:** disconnected sites, exposures cleared, no-update-path vulnerabilities, major jumps excluded by the allowlist.
> Full log on request.


<!-- ===== SKILL: wpremote-visual-monitoring ===== -->

---
name: wpremote-visual-monitoring
description: Visual monitoring via WP Remote â€” enable visual monitoring on a site, refresh checks, and review visual monitoring data (change percentages, screenshots, probe history), correlating visual changes with what caused them. Use when the user asks to watch a site visually, whether a site looks broken or changed, or to review visual monitor data.
---

# Visual monitoring

Two different things â€” don't mix them: **update-time visual regression** runs inside update tasks (part of the `wpremote-updates` safety loop); **visual monitors** are continuous scheduled screenshot checks with a change threshold. This skill is the continuous kind.

## Enable / manage â€” Mode 1 for defaults

- **Default monitor (handled, logged):** `POST /monitoring/visual-monitors` with
  `{ "visual_monitor": { "site_id": "<id>", "url": "<site home URL>", "device": "desktop", "interval": 86400, "threshold": 10 } }`
  Reversible (disable/delete), no site mutation â†’ handled without asking. Defaults: daily interval, 10% threshold, desktop.
- **Custom sets (Mode 2, prepared):** multiple URLs (cart, checkout, landing pages), mobile device, tighter intervals or thresholds â€” arrive as one prepared list: "Ready: monitor 4 URLs on yoursite.com, daily, desktop+mobile, alert >5%. Go?"
- Enable/disable/refresh existing: `POST /monitoring/visual-monitors/{id}/enable|disable|refresh` â€” handled.

## Review â€” Mode 1, handled

- **Status:** `GET /monitoring/visual-monitors` (+ the site's monitoring state in `GET /sites/{site_id}`).
- **Probes:** `GET /monitoring/visual-monitors/{id}/probes` â†’ per run: timestamp, change %, status, baseline/comparison/diff screenshots.
- **Present conversationally:** "yoursite.com â€” last 7 daily probes â‰¤ 0.1% change. Tuesday 04:00 probe: 12.4% (screenshots attached) â€” correlates with the theme update that ran at 03:58 (activity log). Resolved itself by the next probe."
- **Correlate, don't just report:** any spike gets checked against the site's change timeline (activity logs, tasks, auto-update history) before presenting â€” the professional answers "what changed and why," not "something changed."

## In the briefing

Newly enabled/disabled monitors Â· probes that breached threshold (with screenshots and the likely cause) Â· monitors going stale because a site is disconnected (probes fail silently otherwise).



