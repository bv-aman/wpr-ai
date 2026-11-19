# WPR AI Project — Agent Guide

This folder is a **product project**: the WP Remote AI automation pack (Skills + flows that let customers run WP Remote through Claude Code / Codex via the documented REST API).

The juniper support-ticket workflow (recipe routing, ticket checklist, BVAdmin/Loki investigation) does **not** apply inside this folder. Do not run the strict ticket checklist here.

## Architecture (decided 2026-11-11)

- Skills call the REST API directly — **no MCP server, no runtime dependencies**. The client is `curl` (present on macOS, Linux, Windows 10+). Do not require `jq`, Node, or Python in customer-facing skills.
- API contract: `docs/openapi-v6.json` (copy of https://docs.blogvault.net/api/v6/openapi.json). Base URL `https://api.blogvault.net/api/v6`. Verified behavior and quirks live in `docs/api-notes.md` — keep both current.

## Rules

1. **Secrets** live only in env vars (`WPR_API_KEY`). Never in tracked files, docs, example commands with real values, or commits. Our test-account key is read from the Windows User-scope env var `WPR_API_KEY`.
2. **Two audiences, kept separate**: `skills/`, `flows/`, `package/` are customer-facing — zero assumptions, no internal jargon, no internal URLs. `docs/` and `evidence/` are internal.
3. **Mutating operations** in any flow: audit/dry-run first, explicit user confirmation first, use the API-native `backup: true` option where supported, respect locks (`override_lock: false` default).
4. **Async tasks**: mutating POSTs return tasks; poll `GET /tasks/{task_id}` until terminal state. Skills must encode this.
5. `docs/api-notes.md` is the single source of truth for verified API behavior. Update it whenever anything is confirmed or changed.
6. Scratch work goes to `tmp/` (gitignored). Nothing in `tmp/` is a deliverable.
7. **Skills are written to the standard in `docs/skill-authoring.md`:** decision procedure first, examples labeled as calibration, explicit unknown-fallback (base skill's generalization rule), standing cautions as conditions. A skill must pass the generalization test — correct behavior for a request it never mentions — before it ships.
7. Reference codebase for platform behavior: `../data/repositories/blogvault/` (WP Remote runs on the same Rails platform). Cite `file:line` when using it.
