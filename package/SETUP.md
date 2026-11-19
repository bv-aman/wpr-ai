# WP Remote AI Site Professional — Setup Guide

Turn Claude Code or Codex into a site professional for your WordPress fleet: it handles routine work safely on its own (updates with automatic backups, change-verification, and rollback if anything breaks) and brings you fully-prepared decisions for the things that need you.

## What you're installing — 10 skills

| Category | Skills | What they do |
|---|---|---|
| **Foundation** | `wpremote` | Connection, conventions, safety rules, the operating system all skills share · one-click WP logins |
| **Updates** | `wpremote-updates` | Everything updates: fleet-wide vulnerability-aware sweeps, targeted updates ("update X everywhere / on these sites"), update audits, and native auto-update schedules |
| **Recovery** | `wpremote-restore` · `wpremote-migrate` · `wpremote-site-breakage-triage` | Full & surgical restores ("undo the plugins from my 2pm task") · migrations to another server or site · "why is my site broken" investigations |
| **Security** | `wpremote-firewall-ip-analysis` | Blocked-IP analysis with whitelist verdicts |
| **Monitoring & reporting** | `wpremote-health-report` · `wpremote-visual-monitoring` | Fleet health reports · visual change detection with cause-correlation |
| **Site lifecycle** | `wpremote-add-site` · `wpremote-onboard-site` | Connect new sites (API + WP-CLI) · first-day assessment & curated starter pack |

---

## Step 1 — Get your API token (once, ~1 minute)

1. Sign in to your WP Remote dashboard
2. Three-dot menu (top-right) → **My Account** → **API Credentials**
3. Under **API Token** → **Generate API Token** → copy it (shown only once; regenerating invalidates the old one)

Set it as an environment variable — **Windows (PowerShell):**
```powershell
[Environment]::SetEnvironmentVariable('WPR_API_KEY','PASTE_YOUR_TOKEN_HERE','User')
```
…then close and reopen your terminal. **macOS / Linux** — add to `~/.zshrc` or `~/.bashrc`:
```bash
export WPR_API_KEY="PASTE_YOUR_TOKEN_HERE"
```

## Step 2 — Install the skills

### If you use Claude Code

Copy every folder from this pack's `skills/` directory into your skills folder:

**macOS / Linux:**
```bash
mkdir -p ~/.claude/skills && cp -r skills/* ~/.claude/skills/
```
**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse -Force skills\* "$env:USERPROFILE\.claude\skills\"
```
(For a single project only, use `.claude/skills/` inside that project instead.)

**Verify:** start `claude` in any folder and ask: *"List my WP Remote skills."*

### If you use Codex

Codex reads `AGENTS.md`. This pack includes `codex-agents-wpremote.md` — all 13 skills pre-merged (foundation first):

1. Create or open `~/.codex/AGENTS.md` (global) or `AGENTS.md` in your project
2. Append the entire contents of `codex-agents-wpremote.md`

**Verify:** start `codex` and ask: *"Is the WP Remote setup connected and working?"*

## Step 3 (optional, recommended) — Connect the official WP Remote MCP

The MCP gives your AI first-class WP Remote tools — no command-line API calls needed. Same token as Step 1:

```bash
export WPREMOTE_MCP_TOKEN="PASTE_YOUR_TOKEN_HERE"   # same token as WPR_API_KEY
```

**Claude Code:**
```bash
claude mcp add --transport http --scope user \
  --header "Authorization: Bearer ${WPREMOTE_MCP_TOKEN}" \
  wpremote https://mcp.blogvault.net/mcp
```
**Codex:**
```bash
codex mcp add wpremote \
  --url https://mcp.blogvault.net/mcp \
  --bearer-token-env-var WPREMOTE_MCP_TOKEN
```
**Claude Desktop:** Settings → Connectors → Add custom connector → URL `https://mcp.blogvault.net/mcp` → API-key/Bearer auth → paste your token. (If your version has no custom-connector option, see the config-file fallback below.)

## Step 4 — Your first words

```
Give me my standup.
Take care of updates across my sites.
Show me every vulnerable plugin across my account.
My site <name> broke around <time> — figure out what changed.
Log me into <site>.
```

The full prompt list is in `flows/README.md`. From here on: routine work runs safely on its own and lands in your briefing; anything risky or irreversible arrives fully prepared for a one-word go.

---

## API method vs MCP — which do you need?

| | Skills only (API method) | Skills + MCP (recommended) |
|---|---|---|
| Setup | Steps 1–2 | Steps 1–3 |
| Dependencies | None (uses `curl`, preinstalled everywhere) | None extra — MCP is hosted by WP Remote |
| How it calls WP Remote | Direct REST calls via your token | First-class tools through the official MCP server |
| Recommendation | Works everywhere, zero setup beyond the token | Same skills, cleaner integration — 60 extra seconds |

Both use the same token and the same skills. With MCP connected, your AI prefers its tools; without it, the skills drive the API directly.

## Appendix — Claude Desktop config-file fallback (no connectors UI)

Fully quit Claude Desktop, then edit:
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "wpremote": {
      "command": "npx",
      "args": [
        "-y", "mcp-remote",
        "https://mcp.blogvault.net/mcp",
        "--header", "Authorization: Bearer ${WPREMOTE_MCP_TOKEN}"
      ],
      "env": { "WPREMOTE_MCP_TOKEN": "PASTE_YOUR_TOKEN_HERE" }
    }
  }
}
```
Save, start Claude Desktop, open any chat — the tools icon shows **wpremote**. (Requires Node.js for the `npx` bridge.)

## Security notes

- Your token grants full access to your WP Remote account — treat it like a password. It lives only in your environment variables / MCP config, never in chat or files.
- The skills never print or log your token, keys, or FTP/database credentials.
- Nothing destructive (restore, delete, credential changes, anything costing money) runs without your explicit one-word approval, and every update takes a backup first.
