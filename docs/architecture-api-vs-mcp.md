# API (Skills + REST) vs MCP — comparison and recommendation

Internal note, 2026-11-11. Question: "Is MCP better since the customer just talks to the AI?"

## The frame

- **MCP gives the AI hands**: we ship a server exposing typed tools (`list_sites`, `perform_updates`). Auth, retries, task-polling live in the server; the AI can't fumble the plumbing.
- **Skills give the AI judgment**: a `SKILL.md` playbook (audit first → confirm → `backup: true` → perform → poll tasks → report). With skills-only, the AI improvises its hands via `curl` following the manual.

Customer experience is **"talk to the AI, AI does everything" in both designs.** The customer never writes a command either way. We ship the judgment layer (skills) in both worlds; the open question is only where the hands come from.

## Comparison

| | Skills + REST | MCP server (local, npx) | MCP (hosted/remote) |
|---|---|---|---|
| What we build | Markdown skills only | Node server (write/test/maintain/distribute) | Server + hosting + OAuth at our edge |
| Customer install | Paste skills + `WPR_API_KEY` env var | Paste MCP config + env var; **requires Node on their machine** | Paste URL + OAuth login — zero local deps |
| Call reliability | Freeform curl; Windows/PowerShell JSON quoting is error-prone; pagination + task-polling loops executed by the AI per instructions | Typed tool schemas; mis-call nearly impossible | Same, fully server-controlled |
| Client coverage | Claude Code (native skills); Codex via AGENTS.md only (unstructured) | Any MCP client (Claude Code, Codex, Cursor, Claude Desktop) | Same |
| Model dependence | Higher — weaker models fumble freeform curl | Lower — tools work the same for any model | Lowest |
| Iteration speed | Edit markdown | Rebuild/republish | Deploy |
| Time to first POC | Days | Days–weeks | Weeks+ (platform work) |
| Telemetry | None | None (runs on customer machine) | Full (our edge) |

## Recommendation: staged

1. **POC: skills + REST.** Fastest proof, zero distribution risk, and it forces us to solve the real problems first: endpoint selection, call ordering, safety rails, report formats.
2. **Productize: wrap proven flows into `npx wpr-mcp`.** Every validated flow's curl sequence maps 1:1 to one typed tool; the skills become the server's behavioral spec. Nothing is discarded. Skills remain as the thin policy layer that orchestrates the tools.
3. **Endgame: hosted remote MCP** with OAuth — zero local install, works in claude.ai connectors/Claude Desktop, and gives usage telemetry. Requires platform engineering + hosting; a product decision, not a POC one.

> **UPDATE 2026-11-16 — the endgame arrived early:** a hosted WP Remote MCP is live at `https://mcp.blogvault.net/mcp` (verified with a real token; 268 tools, full API surface, Bearer auth). Stage 2 ("we build a local server") is no longer needed — the platform provides the hands officially. Our skills are the judgment layer on top of those hands; the two tiers ship together.

Ship both tiers if distribution constraints matter: MCP for customers who have Node / want the premium path, skills-only as the zero-dependency fallback.

## What carries over from stage 1 to stage 2 (why nothing is wasted)

- Each flow's endpoint sequence and guardrails (defined in the skill) = the implementation of one MCP tool.
- The env-var auth convention (`WPR_API_KEY`) carries over unchanged.
- Verified API behavior in `docs/api-notes.md` is the contract either way.
- POC evidence transcripts become the acceptance tests for the MCP server's tools.
