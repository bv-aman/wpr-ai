# Skill Authoring Standard

**The bar:** a skill must produce correct behavior for a request it never mentions. Skills teach judgment — a lookup table of scenarios fails the first novel request.

## Required anatomy (every skill, in this order)

1. **Role + OS inheritance** — one line placing it inside the two-mode operating system from the `wpremote` base skill (Mode 1 handled / Mode 2 ready-say-go).
2. **Decision procedure first** — the reasoning as rules, axes, or numbered steps that *generate* correct behavior. Written before any example appears. For restore: the 5-step resolution procedure. For updates: the classification axes (reversibility, jump size, history, criticality, budget).
3. **Worked examples second, labeled as calibration** — a table or list that demonstrates the procedure on concrete requests, explicitly framed as "calibration, not an exhaustive list." Never let examples read as the boundary of the skill.
4. **Explicit unknown-fallback** — what to do when nothing matches. The base skill's generalization rule covers this for all skills: intended outcome → minimal API-supported path → classify (unknown ⇒ Mode 2) → smallest scope + state what's not covered → report. Repeat a one-line version inside skills whose domain has special resolution logic (restore, migrate, triage).
5. **Standing cautions as conditions, not cases** — "whenever X is true, do Y" (DB-migration caveat, wp-config trap, credentials-never-echoed), so they fire on unlisted situations too.
6. **Invariants** (non-negotiable, inherited + restated where domain-specific): secrets only in request bodies, never printed; never guess IDs/paths/table names — validate against authoritative sources; never silently change parameters between attempts; the customer authorizes, never analyzes.

## The generalization test (before shipping any skill)

Ask: *"Would this skill behave correctly for a request it never mentions?"* — e.g. for restore: "roll my footer widget back" (→ find the edit in activity logs → widget lives in options/table → nearest scope + honesty about granularity). If the answer depends on an example being listed, the procedure section is too weak.

## Writing rules

- Principles before examples, always.
- Name the authoritative source for every fact (task manifests, file/table catalogs, activity logs) — the agent verifies instead of guessing.
- Prefer "choose for the customer, state why" over "ask the customer" for anything the agent can decide from data (method selection, snapshot choice).
- The one-line proposal format states: exact scope, what it touches, what it doesn't, cautions, go?
- No internal jargon, no internal URLs, no roadmap speculation in customer-facing skill text.
- Failure sections teach recovery logic ("resume from first failed step", "never re-register"), not just "report the error."
