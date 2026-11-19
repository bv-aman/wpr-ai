---
name: wpremote-add-site
description: Connect a new WordPress site to WP Remote — registers the site, hands the customer a short two-step connect card (install the BlogVault plugin from the WordPress plugin directory, paste the connection key), then starts the first sync/backup. Fully prepared for one-word approval. Use when the user asks to add or connect a site to WP Remote.
---

# Add a site — always Mode 2

Everything prepared, one "go", verified steps, one report. The customer authorizes; they never analyze.

## The customer provides (one message)

1. **The site URL.**
2. *Only if applicable:* HTTP basic-auth credentials if the site is behind a login page (used for verification; never echoed), and which client/tags to assign (agency accounts).

## Prepare (before the go)

1. **Not already connected:** `list_sites` → match by URL. Already present → don't re-add; offer a sync or key-reset instead.
2. **Site is live WordPress:** the URL resolves and serves WordPress.
3. One line: *"Ready to connect https://X — register it, you install the plugin and paste a key (2 minutes, I'll walk you through it), then the first backup starts. Go?"*

## Execute (after "go") — three agent steps around one customer step

1. **Register:** create the site via the WP Remote tools (`{ "site": { "url": "https://X" } }`, plus `http_auth` if the site sits behind basic auth). **Save the returned `site_id`.**
2. **Connect card for the customer** (they do this in their WordPress admin, no technical setup):
   - In wp-admin → Plugins → Add New → search **"BlogVault real-time backup"** → Install → Activate (or use their host's one-click plugin installer)
   - Retrieve the site's **connection key** via the WP Remote tools and give it to the customer to paste into the plugin's settings page
   - The key is a secret: deliver it directly, tell the customer to treat it like a password; never store it anywhere
3. **First sync:** start the site sync via the WP Remote tools → track snapshots until the first backup completes; report snapshot id + status.

## Failure handling

- Customer can't find/activate the plugin → link the plugin's wordpress.org page and their host's one-click options; the registration stays valid, resume when done.
- Sync fails → check whether the key was accepted (site connection status) and whether the plugin can reach WP Remote; report the error verbatim.
- **Never re-register to "start over"** — state which steps completed and resume from the first failed one.

## After connection

Report: site id, first snapshot id/status. Then hand off to the **`wpremote-onboard-site` skill** — the first-day assessment and curated starter pack.

**Never** automate via the customer's wp-admin credentials (logging into their wp-admin to install things) — no channel that requires the customer to hand over wp-admin passwords.
