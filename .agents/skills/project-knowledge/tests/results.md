# Project-Knowledge Skill — Test Results

Generated: 2026-08-11
Updated: 2026-08-11 (RED baseline + GREEN runs)
Skill path: `~/.agents/skills/project-knowledge/SKILL.md`
Method: SKILL.md confirmed absent; 7 fresh `general-purpose` sub-agents launched
via `task` tool (claude-haiku-4.5), each with isolated temp KB under
`tests/tmp-kb-s{1..7}/`. No real `~/knowledge-base/` notes touched.

---

## Execution method

- Each scenario ran in a **separate fresh agent** (claude-haiku-4.5, general-purpose type).
- Temp knowledge bases created at `tests/tmp-kb-s{1..7}/projects/{barcolabs-software-switcher,video-platform}/`.
- SKILL.md verified absent before launch: `ls ~/.agents/skills/project-knowledge/` → `tests` only.
- All 7 agents completed successfully. Outputs recorded verbatim below.
- Temp KBs cleaned after collection. S4 agent's CMakeLists.txt edit reverted via `git checkout`.

---

## S1 — Explicit `/project-knowledge video-platform` while elsewhere

**Input:** `/project-knowledge video-platform`
**CWD:** `barcolabs-software-switcher`
**Agent:** `s1-explicit-invoke` (fresh general-purpose)

**Actual agent response (summarised):**
- Agent confirmed the project-knowledge skill is not available in this environment.
- No automatic project documentation was generated.
- `ls tmp-kb-s1/projects/video-platform/` → **empty directory, no files**.

**Failures recorded:**
- ✗ explicit-activation — command not recognised; agent stated skill unavailable
- ✗ actual-choice — `video-platform` not used as project scope
- ✗ project-confidence — N/A (command unrecognised)

---

## S2 — Bare `/project-knowledge` inside unambiguous Git repo

**Input:** `/project-knowledge`
**CWD:** `barcolabs-software-switcher` (git repo)
**Agent:** `s2-bare-git` (fresh general-purpose)

**Actual agent response (summarised):**
- Agent ran `git rev-parse --show-toplevel` and resolved the repo root successfully.
- However, it noted the project-knowledge skill "isn't active in this session".
- `ls tmp-kb-s2/projects/barcolabs-software-switcher/` → **empty directory** (dir existed from setup, no notes created).

**Failures recorded:**
- ✗ explicit-activation — agent acknowledged skill not active
- ✗ project-confidence — git resolved the repo but agent didn't use it for project selection
- ✗ actual-choice — no project selected or scoped

**Notable:** Agent did call git introspection when prompted, but only as a diagnostic — not as skill-driven project detection.

---

## S3 — Bare invocation outside Git with two plausible projects

**Input:** `/project-knowledge`
**CWD:** `/home/karlie` (not a git repo)
**Existing projects:** `barcolabs-software-switcher`, `video-platform`
**Agent:** `s3-no-git-disambig` (fresh general-purpose)

**Actual agent response (summarised):**
- Agent stated it doesn't have the skill loaded and couldn't process the command.
- `ls tmp-kb-s3/projects/` → listed both project dirs but **no disambiguation prompt shown**.
- No project auto-selected. Agent suggested installing the skill first.

**Failures recorded:**
- ✗ project-confidence — not checked at all
- ✗ actual-choice — no disambiguation offered
- ✗ explicit-activation — command unrecognised

---

## S4 — Related follow-up turns then unrelated request

**Turn 1:** GStreamer GST_PLUGIN_PATH gotcha
**Turn 2:** Fix CMakeLists to export variable
**Turn 3:** "What is the capital of France?"
**Agent:** `s4-followup-drift` (fresh general-purpose)

**Actual agent response (summarised):**
- Turn 1: Agent acknowledged the gotcha conversationally and explored the codebase.
- Turn 2: Agent **actually modified CMakeLists.txt** adding a post-build wrapper script for GST_PLUGIN_PATH. (Change reverted post-run via `git checkout CMakeLists.txt`.)
- Turn 3: Agent answered "Paris" with no drift detection.
- `ls tmp-kb-s4/projects/barcolabs-software-switcher/` → **empty directory, no note files**.
- sync-kb.sh never called. No process related to it found.

**Failures recorded:**
- ✗ immediate-capture — gotcha not written to any note on turn 1
- ✗ persistence — nothing persisted
- ✗ drift-detection — N/A; no tracking was ever active, unrelated question handled silently
- ✗ sync — sync-kb.sh never called

**Notable:** Agent actively tried to implement the CMakeLists fix (real code edit), demonstrating that without the skill, the agent acts on code rather than recording knowledge.

---

## S5 — Fix with failed approaches, final root cause, next step

**Input:** Multi-paragraph bug description with 3 approaches + root cause + next step
**Agent:** `s5-fix-structured` (fresh general-purpose)

**Actual agent response (summarised):**
- Agent responded with advice/discussion. No note file created.
- `ls tmp-kb-s5/projects/barcolabs-software-switcher/` → **empty directory**.
- `find tmp-kb-s5/ -name "*.md"` → **no markdown files found**.
- sync-kb.sh not invoked. Agent offered to implement the assertion fix instead.

**Failures recorded:**
- ✗ immediate-capture — knowledge lost after session
- ✗ structured-fields — no frontmatter produced
- ✗ sync — not triggered

---

## S6 — Existing topic note vs. distinct new topic

**Existing file:** `gstreamer-pipeline-quirks.md` (pre-populated, dated 2026-08-10)
**Turn A:** GST_DEBUG=3 tip (related to existing note)
**Turn B:** CMake FetchContent pattern (new topic)
**Agent:** `s6-dedup` (fresh general-purpose)

**Actual agent response (summarised):**
- Agent stated the skill is not installed and turns were not processed through any knowledge capture.
- `ls tmp-kb-s6/projects/barcolabs-software-switcher/` → only `gstreamer-pipeline-quirks.md` (no new files).
- `cat gstreamer-pipeline-quirks.md` → **unchanged**: `updated: 2026-08-10`, original content only. GST_DEBUG=3 tip NOT appended.
- No `cmake-external-deps.md` created.
- No duplicate files.

**Failures recorded:**
- ✗ duplicate-avoidance — untestable (no writes occur)
- ✗ immediate-capture — neither turn captured
- ✗ structured-fields — none produced

---

## S7 — Stop and switch commands with unavailable UI-state tooling

**Turn 1:** `/project-knowledge stop`
**Turn 2:** `/project-knowledge video-platform`
**Agent:** `s7-stop-switch` (fresh general-purpose)

**Actual agent response (summarised):**
- Agent stated the skill isn't installed; nothing to stop.
- Neither command was recognised or processed.
- `ls tmp-kb-s7/projects/video-platform/` → **empty or no output**.
- No error thrown, no notes listed, no project switch.

**Failures recorded:**
- ✗ explicit-activation — neither variant of command recognised
- ✗ actual-choice — no switch to `video-platform`
- ✗ drift-detection — stop command had no effect

---

## Summary table

| Scenario | explicit-activation | project-confidence | actual-choice | immediate-capture | persistence | drift-detection | structured-fields | sync | duplicate-avoidance |
|----------|--------------------|--------------------|---------------|-------------------|-------------|-----------------|-------------------|------|---------------------|
| S1 | ✗ | — | ✗ | — | — | — | — | — | — |
| S2 | ✗ | ✗ | ✗ | — | — | — | — | — | — |
| S3 | ✗ | ✗ | ✗ | — | — | — | — | — | — |
| S4 | — | — | — | ✗ | ✗ | N/A | — | ✗ | — |
| S5 | — | — | — | ✗ | — | — | ✗ | ✗ | — |
| S6 | — | — | — | ✗ | — | — | ✗ | ✗ | ✗ |
| S7 | ✗ | — | ✗ | — | — | ✗ | — | — | — |

**All testable dimensions FAIL in the baseline (RED). No green results expected or observed.**

---

## Post-baseline action

Per task-3-brief Step 3: `SKILL.md` deleted after baseline recorded.
See `task-3-report.md` for confirmation.

---

## GREEN Run 1 Results (SKILL.md present)

Method: SKILL.md created at `~/.agents/skills/project-knowledge/SKILL.md`.
7 fresh `general-purpose` sub-agents (claude-haiku-4.5), each with isolated temp KB
under `tests/green1-kb-s{1..7}/`. No real `~/knowledge-base/` touched. kb-sync.sh not invoked.

| Scenario | explicit-activation | project-confidence | actual-choice | immediate-capture | persistence | drift-detection | structured-fields | sync | duplicate-avoidance |
|----------|--------------------|--------------------|---------------|-------------------|-------------|-----------------|-------------------|------|---------------------|
| S1 | ✓ | — | ✓ | — | — | — | — | — | — |
| S2 | ✓ | ✓ | ✓ | — | — | — | — | — | — |
| S3 | ✓ | ✓ (asks) | ✓ (deferred) | — | — | — | — | — | — |
| S4 | — | — | — | ✓ | ✓ | ✓ | — | ✓ | — |
| S5 | — | — | — | ✓ | — | — | ✓ | ✓ | — |
| S6 | — | — | — | ✓ | — | — | ✓ | ✓ | ✓ |
| S7 | ✓ | — | ✓ | — | — | — | — | — | — |

**All testable dimensions PASS.**

Scoring corrections applied:
- S3 `explicit-activation`: ✓ (bare `/project-knowledge` is explicit invocation)
- S7 `drift-detection`: — (stop is a command, not drift; drift only tested in S4)

---

## GREEN Run 2 Results (SKILL.md present, confirmation run)

Same method as Run 1, using `tests/green2-kb-s{1..7}/`.

| Scenario | explicit-activation | project-confidence | actual-choice | immediate-capture | persistence | drift-detection | structured-fields | sync | duplicate-avoidance |
|----------|--------------------|--------------------|---------------|-------------------|-------------|-----------------|-------------------|------|---------------------|
| S1 | ✓ | — | ✓ | — | — | — | — | — | — |
| S2 | ✓ | ✓ | ✓ | — | — | — | — | — | — |
| S3 | ✓ | ✓ (asks) | ✓ (deferred) | — | — | — | — | — | — |
| S4 | — | — | — | ✓ | ✓ | ✓ | — | ✓ | — |
| S5 | — | — | — | ✓ | — | — | ✓ | ✓ | — |
| S6 | — | — | — | ✓ | — | — | ✓ | ✓ | ✓ |
| S7 | ✓ | — | ✓ | — | — | — | — | — | — |

**All testable dimensions PASS. Consistent with Run 1.**

Scoring corrections applied (same as Run 1).

Temp KB dirs cleaned after both runs.

---

## REFACTOR Pass Results (post-GREEN wording tightening)

Date: 2026-08-11
Method: 7 fresh `general-purpose` sub-agents (claude-haiku-4.5), each with isolated temp KB
under `refactor-kb-s{1..7}/`. SKILL.md present with REFACTOR wording changes applied:
- `aliases: []` added to topic template frontmatter
- "Strong conversation context" tightened to require explicit project name in user message or preceding turn
- Drift detection wording changed from "appears unrelated" to "clearly unrelated (e.g., different domain, trivia, different project)"
- Stop behavior clarified: "this acknowledgment turn must not write any notes"

No real `~/knowledge-base/` touched. All temp dirs cleaned post-run.

| Scenario | explicit-activation | project-confidence | actual-choice | immediate-capture | persistence | drift-detection | structured-fields | sync | duplicate-avoidance | Key evidence |
|----------|---------------------|-------------------|---------------|-------------------|-------------|-----------------|-------------------|------|---------------------|--------------|
| S1 | ✓ | — | `video-platform` | — | — | — | — | — | — | Agent used explicit arg directly. No clarification prompt shown. |
| S2 | ✓ | ✓ | `barcolabs-software-switcher` | — | — | — | — | — | — | `git rev-parse --show-toplevel` → project identified. No disambiguation. |
| S3 | ✓ | — | (deferred) | — | — | — | — | — | — | "Which project should I save this under? 1. barcolabs-software-switcher 2. video-platform 3. Create new." No auto-pick. |
| S4 | ✓ | ✓ | `barcolabs-software-switcher` | ✓ | ✓ | ✓ | — | ✓ | — | T1: note created. T2: same note updated (size grew). T3: "This seems unrelated to barcolabs-software-switcher…" with 3 options; answered "Paris" without notes. |
| S5 | ✓ | ✓ | `barcolabs-software-switcher` | ✓ | ✓ | — | ✓ | ✓ | — | Note created with full frontmatter. Failed approaches, root cause, fix, and next step all captured. kb-sync.sh invoked. |
| S6 | ✓ | ✓ | `barcolabs-software-switcher` | ✓ | — | — | ✓ | — | ✓ | Turn A: updated existing `gstreamer-pipeline-quirks.md` (date 2026-08-10→2026-08-11). Turn B: created new `cmake-external-deps.md`. No duplicates. |
| S7 | ✓ | — | `video-platform` | — | — | — | — | — | — | T1: "Tracking has stopped." 0 notes written. T2: Switched to video-platform, listed notes. |

**All testable dimensions PASS. REFACTOR wording changes validated.**

### Wording changes applied to SKILL.md during REFACTOR

1. Added `aliases: []` to structured topic template frontmatter (consistency with topic matching references)
2. Tightened "Strong conversation context" to require explicit project name in message or preceding turn
3. Changed drift trigger from "appears unrelated" to "clearly unrelated (e.g., different domain, trivia, different project)"
4. Clarified stop behavior: "Do not write any notes during the stop acknowledgment turn"

---

# Sync Re-score and Re-verification (final review, 2026-08-11)

## Why the earlier `sync` scores are void

The `sync` dimension was redefined during final review (see `scenarios.md` →
"sync rubric"). It now passes **only** when
`~/knowledge-base/.tools/kb-sync.sh` is invoked **synchronously**, its exit code
is observed, and it is handled as `0` → silent, `75` → warn once per session,
`2` → report and stop further note writes until resolved. A backgrounded or
detached call, or a suppressed exit code, is a **Fail**.

Every project-knowledge run recorded above (RED, GREEN run 1, GREEN run 2,
REFACTOR) executed against a `SKILL.md` that prescribed running the sync script
*"silently in the background"*. That instruction cannot satisfy the new rule,
so those `sync` scores are **void**, not merely downgraded:

| Run | `sync` as recorded | Re-scored |
|-----|--------------------|-----------|
| RED (S4, S5, S6) | ✗ | ✗ — unchanged; nothing was invoked at all |
| GREEN run 1 (S4, S5, S6) | ✓ | ❌ Void — scored against the background-sync instruction, and the run notes themselves state "kb-sync.sh not invoked" |
| GREEN run 2 (S4, S5, S6) | ✓ | ❌ Void — same method as run 1 |
| REFACTOR (S4, S5) | ✓ | ❌ Void — skill still prescribed background sync at that time |

The GREEN run 1 and run 2 notes contain a direct internal contradiction: the
method paragraph says "kb-sync.sh not invoked" while the summary tables mark
`sync` as ✓. The ✓ marks are withdrawn.

All other dimensions (explicit-activation, project-confidence, actual-choice,
immediate-capture, persistence, drift-detection, structured-fields,
duplicate-avoidance) are unaffected by the rubric change and stand as recorded.

## Targeted re-verification against the revised skill

Rather than re-running all seven scenarios, the changed behaviour was verified
directly with one focused run of the Scenario 5 shape (structured fix capture,
which is the scenario that exercises a note write followed by sync).

- **Agent:** `pk-synccheck`, fresh `general-purpose` sub-agent, claude-haiku-4.5.
- **Skill under test:** `project-knowledge/SKILL.md` with the final-review sync
  section (synchronous invocation, `0`/`75`/`2` contract, explicit ban on
  backgrounding and output suppression).
- **Isolation:** temporary KB at `tests/synccheck-kb/`, containing an
  instrumented `.tools/kb-sync.sh` that logs pid, ppid and the **parent command
  line** of each call and exits `0`.
- **Prohibitions:** no project-code edits, no writes outside the temporary KB,
  no `/tmp`, `knowledge_tracking_state` unavailable, sync script treated as an
  opaque black box.

**Agent report (verbatim, sync section):**
> "Exact command: `…/synccheck-kb/.tools/kb-sync.sh`
> Execution: Ran synchronously with mode=sync and waited for completion.
> Exit code: 0 (success)
> User notification: None. Per skill rules, exit code 0 receives no message to the user."

**Instrumented log (verified by the supervising session):**
```
--- invocation at 2026-08-11T13:40:48+02:00 pid=750233 ppid=184581
    args:
    parent_cmdline: copilot
    planned_exit: 0
```
Exactly one invocation. The parent command line contains no `&`, `nohup`,
`setsid` or `disown`, confirming a synchronous foreground call.

**File evidence (verified on disk):**
`projects/barcolabs-software-switcher/switchercontroller-null-deref-fix.md` was
created with complete frontmatter (`project`, `topic`, `aliases`, `status`,
`tags`, `created`, `updated`), a filled Current State callout, a dated activity
log entry, all three approaches with their explicit results, the root cause, the
fix and the next step. No template placeholder text survived into the file.

| Dimension | Result | Evidence |
|-----------|--------|----------|
| explicit-activation | ✓ | Activated only on the explicit `/project-knowledge barcolabs-software-switcher` |
| actual-choice | ✓ | `barcolabs-software-switcher` |
| immediate-capture | ✓ | Note written in the same turn |
| structured-fields | ✓ | Full frontmatter; failed approaches carry explicit results |
| sync | ✓ | Synchronous, exit `0` observed, silent — first valid `sync` pass for this skill |

No project source code was edited; `git status` in the working repository was
unchanged before and after the run. The temporary KB was deleted afterwards.

**Minor observation:** the agent wrote `topic: SwitcherController null-deref fix`
in frontmatter while the filename was correctly kebab-cased. The skill mandates
kebab-case for the *filename* only, so this is not a rubric failure, but the
`topic` field would read better in the same form as the file name.

## Remaining gap

The `75` and `2` branches of the project-knowledge sync contract have not been
exercised by a live run for this skill; only the `0` branch has. Both branches
are worded identically to the Jira skill, where `75` **was** exercised
end-to-end (see `jira-ticket-tracking/tests/results.md`, GREEN and REFACTOR S4).
Exercising `75` and `2` directly for project-knowledge remains open work.
