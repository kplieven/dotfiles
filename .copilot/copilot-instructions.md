# Global Copilot Instructions

## Custom Commands

### /jira-ticket-tracking — Knowledge Base Ticket Tracking

When the input starts with `/jira-ticket-tracking`, invoke the `jira-ticket-tracking` skill immediately.

Examples:
- `/jira-ticket-tracking list` → list all open (non-closed) tickets with synopsis
- `/jira-ticket-tracking all` → list every ticket, open and closed
- `/jira-ticket-tracking closed` → list only closed tickets
- `/jira-ticket-tracking INFRA-4821` → open or create note for ticket INFRA-4821 and make it the **active ticket for this session** — all findings, investigation log entries, and progress from this point on are written into that note until the session's active ticket changes
- `/jira-ticket-tracking close INFRA-4821` → mark ticket closed, set resolved date, sync

While a ticket is active for the session, if the user's request seems unrelated to that ticket, the skill will flag the drift and ask whether to keep tracking the current ticket, stop tracking, or switch to a different ticket.

## Commit Preferences

- Only write commit titles, no bodies. Copilot `Co-authored-by` trailer is the only exception.
- Use the `feat`/`fix`/`chore`/`refactor`/`build`/`ci`/`docs`/... prefix for commit titles (`feat: add worker discovery`).
- Only work on local history; never push unless explicitly instructed to.
- When removing files from git history, keep their working-tree copies on disk as untracked files unless I explicitly ask to delete them.
- Never commit `docs/superpowers/`, specs, plans, handoff notes, or other agent-generated markdown unless explicitly asked.
- "Commit", "push", "amend", or "put it on a branch" means do exactly that: do not run tests, builds, or reviews first unless asked.

## Testing

**Run without asking:** any test that runs locally, finishes quickly (seconds to ~1 min) and doesn't noticeably load my PC. Just run it and state the command in your reply.

**Ask first:** builds and anything intensive or long-running (full builds, full suites on many cores, heavy RAM/GPU/disk use). Before starting a code change where such runs would be useful, ask me (with the `ask_user` tool) whether you should run them or I will. Never put this in one dense sentence. Use a scannable layout: one short line per field in the `message` (aligned label, then value), and a single choice field (You / Me) for the answer. Template:

```
Tests/builds for this change: who runs them?

Duration     ~2 min full suite · ~10 s targeted
Frequency    once at the end (or: after each of 4 steps)
PC load      all cores for ~2 min · ~2 GB RAM · no GPU
Full suite   <exact command from repo root>
Targeted     <exact command for single test/filter/package>

Run them:  ( ) You  ( ) Me
```

- **Duration:** estimate per run, based on suite size, build system and any previous run times you can find.
- **Frequency:** how often you expect to run them during this change.
- **PC load:** expected CPU cores, RAM, GPU and disk use.
- **Commands:** exact commands from the repo root, targeted variant next to the full suite.

Ask once per task and stick with my answer (it covers only the builds/intensive runs). Every time you would run tests, put the exact command in your reply. If I chose to run them myself, give the command instead of running it.

## Session Handoffs

- **Handoffs:** when I ask to checkpoint, stop, or continue in a fresh session, write `HANDOFF.md` at the root of the main checkout (not a worktree, not the session-state folder) and add it to `.git/info/exclude`. Include: branch/worktree, done, in progress, next step, and every decision or preference from the conversation that isn't in the repo. Do not commit WIP. When I say "continue" in a new session, read `HANDOFF.md` first.
