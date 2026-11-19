# WPR AI — the site professional for WP Remote customers

Turn Claude Code or Codex into a hired professional for your WordPress fleet: it handles routine work safely on its own — updates with automatic backups, change-verification, and auto-rollback if anything breaks — and brings you fully-prepared decisions for the things that genuinely need you. One word from you executes any of them.

**POC-proven against a live account** (see `evidence/`): a real fleet update ran with `backup → update → visual regression (0.0% change) → health test`, and vulnerabilities were verified cleared afterward.

## How it works — two modes, every flow

- **"Handled."** — routine, reversible work runs autonomously inside the verification loop and lands in your weekly briefing. You review outcomes, not permission slips.
- **"Ready — go?"** — risky, irreversible, or costly work arrives with all the preparation done (staging tests, consequence mapping, rollback points). You spend one word, never analysis.

Controls that never turn off: backup-first on every mutation · visual-regression + health-test verification · auto-rollback · canary waves for fleets (never everything at once) · stop-on-repeat · locks respected · credentials never printed · nothing destructive without explicit approval.

## What's inside

| Path | Contents |
|---|---|
| `skills/` | 10 skills: `wpremote` (foundation + quick logins) · `wpremote-updates` (sweeps, targeted updates, schedules) · `wpremote-restore` · `wpremote-migrate` · `wpremote-site-breakage-triage` · `wpremote-firewall-ip-analysis` · `wpremote-health-report` · `wpremote-visual-monitoring` · `wpremote-add-site` · `wpremote-onboard-site` |
| `package/` | `SETUP.md` — customer setup (token → skills → optional MCP, Claude Code + Codex + Claude Desktop) · `codex-agents-wpremote.md` — pre-merged bundle for Codex |
| `flows/` | The copy-paste prompts customers actually type (12 flows) |
| `docs/` | Internal: API working notes, autonomy model, architecture, skill-authoring standard, project status |
| `evidence/` | Live POC run artifacts |
| `scripts/` | Internal tooling (smoke test) |

## Quick start

1. Get your API token: WP Remote dashboard → My Account → API Credentials → Generate API Token
2. Follow **`package/SETUP.md`** — install the skills (Claude Code or Codex), optionally connect the official WP Remote MCP (`https://mcp.blogvault.net/mcp`)
3. Say: *"Give me my standup."*

## Skills are API-first, MCP-friendly

The skills drive the documented WP Remote API v6 directly (zero dependencies). With the official WP Remote MCP connected, the agent prefers its first-class tools — same token, same skills, both paths in SETUP.md.
