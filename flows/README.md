# Copy-paste flows

Paste any of these into your AI tool (Claude Code, Codex) once the WP Remote skills are installed. Your AI professional handles routine work on its own (backups and change-verification always on) and brings you only decisions that actually need you.

| # | Paste this | What happens |
|---|---|---|
| 1 | `Take care of updates across my sites.` | Your professional sweeps everything: safe updates applied and verified automatically (backup → update → change-check → health test, auto-rollback if broken), risky ones staged and verified first, then one decision each. You get a briefing, not a table. |
| 1b | `Give me my standup.` | The briefing: what I handled, what needs you, what happened — on demand. |
| 2 | `My site <name-or-URL> broke around <time>. Figure out what changed.` | Breakage triage: full change timeline from activity logs, updates, restores, cleanups — ranked likely cause + recommended fix (read-only) |
| 3 | `The IP <ip> was blocked on <site / all sites>. Analyze it and tell me if I should whitelist.` | Firewall IP analysis: every hit, rules, patterns, login attempts → verdict (whitelist action only on your confirmation) |
| 4 | `Give me this week's health report.` | Fleet health report: uptime, updates, vulnerabilities, malware, backups, SSL expiry, attention list |
| 5 | `Log me into <site>.` | One-click SSO login URL |
| 6 | `Update all plugins across my sites.` · `Update <plugin> everywhere.` · `Update <plugin> on <site1>, <site2>.` | Targeted updates with the full safety loop — only surprises the instruction didn't cover (major jumps, locks) come back for one word |
| 7 | `Set up auto-updates.` · `Show my auto-update schedules.` · `What did the nightly schedule do last night?` | Viewing schedules and run results: handled. Creating/changing a schedule: fully prepared, one go |
| 8 | `Enable visual monitoring on <site>.` · `Has <site> changed visually?` | Daily screenshot checks with change thresholds; spikes correlated to what caused them |
| 9 | `Add <url> to WP Remote.` | Five-step connect (register → plugin → key → first backup), prepared as one go; resumes cleanly on failure |
| 10 | `Restore <site> to <time / yesterday's backup>.` · `Restore the plugins from my 2pm update task.` · `Undo what that import did to my posts.` | Full **or selective** restores: resolves the task → components → pre-change snapshot → scoped paths/tables; data-loss window stated, HTTP vs FTP chosen for you — one go |
| 11 | `Migrate <site> to <new server / site B>.` | Internal (account site, HTTP) or external (server + DB credentials, no plugin needed at destination) — rollback point recorded, cutover plan included, one go |
| 12 | `I just added <site> — what should we do?` (also runs automatically after add-site) | First-day assessment: health score, updates, vulnerabilities, hack/redirection check + your fleet's conventions → a curated starter pack of prepared actions, one word applies it |

## Conventions (how your professional works)

- Routine, reversible work (patch updates inside the safety loop) runs **autonomously** and lands in your briefing — you review outcomes, not permission slips.
- Every update is protected: platform backup before and after, visual-regression change check, automated health test — **auto-rollback if the site breaks**.
- Locked plugins/themes/core are always respected; overrides only if you explicitly ask.
- You are always asked first for: major version jumps on important plugins, anything destructive (restore/delete), credential changes, anything that costs money, and anything the professional hasn't seen before.
- Big fleets update in small verified waves — never everything at once.
