---
name: wpremote-restore
description: Backup restore via WP Remote — full or selective, over HTTP or FTP/SFTP/FTPS. Resolves any restore request — "restore the plugins from my 2pm task", "undo the WooCommerce update", "bring back the uploads folder", "put the site back to last Tuesday" — into the minimal correct scope against the right snapshot, fully prepared for one-word approval. Use when the user asks to restore, roll back, undo an update/change, or recover anything from a backup.
---

# Backup restore — always Mode 2

Restore overwrites whatever it touches: irreversibility floor, **always** a prepared action. The customer authorizes; they never analyze.

## The resolution procedure (this is the skill — it handles requests this file never mentions)

Every restore request, known or novel, resolves through these five steps:

1. **Translate the words into an intended outcome.** What changed, what's broken, what should become true again. ("Restore the plugins from my 2pm task" → *the code of exactly those plugins, as it was before that task.*)
2. **Find the change source** — the event that made "now" wrong: an update task (`GET /tasks` — its `input` is a manifest of exactly what changed), an auto-update run, a malware cleanup, an import, a deletion, an edit. Sources: task manifests, `auto-update-history`, cleanup reports, activity logs. No source found → fall back to the customer's time reference.
3. **Resolve to the minimal scope that fully covers the intent** — component → `paths`/`tables` via the live catalogs (below). Smaller is safer, but never so small it half-fixes; when torn between two scopes, propose the smaller one **and state what it does not cover**.
4. **Pick the snapshot**: latest *succeeded* before the change (or the named point in time). State id + timestamp.
5. **Package the one line**: loss statement scoped to what's touched, loss-reducers where they apply, method chosen by site state, cautions where they apply. One word executes it.

## Resolution mechanics (never guess)

- **Task-driven chains:** `GET /tasks?filters[type:eq]=wp_site_update` (+ window) → `input.sites[].plugins[].filename` / `.themes[].filename` = exactly what was updated; `details.sites[].steps` gives the `pre_snapshot` timing and flags `update_plugin_db` (DB caveat below). Auto-updates resolve via `GET /auto-update-history` → its task.
- **Component → scope:** plugin `filename: "woocommerce/woocommerce.php"` → `./wp-content/plugins/woocommerce/`; theme → `./wp-content/themes/<stylesheet>/`; core → `./wp-admin/` + `./wp-includes/` (+ root core files). Tables → **real names from the site's catalog**.
- **Catalog validation (authoritative):** `GET /sites/{id}/files` → `{ files: [{ path, type, status }] }`; `GET /sites/{id}/tables` → `{ tables: [{ name, rows, status }] }`. Every path/table in the scope must exist there; correct mismatches before proposing.
- **Loss-reducers:** `retain_latest_posts`, `retain_latest_woocommerce_orders` (site has `woocommerce: true`), `real_time_events: { enabled: true, until: <ts> }` for point-in-time (real-time backups required).
- **Method:** HTTP (omit `connection`) when the site is connected; FTP/SFTP/FTPS (`connection.method: "ftp"` + server creds + **required** database creds) when it's down/disconnected or the customer wants direct server write; `http_auth` when behind basic auth. Pre-flight: TCP reachability + format + catalog checks — the task's first steps are the real credential test (fail-fast before writes).

## Standing cautions (apply whenever their condition is true, listed or not)

- **DB-migration caveat:** rolling back a plugin files-only when its update ran `update_plugin_db` leaves newer schema under older code. State it; offer files-only / +tables (loss warning) / full restore / staging test.
- **Old-snapshot caution:** full-files restore brings back that era's `wp-config.php` — flag if hosting/DB credentials changed since.
- **Granularity honesty:** DB restores are per-table, not per-row/per-page. When the customer asks for finer granularity than the API has, say so and propose the nearest scope plus loss-reducers.
- **Inclusion-only:** scope has no excludes. If the intent needs "everything except X", say it's not expressible; propose the nearest alternative (targeted restores of what matters, or full restore — noting current uploads etc. remain in a snapshot either way).

## Worked examples (calibration for the procedure — not an exhaustive list)

| Request | Resolution |
|---|---|
| "Restore the plugins from my 2pm task" | task manifest → plugin dirs → pre-update snapshot → files-only |
| "Undo the update" (whole run) | every component the task touched; core → core paths |
| "Undo the WooCommerce update" (no task named) | find its `update_plugin` step → snapshot before it |
| "Restore the theme but keep my settings" | theme dir only — settings live in DB, untouched |
| "Restore the database only" | `include_database: true`, no files |
| "Undo what the import did to my posts" | posts + postmeta tables + `retain_latest_posts` |
| "Bring back the deleted uploads folder" | paths restore of that folder |
| "Put the site back to last Tuesday" | pre-Tuesday snapshot + `real_time_events.until` Tuesday EOD |
| "Undo the malware cleanup" | cleanup report's file list → pre-cleanup snapshot |
| "Restore subsite X" (multisite) | `subsite_ids` |

## The one line (shape, for any scope)

> "Ready: restore **<exact scope>** on <site> from snapshot `<id>` (<timestamp> — <why this one>). Touches: <what>. Doesn't touch: <what>. <Cautions if any>. Go?"

## Execute and track

- Run the restore tool for that snapshot with arguments `{ restore: { scope, connection?, options } }`. Credentials pass directly as tool arguments — never echo them in replies.
- Poll `GET /tasks/{id}` — progress on request. Verify `GET /sites/{id}` after. Offer a visual check (visual-monitoring skill refresh) for anything user-visible.

## Failure handling

- Report the failing **step** and error verbatim.
- Retry the same snapshot + scope is safe; **never silently change snapshot or scope** — re-confirm.
- Credentials never echoed in chat, logs, or the briefing.

## Notes

- "Push staging to production" belongs to the migrate/staging skills, not this one.
- Not available today: exclude lists in scope (`exclude_paths`) and a dry-run credential-test endpoint.
