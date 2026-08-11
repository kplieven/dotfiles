---
name: project-knowledge
description: Use when the user explicitly invokes project knowledge tracking or continues work while project tracking is active.
---

# Project Knowledge Tracking

## Overview

Track project knowledge explicitly via the `/project-knowledge` command. Notes live under `~/knowledge-base/projects/<project>/`. Active-project state is session-local — it lives only in conversation context and is never persisted to disk.

**Never activate from ordinary project work without explicit invocation.**

## Command Contract

| Invocation | Behavior |
|---|---|
| `/project-knowledge` | Infer project from context, activate, capture any knowledge carried by the invoking message, list existing notes |
| `/project-knowledge PROJECT` | Activate the named project, capture any knowledge carried by the invoking message, list existing notes |
| `/project-knowledge switch PROJECT` | Finalize current focus and activate another project |
| `/project-knowledge stop` | Finalize any unrecorded focus and stop automatic knowledge capture |
| `/project-knowledge list` | List actual project directories and note counts |

## Project Resolution

Resolve project name in this order:

1. **Explicit argument** — if the user passed a project name, use it directly
2. **Git remote** — `git remote get-url origin` → extract repository name
3. **Git root basename** — `git rev-parse --show-toplevel` → basename
4. **Strong conversation context** — only if the project name appeared explicitly in the user's message or the immediately preceding turn

If none is reliable:
- List actual directories under `~/knowledge-base/projects/`
- Ask a single choice question: "Which project should I save this under?"
- Include an option to create a new project
- **Do not** label an uncertain CWD candidate as recommended
- **Do not** auto-pick; wait for user input

## Structured Topic Template

Every note file uses this structure:
```yaml
---
project: project-name
topic: descriptive-topic-name
aliases: []
status: active
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

```markdown
> [!status]+ Current State
> **Status:** active
> **Current focus:** One-line resumption point

## Problem or Question
## Activity Log
## Findings
## Decisions
## Approaches Tried
## Gotchas
## Solution / Outcome
## Related
## Next Steps
```

- Activity log entries must be dated: `### YYYY-MM-DD — Description`
- Failed approaches must include explicit results explaining why they failed
- Replace every placeholder before saving; a saved note must not contain the literal template text such as `One-line resumption point`. Leave a section empty rather than keeping its placeholder.
- Record only what was established. Do not enrich a finding with default values, recommended ranges, timings, or mechanisms that were not stated by the user and are not already in a note.

## Topic Matching and Note Updates

Before creating a new note:

1. **List existing notes** in `~/knowledge-base/projects/<project>/`
2. **Check frontmatter** — if an existing note's `topic:` or `aliases:` matches the current subject, **update that note** instead of creating a new one
3. **Create a new file** only for a genuinely distinct subject — use `kebab-case-topic-name.md`

On every write to a note:
- Update the `updated:` date in frontmatter
- Update `Current focus:` in the status callout

## Sync

After **every** note write, run sync **synchronously** and wait for it to finish:

```bash
~/knowledge-base/.tools/kb-sync.sh
```

Handle the exit code:

- **`0`** — success. Say nothing to the user.
- **`75`** — locally durable, remote sync deferred. The note is safe on disk. Warn the user **once per session** with this exact line, including the deferral half: "Note saved locally; remote sync deferred." Do not shorten it to "saved locally", do not repeat it for subsequent `75` exits, and continue working normally.
- **`2`** — retained merge conflict. The note contains conflict markers. **Stop all further note writes until the conflict is resolved.** Report it to the user, then resolve: read both sides, keep all unique facts, remove the markers, `git add`, `git commit`, re-run sync, and only resume writing once sync returns `0`.

Any other non-zero exit is reported to the user once; the note stays on disk and the session continues.

Rules that must not be broken:

- Run sync **synchronously** and wait for it. Never background or detach it (`&`, `nohup`, `setsid`, `disown`, async job).
- Never suppress its output or exit code (`&>/dev/null`, `|| true`, ignoring `$?`).
- Never report success for a write whose sync exit code was not observed.
- Sync follows a write. Do not run it when nothing was written — listing or reading notes is not a write.

## Active State and Behavior

### Activation

When the skill activates:
1. Resolve and confirm the project
2. **Immediately write** any knowledge carried by the invoking message to the appropriate note. If the invoking message carries no knowledge — a bare `/project-knowledge` or `/project-knowledge PROJECT` with nothing else in it — write nothing yet. Activation on its own is not a write.
3. Call `knowledge_tracking_state` if available (warn once if unavailable, then continue without it)
4. If step 2 wrote a note, run sync as described in [Sync](#sync). If nothing was written, do not run sync.

### Related Turns (while tracking is active)

On turns related to the active project, record:
- Meaningful findings and observations
- Decisions and their rationale
- Failed approaches with explicit results
- Outcomes and resolutions
- Focus changes

Run sync as described in [Sync](#sync) after every note write.

### Drift Detection

When a turn is clearly unrelated to the active project (e.g., different domain, trivia, or a different project):
- **Do not** silently continue tracking
- Ask the user: "This seems unrelated to `<project>`. Should I:
  1. Continue tracking `<project>`
  2. Stop tracking
  3. Switch to `<other-project>`" (list plausible existing projects)
- Respond to the user's actual question normally regardless of their tracking choice

### Stop Behavior

On `/project-knowledge stop`:
- If knowledge or a focus change from this session has not been recorded yet, write it to the active note, update `Current focus:` and `updated:`, then sync. If everything is already recorded, write nothing and do not sync.
- Acknowledge that tracking has stopped
- No further automatic knowledge capture until explicitly re-invoked
- Never write a note whose only content is that tracking stopped

### Switch Behavior

On `/project-knowledge switch PROJECT`:
- Finalize any unrecorded focus or knowledge for the current project (write and sync only if something is actually pending)
- Activate the new project
- List notes for the new project
