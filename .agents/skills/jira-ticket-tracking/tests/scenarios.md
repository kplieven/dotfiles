# Jira Skill Baseline Scenarios

Five reusable prompts for testing the `jira-ticket-tracking` skill.
Each scenario is self-contained and intended to be run against a fresh agent
with an isolated knowledge-base path (e.g. `~/kb-test-<scenario>/`).

---

## Shared rubric definitions

These definitions apply to every scenario below.

### sync-invocation

| Result | Condition |
|--------|-----------|
| **Pass** | `~/knowledge-base/.tools/kb-sync.sh` is invoked **synchronously** after each note write, the exit code is observed, and it is handled as: `0` → silent, `75` → warn the user once per session, `2` → report and **stop all further note writes until resolved** |
| **Fail** | Sync is backgrounded or detached (`&`, `nohup`, `setsid`, `disown`), its output or exit code is suppressed (`&>/dev/null`, `|| true`), a non-zero exit is swallowed or reported as success, the wrong command is used (e.g. the legacy `sync-kb.sh &>/dev/null &`), or sync is not run after a write |
| **N/A** | The scenario expects no note write |

Exit `0` producing user-visible sync chatter is also a Fail (must be silent).

### active-state

Tracking is **explicit only**. Setting an active ticket, creating a note, writing
to a note, or syncing in response to a **bare** ticket identifier (no
`/jira-ticket-tracking` prefix) is a Fail, regardless of how helpful the note is.

---

## Scenario 1 — Bare Ticket ID Must Not Activate; Explicit Invocation Must

**Setup:** No note exists for `INFRA-4821`. No Jira API is available; the agent
cannot look up the real ticket.

**Prompt sequence (two turns):**

Turn 1 — bare identifier, **not** a command (paste verbatim):

```
I'm looking at INFRA-4821 today. In general, what does a Redis sentinel failover involve?
```

Turn 2 — explicit invocation (paste verbatim):

```
/jira-ticket-tracking INFRA-4821
```

**Expected behaviour:**

Turn 1 (bare identifier — must NOT activate):
1. **No file is created** anywhere under `tickets/`.
2. **No active ticket** is set.
3. **No sync** is run and `knowledge_tracking_state` is not called.
4. Agent answers the actual question and offers tracking **once**, naming the
   exact command `/jira-ticket-tracking INFRA-4821`.

Turn 2 (explicit invocation — must activate):
5. Agent searches `tickets/INFRA-4821-*.md` — finds nothing.
6. Agent creates `tickets/INFRA-4821-unknown.md` (or similar slug).
7. Frontmatter fields that cannot be inferred are `unknown` (title, synopsis,
   project, priority, branch) and `tags: []` — not invented values.
8. `status` is set to `investigating`.
9. INFRA-4821 is declared the active ticket for the session.
10. `~/knowledge-base/.tools/kb-sync.sh` runs synchronously; exit `0` is silent.

**Scoring rubric:**

| Criterion | Pass | Fail |
|-----------|------|------|
| note-path | No file after turn 1; `tickets/INFRA-4821-*.md` created in turn 2 | File created on turn 1, wrong path, or no file after turn 2 |
| metadata-fidelity | Unknown fields marked `unknown`/`[]`, not fabricated | Any invented title/description/priority |
| active-state | Not active after turn 1 (tracking offered instead); active INFRA-4821 after turn 2 | Activated by the bare identifier, or not set after the explicit command |
| drift-behaviour | N/A (no prior active ticket) | Drift question shown spuriously |
| sync-invocation | No sync in turn 1; shared sync-invocation rule satisfied in turn 2 | Sync in turn 1, or shared sync-invocation rule violated |
| invented-facts | None | Any fabricated Jira metadata |

---

## Scenario 2 — Drift Detection

**Prompt sequence (two turns):**

Turn 1:
```
/jira-ticket-tracking INFRA-4821
```
A note for INFRA-4821 already exists with `synopsis: Redis cluster failover causes downtime`.

Turn 2:
```
Can you help me write a Python script to parse CSV files?
```

**Expected behaviour:**
1. Turn 1: agent opens the note, sets INFRA-4821 as active ticket.
2. Turn 2: agent detects drift (CSV parsing is unrelated to Redis/infrastructure).
3. Agent asks **one** focused question offering at least three choices:
   - Continue tracking under INFRA-4821
   - Stop ticket tracking
   - Switch to a different ticket (names a plausible match if one exists, otherwise
     offers to create new)
4. Agent does **not** silently write CSV content to the INFRA-4821 note.
5. Agent does **not** silently drop tracking.

**Scoring rubric:**

| Criterion | Pass | Fail |
|-----------|------|------|
| note-path | Existing note opened correctly | Note recreated or wrong path |
| metadata-fidelity | Frontmatter unchanged after turn 1 | Fields overwritten |
| active-state | INFRA-4821 active after turn 1 | Not set |
| drift-behaviour | Exactly one drift question with ≥3 choices | Silent write, silent drop, or >1 question |
| sync-invocation | Shared sync-invocation rule satisfied for the turn-1 write | Shared sync-invocation rule violated |
| invented-facts | No new facts added to note on turn 2 | CSV content written to INFRA-4821 note |

---

## Scenario 3 — Duplicate Note Files for Same Ticket

**Setup:** Two files exist:
- `~/knowledge-base/tickets/INFRA-4821-redis-failover.md`
- `~/knowledge-base/tickets/INFRA-4821-duplicate-entry.md`

**Prompt:**
```
/jira-ticket-tracking INFRA-4821
```

**Expected behaviour:**
1. Agent detects both files match `INFRA-4821-*.md`.
2. Agent reports the duplicate to the user and asks which file to use
   (or which to keep), rather than silently picking one.
3. Agent does **not** open or merge files without user confirmation.
4. No data is discarded silently.

**Scoring rubric:**

| Criterion | Pass | Fail |
|-----------|------|------|
| note-path | No file silently selected | One file silently opened |
| metadata-fidelity | Both files' contents preserved | Either file overwritten |
| active-state | Not set until user resolves duplicate | Active ticket set prematurely |
| drift-behaviour | N/A | |
| sync-invocation | N/A — no write occurs, so no sync before resolution | Sync fired before resolution |
| invented-facts | None | Agent invents a merged note without consent |

---

## Scenario 4 — Finding Arrives While Remote Sync Is Deferred (exit 75)

**Setup:** `~/knowledge-base/.tools/kb-sync.sh` in the isolated KB is a stub that
prints a deferral message to stderr and **exits `75`** (locally durable, remote
sync deferred). The `knowledge_tracking_state` tool is unavailable.

**Prompt sequence:**

Turn 1:
```
/jira-ticket-tracking INFRA-4821
```
(Note exists; ticket becomes active.)

Turn 2:
```
I found that the Redis sentinel timeout is set to 5000ms instead of the
recommended 1500ms — that's the root cause of the failover delay.
```

**Expected behaviour:**
1. Agent writes the finding to the note (Investigation Log + Root Cause).
2. Agent runs sync **synchronously** and observes exit `75`.
3. Agent surfaces **one** warning that the note is saved locally and remote sync
   is deferred — and does not repeat it on the next `75`.
4. Exit `75` is **not** a task failure: the note file on disk reflects the finding
   and the ticket stays active.
5. Session continues normally.

**Scoring rubric:**

| Criterion | Pass | Fail |
|-----------|------|------|
| note-path | Finding written to correct note file | Finding not written |
| metadata-fidelity | `updated:` date updated; root cause section filled | Date stale or section missing |
| active-state | Ticket remains active after exit `75` | Active ticket cleared on deferred sync |
| drift-behaviour | N/A | |
| sync-invocation | Shared rule satisfied: synchronous call, exit `75` observed and warned exactly once | Backgrounded, suppressed, warned repeatedly, treated as fatal, or reported as success |
| invented-facts | Only stated facts recorded | Additional unrequested details added |

---

## Scenario 5 — Cross-Linking Between Jira Ticket and Project Tracker

**Setup:**
- Active Jira ticket: `INFRA-4821` (Redis failover)
- Project tracking is also active for project `infrastructure-hardening`, whose
  topic note exists at
  `~/knowledge-base/projects/infrastructure-hardening/redis-reliability.md`
  and covers general Redis reliability work

**Prompt:**
```
/jira-ticket-tracking INFRA-4821

The finding about sentinel timeout should also be noted as a reusable insight
in the infrastructure-hardening project note, since it affects all Redis clusters.
```

**Expected behaviour:**
1. Finding written to `INFRA-4821` note under Investigation Log.
2. Finding added to `projects/infrastructure-hardening/redis-reliability.md` as a
   reusable project-level insight, clearly attributed but not duplicating the full
   ticket detail.
3. `INFRA-4821` note gets a `Project: [[projects/infrastructure-hardening/redis-reliability]]`
   link in its Related section.
4. The project note gets a `Ticket: [[tickets/INFRA-4821-redis-failover]]` link back.
5. Each file updated independently; sync fired once per file write (or once after both).

**Scoring rubric:**

| Criterion | Pass | Fail |
|-----------|------|------|
| note-path | Both files updated at correct paths | Either file missing or wrong path |
| metadata-fidelity | Ticket note and project note each contain correct attribution | Content crossed over or repeated verbatim |
| active-state | INFRA-4821 remains active | Active ticket switched or cleared |
| drift-behaviour | N/A — cross-link is expected behaviour | Drift question raised for project-note update |
| sync-invocation | Shared rule satisfied after each write (or once after both) | Shared sync-invocation rule violated |
| invented-facts | Only stated finding recorded | Extra Redis details fabricated in project note |

---

## Test execution rules

- Each scenario runs in a **fresh agent** with an **isolated temporary knowledge
  base**; the real `~/knowledge-base/` must never be read for note lookup or
  written to.
- Agents must **not edit any project source code**, run builds, or modify any
  repository. The scenarios test note-taking behaviour only; a code edit is a
  test-protocol violation and is recorded as such.
- Record the agent identity (name/type/model), the verbatim decisive output, and
  the on-disk file evidence (`find`/`cat` output) for each scenario.
- Delete every temporary knowledge base after collecting evidence.

---

## Scoring Summary Template

Copy this table into `results.md` for each scenario run.

| Scenario | note-path | metadata-fidelity | active-state | drift-behaviour | sync-invocation | invented-facts | Overall |
|----------|-----------|-------------------|--------------|-----------------|-----------------|----------------|---------|
| S1 | | | | | | | |
| S2 | | | | | | | |
| S3 | | | | | | | |
| S4 | | | | | | | |
| S5 | | | | | | | |

Values: ✅ Pass · ❌ Fail · ⚠️ Partial · N/A

A scenario is **PASS** only when every applicable criterion is ✅. A ⚠️ on any
criterion means the scenario does not pass.
