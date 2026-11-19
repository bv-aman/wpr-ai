# WP Remote AI — your site professional

Turn Claude Code or Codex into a hired professional for your WordPress sites. It handles routine work safely on its own — updates with automatic backups, change-verification, and rollback if anything breaks — and brings you fully-prepared decisions for the things that need you. One word from you executes any of them.

You never review permission slips — you review outcomes. Nothing destructive (restore, delete, credential changes, anything costing money) runs without your explicit one-word approval, and every update is backed up first.

## Setup — 2 minutes

### Step 1 · Get your API token

WP Remote dashboard → three-dot menu (top right) → **My Account** → **API Credentials** → **Generate API Token**. Copy it (shown only once).

Set it as an environment variable:

**Windows (PowerShell):**
```powershell
[Environment]::SetEnvironmentVariable('WPR_API_KEY','PASTE_YOUR_TOKEN','User')
```
…then close and reopen your terminal.

**macOS / Linux:**
```bash
echo 'export WPR_API_KEY="PASTE_YOUR_TOKEN"' >> ~/.zshrc && source ~/.zshrc
```

### Step 2 · Install the skills

**Claude Code — macOS / Linux:**
```bash
git clone https://github.com/bv-aman/wpr-ai.git /tmp/wpr-ai \
  && mkdir -p ~/.claude/skills \
  && cp -r /tmp/wpr-ai/skills/* ~/.claude/skills/
```

**Claude Code — Windows (PowerShell):**
```powershell
git clone https://github.com/bv-aman/wpr-ai.git $env:TEMP\wpr-ai
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse -Force $env:TEMP\wpr-ai\skills\* "$env:USERPROFILE\.claude\skills\"
```

**Codex (any OS):** after cloning as above, append the bundled skills file to your AGENTS.md:

```bash
mkdir -p ~/.codex && cat /tmp/wpr-ai/codex-skills.md >> ~/.codex/AGENTS.md
```
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.codex" | Out-Null
Add-Content -Path "$env:USERPROFILE\.codex\AGENTS.md" -Value (Get-Content $env:TEMP\wpr-ai\codex-skills.md -Raw)
```

### Step 3 · (Optional, recommended) Connect the official WP Remote MCP

First-class WP Remote tools for your AI — 60 extra seconds, same token:

```bash
export WPREMOTE_MCP_TOKEN="PASTE_YOUR_TOKEN"    # same token as Step 1
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

**Claude Desktop:** Settings → Connectors → Add custom connector → URL `https://mcp.blogvault.net/mcp` → API-key/Bearer auth → paste your token.

### Done — verify

Open your AI tool and ask: **"Is the WP Remote setup connected and working?"**

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
| `Add <url> to WP Remote.` | Five-step connect (register → plugin → key → first backup), prepared as one go |
| `Log me into <site>.` | One-click WordPress login link |

## What's in this repo

- `skills/` — 10 skills (updates · restore · migrate · breakage triage · firewall IP analysis · health report · visual monitoring · add-site · onboarding · foundation)
- `codex-skills.md` — the same skills, pre-merged for Codex's AGENTS.md
- This README

## Safety, always on

- Backup before **and** after every update; visual change-check + automated health test; auto-rollback if a site breaks
- Fleet changes roll out in small verified waves — never everything at once
- Locked plugins/themes always respected; your token and credentials are never printed or logged
- With or without the MCP, the skills work — API directly, or first-class tools if MCP is connected

*Note: while this repo is private, `git clone` requires access. Once public, the same commands work for anyone, and a no-git download option can be added.*
