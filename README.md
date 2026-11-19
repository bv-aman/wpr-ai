# WP Remote AI — your site professional

Turn Claude or Codex into a hired professional for your WordPress sites. It handles routine work safely on its own — updates with automatic backups, change-verification, and rollback if anything breaks — and brings you fully-prepared decisions for the things that need you. One word from you executes any of them.

You never review permission slips — you review outcomes. Nothing destructive (restore, delete, credential changes, anything costing money) runs without your explicit one-word approval, and every update is backed up first.

## Setup — 2 minutes, no terminal

### Step 1 · Get your API token

WP Remote dashboard → three-dot menu (top right) → **My Account** → **API Credentials** → **Generate API Token**. Copy it — it's shown only once.

### Step 2 · Connect WP Remote (the hands)

**Claude (claude.ai or the desktop app):**
Settings → **Connectors** → Add custom connector → name it **WP Remote**, URL `https://mcp.blogvault.net/mcp`, authentication **API key / Bearer** → paste your token → Connect.

**Codex (web or desktop):**
Settings → **Connectors** → Add connector / MCP server → same URL → Bearer token → paste your token.

### Step 3 · Add the professional brain (the skills)

**Claude:** Settings → **Capabilities** → **Skills** → upload **`wpr-skills.zip`** from this repo → enable the WP Remote skills. (If your plan doesn't offer Skills upload, the connector alone already gives full site control — the skills add the professional judgment.)

**Codex web:** paste the contents of **`codex-instructions.md`** into Settings → custom instructions.

**Codex desktop / IDE:** copy **`codex-skills.md`** into your project as `AGENTS.md`.

### Done — ask your AI

> **"Is the WP Remote setup connected and working?"**

## What to say

| You say | What your professional does |
|---|---|
| `Give me my standup.` | The briefing: what I handled, what needs you, what happened |
| `Take care of updates across my sites.` | Vulnerability-aware sweep: safe updates run with backup + change-check + health test, risky ones arrive verified and ready |
| `Update WooCommerce everywhere.` / `...on site A and B.` | Targeted updates — only surprises (major jumps, locks) come back for a word |
| `Show me every vulnerable plugin across my account.` | Severity + virtual-patch status, worst first, with the fix plan |
| `My site <name> broke around <time>. Figure out what changed.` | Full change timeline, ranked likely cause, recommended fix |
| `Restore <site> to <time>.` / `Restore the plugins from my 2pm update task.` | Snapshot pre-picked, data-loss window stated, HTTP or FTP chosen for you — one go |
| `Migrate <site> to <new server / site B>.` | Internal or external migration, rollback point recorded, cutover plan included |
| `The IP <ip> was blocked on <site>. Should I whitelist it?` | Full traffic analysis → evidence-backed verdict |
| `Give me this week's health report.` | Uptime, updates, vulnerabilities, malware, backups, SSL — ranked attention list |
| `Enable visual monitoring on <site>.` | Daily screenshot checks; changes correlated to what caused them |
| `Add <url> to WP Remote.` | Register + a 2-minute connect card (plugin + key) + first backup |
| `Log me into <site>.` | One-click WordPress login link |

## What's in this repo

- `wpr-skills.zip` — the 10 skills, ready to upload to Claude
- `codex-instructions.md` — condensed version to paste into Codex web
- `codex-skills.md` — full version for Codex desktop/IDE projects (`AGENTS.md`)
- `skills/` — the individual skills (same content as the zip)

## Safety, always on

- Backup before **and** after every update; visual change-check + automated health test; auto-rollback if a site breaks
- Fleet changes roll out in small verified waves — never everything at once
- Locked plugins/themes always respected; your token and credentials are never printed or logged
- Works through the official WP Remote MCP — your token stays in your connector settings
