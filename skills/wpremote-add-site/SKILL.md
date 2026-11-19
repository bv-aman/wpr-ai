---
name: wpremote-add-site
description: Connect a new WordPress site to WP Remote — five-step onboarding combining API v6 and WP-CLI (register the site, install+activate the BlogVault plugin, fetch the connection key, set it via WP-CLI, start the first sync/backup). Use when the user asks to add or connect a site to WP Remote.
---

# Add a site (API + WP-CLI) — Mode 2 end-to-end

Everything prepared, one "go", five verified steps, one report. Per the base skill's irreversibility floor this is always a prepared action — the customer authorizes, never analyzes.

## What the customer provides (one message, only what they alone know)

1. **The site URL.**
2. **How the agent can reach WP-CLI on that site** — one of:
   - an SSH alias or command (`ssh sg-shop`, path `/www/shopxyz/public`) — works when they already have key-based SSH set up; the agent uses their existing access, **never ask for SSH passwords in chat**
   - a local path for dev sites (`~/sites/dev-example`)
   - "no shell access" → **manual-mode fallback** below
3. *Only if applicable:* HTTP basic-auth credentials for the site (→ `connection.http_auth` in the API call, not logged), sticky-IP requirement, agency assignment ("add to client X, tag Production").

Everything else — registration, plugin, key handling, first sync — is the agent's job.

## Prerequisites (verify before proposing)

- **WP-CLI reachability:** verify with a benign call first (`wp --info`, `wp plugin list`) over the access the customer described.
- The site is a live WordPress install reachable at its URL.
- **Not already connected:** `GET /sites`, match by URL. If present → don't re-add; offer `POST /sites/{id}/sync` or key-reset recovery instead.

## Manual-mode fallback (no shell access)

Preferred: **plugin self-connect** — guide the customer to install "BlogVault real-time backup" from the Plugins page in wp-admin and use the plugin's built-in connect/sign-in to their existing WP Remote account (zero pastes, zero secrets; if the plugin supports a one-click account connect, prefer that over key paste).

Otherwise the agent performs steps 1, 3, and 5 over the API and hands the customer a two-paste card: (1) install "BlogVault real-time backup" from the plugin repo in wp-admin (or two ready-made commands for their host's terminal), (2) paste the connection key into the plugin's settings page. Customer effort: one message → two pastes; everything else stays automated.

**Never** automate via the customer's wp-admin credentials (platform-logging-into-wp-admin style) — no channel that requires the customer to hand over wp-admin passwords.

## Prepare, then one line

After the checks: *"Ready to connect https://X — register in WP Remote, install + activate the BlogVault plugin, set the connection key, run the first backup. Go?"* — wait for the word.

## Execute (after "go") — five steps, verify each

1. **Register:** `POST /sites` with `{ "site": { "url": "https://X" } }` — add `connection.http_auth` / `sticky_ip` only if the site sits behind basic auth or a sticky origin. **Save the returned `site_id`.**
2. **Plugin:** `wp plugin install blogvault-real-time-backup --activate` (already installed → `wp plugin activate blogvault-real-time-backup`). Verify with `wp plugin list`.
3. **Connection key:** `GET /sites/{site_id}/key` → `{ "key": "..." }`. **The key is a secret** — capture it into a shell variable; never print, echo, or log it; never leave it in shell history or files.
4. **Set the key (value referenced, never printed):**
   - bash: `KEY=$(...); wp blogvault setkey --key="$KEY"`
   - PowerShell: `$k = (...).key; wp blogvault setkey --key="$k"`
5. **First sync:** `POST /sites/{site_id}/sync` → `{ "sync": { "snapshot_id": "...", "in_progress": true } }` — track via `GET /sites/{id}/snapshots` until the first backup completes; report snapshot id + status.

## Failure handling

- Plugin step fails (repo unreachable, permissions) → report the exact WP-CLI error; the site stays registered; resume from step 2 after fixing.
- Sync fails → check the key was accepted and the plugin can reach the platform; report the snapshot/task error verbatim.
- **Never re-register to "start over"** — state exactly which steps completed and resume from the first failed one.

## After connection

Report: site_id, first snapshot id/status. Then hand off to the **`wpremote-onboard-site` skill** — the first-day assessment: site analysis + fleet conventions → a curated starter pack of prepared actions the customer approves in one word.
