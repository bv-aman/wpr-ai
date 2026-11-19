# WPR AI Project

**Value prop:** WP Remote customers manage their whole WordPress fleet from Claude Code / Codex — connected to WP Remote through the documented v6 REST API, guided by Skills — running automations instead of doing manual work in the dashboard.

## Definition of POC success

A customer who has (a) a WP Remote account and (b) Claude Code or Codex already installed:

1. pastes **one block** from us,
2. types **one sentence** (e.g. "audit all my sites and update everything safely"),
3. and a real flow runs on their real sites — audit first, backup before any change (API-native `backup: true`), report at the end — without them opening the WPR dashboard.

## The customer pack (four parts)

| Part | What it is | Home |
|---|---|---|
| Connection | Bearer-token API access baked into the skills (`WPR_API_KEY` env var; `curl` as the client — no server, no runtime deps) | `skills/` |
| Skills | `SKILL.md` playbooks: API conventions, safety rails, async task handling | `skills/` |
| Flows | Copy-paste prompts for the common jobs (the actual POCs) | `flows/` |
| Install | One-paste setup for Claude Code + Codex | `package/` |

## Decisions

- **2026-11-16 — Hosted MCP discovered live** (`mcp.blogvault.net/mcp`, verified, 268 tools): the platform provides the hands; our skills are the judgment layer. No need to build a local MCP server — the pack ships alongside the official MCP. Customer-facing Claude Desktop steps drafted (connectors UI + mcp-remote config fallback).
- **2026-11-12 — Autonomy model v2 (same-day Aman review):** pure two-mode OS, universal to every flow — Mode 1 "Handled" (autonomous, verified, logged) and Mode 2 "Ready, say go" (agent completes all preparation, customer spends one word). No probation. Old Lanes 3/4 dissolved: irreversible/costly actions = Mode 2 with mandatory prep (the floor); awareness = the briefing, not pings. Controls: irreversibility floor, change budget, never-list (`wpr-ai:hold` tags), always-on verification gates, audit trail. Full model: `docs/autonomy-model.md`.
- **2026-11-12 — Autonomy model v1 (superseded same day):** four lanes + supervised probation.
- **2026-11-11 — API:** build on the documented public OpenAPI v6 — `https://api.blogvault.net/api/v6`, Bearer token (`bvsk…`) the customer generates at **My Account > API Credentials**. Spec copy: `docs/openapi-v6.json`; working notes: `docs/api-notes.md`.
- **2026-11-11 — Architecture:** **Skills calling REST directly.** No MCP server, zero runtime dependencies; skills standardize on `curl` (present on macOS, Linux, Windows 10+); no `jq` dependency.
- **2026-11-11 — Validation:** **real test account.** API token delivered via User-scope env var `WPR_API_KEY` — never pasted in chat, never committed.

## Status

- [x] Project folder, charter, working rules
- [x] API source confirmed + endpoint inventory (`docs/api-notes.md`)
- [x] Architecture + validation decisions recorded
- [x] Core skill drafted — `skills/wpremote/SKILL.md` (auth, curl conventions, pagination, task polling, safety rails)
- [x] Flagship flow skill drafted — `skills/wpremote-update-sweep/SKILL.md` (audit → plan → confirm → execute → track → report)
- [x] Smoke-test script ready — `scripts/smoke-test.ps1` (runs the moment the token exists)
- [x] Flow list confirmed by Aman — 5 flows: 1) vulnerability-aware safe update sweep 2) "site is broken" triage via activity logs 3) firewall blocked-IP analysis 4) weekly health report 5) one-click login
- [x] Test account wired + live smoke test passed (auth OK, 6 sites, rate limit 200/min — see `docs/api-notes.md`)
- [x] Flow 1 data source verified live: `include_vulnerabilities=true` returns CVSS severity + virtual-patch status (plan-gated; works on the test account — 26 plugins, worst 9.8). Update Lens = optional enhancement, not a dependency
- [x] All five flow skills written: `wpremote-update-sweep` (vulnerability-aware), `wpremote-site-breakage-triage`, `wpremote-firewall-ip-analysis`, `wpremote-health-report`, `wpremote-quick-login` — plus `flows/README.md` copy-paste prompts
- [x] **All five flows validated end-to-end against the live test account** — evidence in `evidence/` (Flow 1 executed a real OxyBoron update: backup → 4 plugins + 1 theme → post-snapshot → visual regression 0.0% → wp_test, all green; Gravity Forms major-jump correctly held for sandbox/staging decision)
- [x] Four more professional-mode skills built (2026-11-16): `wpremote-update-plugins` (targeted: all/X-everywhere/X-on-N), `wpremote-auto-update-schedules` (view handled; create/change prepared-one-go), `wpremote-visual-monitoring` (enable + correlate-the-spike review), `wpremote-add-site` (API+WP-CLI five-step connect) — live-grounded (3 schedules exist on the account; 0 visual monitors)
- [x] Migration + restore skills built (2026-11-19): `wpremote-migrate` (internal HTTP / external FTP+SFTP+DB, no plugin at destination, rollback point + cutover plan) and `wpremote-restore` (HTTP / FTP for down sites, data-loss window stated, loss-reducers, point-in-time via real-time events) — both Mode 2 with connection pre-flight; schemas verified from spec (see `docs/api-notes.md`)
- [x] `wpremote-onboard-site` built (2026-11-19): first-day assessment — site analysis (health/updates/vulns/hack+redirections) + fleet conventions (monitoring %, tags, schedules, reports) → curated starter pack, one word applies; add-site hands off to it automatically. GA = dashboard-only (not in public API, flagged)
- [x] Pre-handover audit (2026-11-19): all 13 skill names match dirs; internal-language leaks fixed (test-site names, "platform feedback" wording); demo transcript moved to `docs/`; all skills pass the authoring standard's generalization test
- [x] Customer package started (2026-11-19): `package/SETUP.md` (token → skills install Claude Code/Codex → optional MCP → first prompts, both methods) and `package/codex-agents-wpremote.md` (skills merged for AGENTS.md, foundation first)
- [x] **Skill consolidation 13 → 10** (2026-11-19): `update-sweep` + `update-plugins` + `auto-update-schedules` merged into `wpremote-updates` (one update brain, one trigger space); `quick-login` folded into the base skill. Folder-per-skill format retained — it is the Claude Code skill format; flat `.md` files are not discoverable. Codex bundle regenerated (47.3 KB, 10 skills)
- [ ] Customer pack assembled; install snippet tested on a clean machine

## Working rules

See `CLAUDE.md` in this folder. Short version:

- No secrets in files, docs, or commits — env vars only.
- Customer-facing artifacts assume zero setup beyond Claude Code/Codex itself.
- Every mutating flow is audit-first, backup-first (API-native `backup: true` where supported), confirm-first.
- Every POC flow ships with three things: the skill, an example prompt, and run evidence.

## Layout

- `docs/` — internal notes + API contract (`openapi-v6.json`, `api-notes.md`)
- `skills/` — customer-facing skills; `scripts/` — internal tooling (smoke test)
- `flows/`, `package/`, `evidence/` — created as work lands
- `tmp/` — scratch, gitignored
