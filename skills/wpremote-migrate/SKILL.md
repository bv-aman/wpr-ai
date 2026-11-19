---
name: wpremote-migrate
description: Website migration via WP Remote — move a site to another server (external, pushed over FTP/SFTP/FTPS + direct database import, no plugin needed on the destination) or onto another site already in the account (internal, over HTTP). Always fully prepared — destination verified, rollback point recorded, cutover plan stated — for one-word approval. Use when the user asks to migrate, move, or clone a site to a new host/server or another site.
---

# Website migration — always Mode 2

Migration overwrites the **destination**. Always a prepared action; the customer authorizes, never analyzes.

## Choosing the way (the procedure, not a table)

The type is decided by **where the destination lives** — a site on this account ⇒ internal; any other server ⇒ external. Everything else follows the same preparation procedure below. Requests that are really "copy for testing" belong to the staging skill; "selective component copy" belongs to the restore skill (paths scope) — recognize the intent and route there.

Reference for the two ways:

| | **Internal** (`type: "internal"`) | **External** (`type: "external"`) |
|---|---|---|
| Destination | a site already added on this account | any server, anywhere |
| Transport | `connection.method: "http"` (only) | `connection.method: "ftp"` + FTP/SFTP/FTPS server credentials + **database credentials (required)** |
| Destination needs plugin? | yes — must be `connected` | **no** — files pushed via FTP, DB imported directly |
| Typical use | copy/rebuild between your own sites, push to a staging-linked site | host migration, moving servers |

For "spin up a copy to test on" — that's the staging skill (`POST /staging-sites`), not a migration. Use this skill when the destination is a real site.

## 1. Gather inputs

- Source site (name/URL → id) and snapshot to migrate from (default: latest succeeded; point-in-time via `options.real_time_events: { enabled: true, until: <ts> }` when near-zero-loss cutover matters).
- Destination: internal → which account site; external → destination URL + server credentials (`protocol: ftp|sftp|ftps, host, username, password | private_key, path, port`) + database credentials (`host, username, password, name`), optional `http_auth` if the destination web server is protected.
- Scope: default full (`include_files: true, include_database: true`); `paths`/`tables` for partial.

## 2. Prepare (before the go)

1. **Source:** snapshot exists, status `succeeded`; state its timestamp.
2. **Destination — internal:** resolve via `GET /sites` URL match; must be `connected`; **record its latest snapshot id as the rollback point** (that's how you undo this migration); state plainly that the destination will be overwritten.
3. **Destination — external:** TCP pre-flight to host:port from the customer's machine; credential format checks (SFTP: password or private key, not both required); remind that destination DB will be imported into directly.
4. **Options to propose:**
   - `retain_latest_posts` / `retain_latest_woocommerce_orders` — keep newer content at the destination (merge-style migration)
   - `preserve_permissions: true`
   - `options.server: { ip, name_server }` — destination server metadata (helps routing during cutover)
   - `real_time_events.until` — capture source changes past the snapshot up to a cutoff (near-zero-downtime cutover)

## 3. The one line

> "Ready: migrate yoursite.com (snapshot Nov 11 11:09 UTC) → https://new.example.com over SFTP + DB import. Destination will be overwritten. Rollback: destination snapshot `6af45…` recorded. DNS cutover stays yours. Go?"

## 4. Execute and track

- `POST /sites/{site_id}/backups/{snapshot_id}/migrate` — body via temp file (contains credentials: never print, delete after). Envelope `{ migration: { destination_url, type, scope, connection?, options } }`.
- Poll `GET /tasks/{id}`; migrations are long — progress on request.
- **Post-migration:**
  - internal → verify destination (`GET /sites/{dest_id}` sync status), report.
  - external → the platform cannot flip DNS: remind the customer of the cutover step; once DNS points at the new server, offer the **add-site skill** to register the new site in WP Remote so protection continues.

## 5. Failure handling

- Report the failing step + error verbatim (connection refused / auth failed / DB import error / disk full).
- Safe to re-run the same migration (idempotent re-push); never silently change destination or snapshot on retry — re-confirm.
- Credentials never echoed in chat, logs, or the briefing.

## Connection testing (same reality as restore)

No dry-run test endpoint exists today. Pre-flight = TCP reachability + format checks + account-side state; the task's first steps are the real credential test and **fail fast before destination writes begin**.
