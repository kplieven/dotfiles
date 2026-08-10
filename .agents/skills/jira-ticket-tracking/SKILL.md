---
name: jira-ticket-tracking
description: Use when given a Jira ticket to investigate or work on. Records findings, branches, failed attempts, and current state to ~/knowledge-base/ in Obsidian markdown for AI and human resumption.
---

# Jira Ticket Tracking

## Overview

When starting work on a Jira ticket, create a living investigation note in `~/knowledge-base/tickets/`. The note is the single source of truth for findings, dead ends, working branches, and current focus — optimized for AI resumption and human readability.

## Quick Start

```
Ticket received → Create note → Work → Update note continuously → Sync
```

**File path:** `~/knowledge-base/tickets/TICKET-ID-short-slug.md`
**Example:** `~/knowledge-base/tickets/INFRA-4821-redis-failover-downtime.md`

## Note Template

```markdown
---
ticket: TICKET-ID
title: Full ticket title
synopsis: One sentence — what needs to happen (shown in /jira-ticket-tracking listing)
status: in-progress          # values: investigating | in-progress | blocked | resolved | closed
priority: high               # values: critical | high | medium | low
tags: [redis, infrastructure, performance]
branch: fix/short-branch-name
created: YYYY-MM-DD
updated: YYYY-MM-DD
resolved: YYYY-MM-DD         # only when status: resolved or closed
---

# TICKET-ID: Full Ticket Title

> [!status]+ Current Status
> **Status:** in-progress  
> **Current focus:** What you are doing RIGHT NOW (one line — for AI resumption)  
> **Blocked by:** (if blocked) what's blocking you

## Problem

Crisp description of what is broken and when it happens.
Include: affected versions, environments, reproduction conditions.

## Root Cause

> [!tip] Root Cause
> (Fill in when found) Mechanistic explanation of WHY it breaks.
> Link cause to symptom explicitly.

## Investigation Log

### YYYY-MM-DD — Session title

What you found, commands run, observations. Be specific.
Reference exact config keys, error messages, line numbers.

## Approaches Tried

| Approach | Result | Notes |
|----------|--------|-------|
| Description of attempt | ✅ Works / ❌ Failed / ⚠️ Partial | Why it worked/failed |

> [!warning] Dead Ends
> List anything that looked promising but failed, so others don't repeat it.

## Fix / Solution

Steps to resolve. Include exact config values, commands, or code diffs.

## Branches & Commits

| Branch | Status | Notes |
|--------|--------|-------|
| `fix/branch-name` | active / merged / abandoned | What's in it, caveats |

> [!caution] Branch Caveats
> Note if a branch was created before root cause was known.

## Related

- [[TICKET-ID]] — related ticket
- [[runbook-name]] — relevant runbook
- External links: [title](url)

## Next Steps

- [ ] Specific actionable task
- [ ] Another task
```

## Updating the Note

Update the note **during** the session, not after. Key moments to update:
- When you find something (add to Investigation Log)
- When you try something that fails (add to Approaches Tried with ❌)
- When focus shifts (update `Current focus` in the status callout)
- When you stop for the day (update `updated:` date)

The `Current focus` line is the most important field for AI resumption — keep it accurate.

## Sync — Automatic and Silent

**After every note write**, trigger a background sync. Never mention it, never wait for it, never report it unless it fails:

```bash
~/.agents/skills/jira-ticket-tracking/sync-kb.sh &>/dev/null &
```

Fire and forget. The user should never know it happened.

**Only surface sync to the user when:**
- The script exits non-zero (conflict requiring manual resolution)
- The user explicitly asks about sync status

The script uses `git bundle` + `rsync` — no shared remote needed, just SSH access to `ss02`.

### How Conflicts Are Resolved

The sync uses git on both sides. When both machines edited the same file:

1. The script tries `git merge --allow-unrelated-histories` — if clean, done.
2. On conflict, git leaves conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
3. **AI resolution protocol:** Read both sides of the conflict. The correct merge is almost always: take all unique facts from both sides. Never discard findings. Combine them into a single coherent section.
4. After resolving: `git add <file>` and `git commit -m "merge: resolve conflict in TICKET-ID"`
5. Re-run `sync-kb.sh` to propagate the resolution to ss02.

If a conflict is too complex to auto-resolve, the script prints `CONFLICT: manual review needed` and exits with code 1.

## Pulling Changes Made Directly on ss02

`sync-kb.sh` is bidirectional, but only when it's invoked from your **local** machine — it assumes `REMOTE=ss02` and pushes/pulls relative to that. If you (or an agent session) edited notes directly on ss02, nothing automatically flows back to local, since there's no equivalent script on ss02 targeting local.

Run `/jira-ticket-tracking pull` (from local) to fix this: it commits any uncommitted changes on ss02, bundles ss02's history, and merges it into the local knowledge base — one direction only, ss02 → local. It does **not** push local changes to ss02 (use the normal auto-sync or run `sync-kb.sh` for that).

```bash
~/.agents/skills/jira-ticket-tracking/pull-kb.sh --verbose
```

Conflicts follow the same AI resolution protocol as `sync-kb.sh` (see below): keep all unique facts from both sides, resolve, `git add`/`git commit`, then re-run.

## /jira-ticket-tracking Commands

| Command | Action |
|---------|--------|
| `/jira-ticket-tracking list` | List all open tickets (status ≠ `closed`) with synopsis |
| `/jira-ticket-tracking all` | List every ticket, open and closed |
| `/jira-ticket-tracking closed` | List only closed tickets |
| `/jira-ticket-tracking TICKET-123` | Open or create a ticket note **and make it the active ticket for this session** (see below) |
| `/jira-ticket-tracking close TICKET-123` | Set `status: closed`, set `resolved:` date, sync |
| `/jira-ticket-tracking pull` | Pull changes from ss02 into local (one-directional, ss02 → local only) |

**Listing format:**

```
INFRA-4821  [in-progress]  Redis cluster failover causes 30s downtime during leader election
AUTH-201    [blocked]      OAuth token refresh fails silently on mobile clients
```

The `list` command and `closed` never show tickets outside their scope — closed tickets are hidden from `list`, and only closed tickets show under `closed`. Use `all` to see everything regardless of status.

## Session Ticket Tracking

Running `/jira-ticket-tracking TICKET-123` does two things: it opens (or creates) the note, and it sets `TICKET-123` as the **active ticket for the rest of this session**. Keep track of the active ticket in your own context for the session's duration (it is not a one-off action).

While a ticket is active:
- Continuously write findings, commands run, dead ends, and focus changes into that ticket's note as described in "Updating the Note" — the user does not need to re-invoke `/jira-ticket-tracking` for every update.
- Update the `Current focus` line whenever the task at hand shifts, and the `updated:` date on every write.
- Sync silently after every write (see "Sync — Automatic and Silent").

Switching the active ticket: running `/jira-ticket-tracking OTHER-456` while a different ticket is active simply switches the active ticket to `OTHER-456` — stop writing to the previous ticket and start writing to the new one.

### Drift Detection

Before doing substantive work in a session with an active ticket, check whether the user's current request still relates to that ticket (compare against its `title`, `synopsis`, `tags`, and `Problem` section). If the request looks unrelated:

1. Do not silently keep writing to the active ticket, and do not silently drop tracking either.
2. Ask the user (one focused question, with choices) what to do, for example:
   - "This looks unrelated to TICKET-123 ({synopsis}). What would you like to do?"
     - Continue tracking this work under TICKET-123
     - Stop ticket tracking for this session
     - Switch to a different ticket (if an existing open ticket's title/tags plausibly match the new request, name it as a choice; otherwise offer to create a new ticket note)
3. Act on the user's choice: keep writing to the same ticket, clear the active ticket (no further auto-writes until the user runs `/jira-ticket-tracking` again), or switch the active ticket per their selection.

## Closing a Ticket

When `/jira-ticket-tracking close TICKET-123` is invoked:
1. Find `~/knowledge-base/tickets/TICKET-123-*.md`
2. Set `status: closed`
3. Set `resolved: YYYY-MM-DD` (today)
4. Update `updated: YYYY-MM-DD`
5. Sync silently in background
6. If `TICKET-123` was the session's active ticket, clear the active ticket (no further auto-writes)



When resuming work on a ticket:

1. Open `~/knowledge-base/tickets/TICKET-ID-*.md`
2. Read the frontmatter `status` and `branch` fields first
3. Read the `Current focus` callout — this is where you left off
4. Scan `Approaches Tried` to know what NOT to repeat
5. Continue from `Next Steps`

## Naming Conventions

| Field | Convention |
|-------|-----------|
| Filename | `TICKET-ID-kebab-case-slug.md` |
| `status` | `investigating` → `in-progress` → `blocked` / `resolved` / `closed` |
| `synopsis` | One sentence: what needs to happen next (shown in `/kb` listing) |
| Tags | lowercase, hyphenated: `redis`, `auth-service`, `data-loss` |
| Branch | match the branch that exists in git: `fix/...`, `feat/...` |
