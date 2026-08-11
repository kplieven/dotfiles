---
name: jira-ticket-tracking
description: Use when the user explicitly invokes /jira-ticket-tracking, when Jira ticket tracking is already active for the session, or when a bare Jira ticket identifier appears and the user should be offered ticket tracking.
---

# Jira Ticket Tracking

## Overview

Each Jira ticket gets one durable note at `~/knowledge-base/tickets/TICKET-ID-slug.md`. The note is the persistent record of investigation, findings, and resolution. Active-ticket state is session-local — it lives only in conversation context and is never persisted to disk.

**Tracking activates only on explicit invocation — see [Activation](#activation).**

## Activation

Ticket tracking is **explicit only**. There are exactly two ways it starts:

1. The user runs `/jira-ticket-tracking TICKET-ID`.
2. The user answers "yes" to an offer to start tracking (this counts as explicit consent and is equivalent to running the command).

### A bare ticket identifier does NOT activate tracking

When the user merely mentions a ticket identifier (for example writes `INFRA-4821`, "look at INFRA-4821", or pastes a ticket URL) without the `/jira-ticket-tracking` command:

- **Do not** create a note.
- **Do not** open or write to an existing note.
- **Do not** set an active ticket.
- **Do not** run sync.
- **Do not** call `knowledge_tracking_state`.

Instead:

1. Answer the user's actual question normally.
2. Offer tracking once, in one line, naming the exact command:
   > "Want me to track INFRA-4821 in the knowledge base? Run `/jira-ticket-tracking INFRA-4821` (or say yes)."
3. If an existing note for the identifier is already known from earlier in the session, you may mention that it exists. Do not glob, read, or modify the knowledge base just to answer a bare mention.
4. If the user declines or ignores the offer, do not repeat it for that ticket in this session and do not write anything.

Everything below this section — note lookup, note creation, frontmatter, writes, sync, UI state — applies **only after** explicit activation.

## Note Lookup and Creation

After explicit activation, when opening or creating a note for `TICKET-ID`:

1. Search `~/knowledge-base/tickets/TICKET-ID-*.md`.
2. **Zero matches** → create one note at `tickets/TICKET-ID-slug.md` (use a descriptive slug if known, otherwise `unknown`).
3. **One match** → reuse it.
4. **Multiple matches** → stop with a duplicate-note error. List the files, ask the user which to keep, and do not set active ticket or write anything until resolved. This is a lookup failure, not a sync failure — do not run sync and do not quote the sync exit-`2` rule for it.

## Note Frontmatter Contract

Required fields for every note:

```yaml
---
ticket: TICKET-ID
project: project-name-or-unknown
title: Full title or unknown
synopsis: One-sentence known objective or unknown
status: investigating
priority: unknown
tags: []
branch: unknown
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

Add `resolved: YYYY-MM-DD` only when status is `resolved` or `closed`.

**Do not invent Jira metadata.** If a field value is not known from the user or from the note, set it to `unknown`. Never fabricate titles, descriptions, priorities, or tags.

## Note Body Template

```markdown
# TICKET-ID: Title

> [!status]+ Current Status
> **Status:** investigating
> **Current focus:** (one line — for AI resumption)
> **Blocked by:** (if blocked)

## Problem

Crisp description of what is broken and when it happens.

## Root Cause

> [!tip] Root Cause
> (Fill in when found) Mechanistic explanation.

## Investigation Log

### YYYY-MM-DD — Session title

What you found, commands run, observations.

## Approaches Tried

| Approach | Result | Notes |
|----------|--------|-------|
| Description | ✅ / ❌ / ⚠️ | Why |

## Fix / Solution

Steps to resolve.

## Branches & Commits

| Branch | Status | Notes |
|--------|--------|-------|

## Related

- (links to other tickets, project notes, runbooks)

## Next Steps

- [ ] Actionable item
```

**Replace every placeholder before saving.** The template above is a shape, not content. A saved note must never contain the literal placeholder text — `Title`, `(one line — for AI resumption)`, `(if blocked)`, `Crisp description of what is broken and when it happens.`, `| Description | ✅ / ❌ / ⚠️ | Why |`, `Steps to resolve.`, `(links to other tickets, project notes, runbooks)`, or `- [ ] Actionable item`. If you have no content for a section, leave the section body empty or write `unknown` — for the heading that means `# INFRA-4821: unknown`, and for an empty table it means keeping only the header row. Leaving the placeholder in a saved note is a defect, not a neutral default.

## Updating the Note

Update the note **during** the session, not after. Key moments:
- Finding → add to Investigation Log
- Failed attempt → add to Approaches Tried with ❌
- Focus shift → update `Current focus`
- Any write → update `updated:` date

The `Current focus` line is the most important field for AI resumption.

## Sync

After every note write, run sync **synchronously**:

```bash
~/knowledge-base/.tools/kb-sync.sh
```

Handle exit codes:
- **`0`** — success. Say nothing to the user.
- **`75`** — locally durable, remote sync deferred. Warn the user once per session with this exact line, including the deferral half: "Note saved locally; remote sync deferred." Do not shorten it to "saved locally" and do not repeat it for subsequent `75` exits.
- **`2`** — retained merge conflict. The note contains conflict markers. **Stop all further note writes until the conflict is resolved.** Report it to the user, then resolve: read both sides, keep all unique facts, remove the markers, `git add`, `git commit`, re-run sync, and only resume writing once sync returns `0`.

Rules that must not be broken:

- Run sync **synchronously** and wait for it. Never background or detach it (`&`, `nohup`, `setsid`, `disown`, async job).
- Never suppress its output or exit code (`&>/dev/null`, `|| true`, ignoring `$?`).
- Never report success for a write whose sync exit code was not observed.
- Sync follows a write. Do not run it when nothing was written — opening or reading a note is not a write.

## UI State Tool (Optional)

After the first note write for a ticket, call `knowledge_tracking_state`:

```json
{
  "action": "activate",
  "kind": "jira",
  "identifier": "TICKET-ID",
  "summary": "known synopsis or concise current objective"
}
```

If `knowledge_tracking_state` is unavailable, warn once ("UI state tool not available; tracking continues without UI indicator") and continue normally. Do not retry or error.

When **switching** tickets: update the previous note's `Current focus` to reflect the stopping point, then call the tool with `action: "activate"` for the new ticket.

When **closing** the active ticket: call the tool with `action: "stop"`.

## /jira-ticket-tracking Commands

| Command | Action |
|---------|--------|
| `/jira-ticket-tracking list` | List all open tickets (status ≠ `closed`) with synopsis |
| `/jira-ticket-tracking all` | List every ticket, open and closed |
| `/jira-ticket-tracking closed` | List only closed tickets |
| `/jira-ticket-tracking TICKET-123` | Open or create note, set as active ticket for session |
| `/jira-ticket-tracking close TICKET-123` | Set `status: closed`, add `resolved:` date, sync, clear active ticket |
| `/jira-ticket-tracking pull` | Pull changes from remote into local knowledge base |

A bare `TICKET-123` typed **without** the `/jira-ticket-tracking` prefix is not a command. It never opens, creates, or activates anything — see [Activation](#activation).

**Listing format:**

```
INFRA-4821  [in-progress]  Redis cluster failover causes 30s downtime
AUTH-201    [blocked]      OAuth token refresh fails silently on mobile
```

## Session Ticket Tracking

Running `/jira-ticket-tracking TICKET-123` opens (or creates) the note and sets `TICKET-123` as the **active ticket** for this session. Active state is held in conversation context only. Nothing else sets the active ticket — a bare identifier mention does not.

While a ticket is active:
- Write findings, commands, dead ends, and focus changes into the note continuously.
- Update `Current focus` on every focus shift and `updated:` on every write.
- Sync after every write.

### Switching Tickets

Running `/jira-ticket-tracking OTHER-456` while a ticket is active:
1. Update the previous note's `Current focus` to reflect where work stopped.
2. Sync the previous note.
3. Open the new ticket's note and set it as active.
4. Call `knowledge_tracking_state` with `action: "activate"` for the new ticket (if available).

### Drift Detection

Before doing substantive work in a session with an active ticket, check whether the user's request relates to that ticket (compare against `title`, `synopsis`, `tags`, `Problem`). If unrelated:

1. Do not silently write to the active ticket. Do not silently drop tracking.
2. Ask one focused question with choices:
   - Continue tracking under TICKET-ID
   - Stop ticket tracking for this session
   - Switch to a different ticket (name a plausible match if one exists, or offer to create new)
3. Act on the user's choice.

## Closing a Ticket

When `/jira-ticket-tracking close TICKET-123`:
1. Find the note (same lookup rules — zero/one/multiple matches).
2. Set `status: closed`, add `resolved: YYYY-MM-DD`, update `updated:`.
3. Sync.
4. If active, clear active ticket and call `knowledge_tracking_state` with `action: "stop"` (if available).

## Resuming Work

1. Open `~/knowledge-base/tickets/TICKET-ID-*.md`
2. Read `status` and `branch` from frontmatter
3. Read `Current focus` — this is where you left off
4. Scan `Approaches Tried` to avoid repeating dead ends
5. Continue from `Next Steps`

## Dual-Tracker Routing

When project tracking (e.g. a `projects/` note) is also active in the session:

- **Jira note** gets: execution details, commands run, ticket status changes, investigation log entries.
- **Project note** gets: reusable mechanistic findings only — insights that apply beyond this single ticket. Do not copy routine progress or ticket administration.
- **Cross-links:** Add `Project: [[projects/project-name/topic]]` in the Jira note's Related section. Add `Ticket: [[tickets/TICKET-ID-slug]]` in the project note.
- **Write only what was established.** A reusable finding is generalised in *scope*, never enriched with new detail. Do not add default values, recommended ranges, timings, percentages, cycle counts, or failure mechanisms that the user did not state and that are not already recorded in a note. "This applies to all Redis clusters" is generalisation and is fine; "the default is 30000ms and this adds ~3.5s per cycle" is fabrication unless someone said so.
- Do not raise a drift question when updating a project note as part of dual-tracker routing — this is expected behaviour.

## Naming Conventions

| Field | Convention |
|-------|-----------|
| Filename | `TICKET-ID-kebab-case-slug.md` |
| `status` | `investigating` → `in-progress` → `blocked` / `resolved` / `closed` |
| `synopsis` | One sentence: what needs to happen (shown in listing) |
| Tags | lowercase, hyphenated: `redis`, `auth-service` |
| Branch | match git: `fix/...`, `feat/...` |
