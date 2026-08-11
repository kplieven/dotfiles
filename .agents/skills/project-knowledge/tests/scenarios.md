# Project-Knowledge Skill — Baseline Scenarios

Generated: 2026-08-11

---

## Scoring dimensions

| Dimension | What we measure |
|-----------|----------------|
| **explicit-activation** | Skill invoked when `/project-knowledge` command used |
| **project-confidence** | Correct project identified without user clarification |
| **actual-choice** | Which project name ended up in the note path |
| **immediate-capture** | Note written in the same turn the knowledge appeared |
| **persistence** | Note still present and loadable in a later turn |
| **drift-detection** | Unrelated request flagged / skill politely stops tracking |
| **structured-fields** | Frontmatter correct (project, topic, tags, created, updated) |
| **sync** | See the sync rubric below |
| **duplicate-avoidance** | Existing note updated, not a second file created |

### sync rubric

| Result | Condition |
|--------|-----------|
| **Pass** | `~/knowledge-base/.tools/kb-sync.sh` is invoked **synchronously** after each note write, the exit code is observed, and it is handled as: `0` → silent, `75` → warn the user once per session, `2` → report and **stop all further note writes until resolved** |
| **Fail** | Sync is backgrounded or detached (`&`, `nohup`, `setsid`, `disown`), its output or exit code is suppressed (`&>/dev/null`, `\|\| true`), a non-zero exit is swallowed or reported as success, the wrong command is used (e.g. the legacy `sync-kb.sh &>/dev/null &`), or sync is not run after a write |
| **N/A** | The scenario expects no note write |

Exit `0` producing user-visible sync chatter is also a Fail (must be silent).

---

## Scenario 1 — Explicit invocation while working elsewhere

**Setup:** CWD is `/home/karlie/repos/barco-labs/barcolabs-software-switcher`.  
**User message:**
```
/project-knowledge video-platform
```

**Expected behavior:**
- Skill activates (explicit-activation ✓)
- Ignores CWD; uses `video-platform` as project name
- Lists notes under `~/knowledge-base/projects/video-platform/` (or reports none)
- No note written (the invoking message carries no knowledge to capture, so activation alone is not a write)
- No sync run (nothing was written)
- No clarification prompt

**Score dimensions:** explicit-activation, actual-choice

---

## Scenario 2 — Bare invocation inside unambiguous Git repo

**Setup:** CWD is `/home/karlie/repos/barco-labs/barcolabs-software-switcher`  
(git toplevel → `barcolabs-software-switcher`).  
**User message:**
```
/project-knowledge
```

**Expected behavior:**
- Skill runs `git rev-parse --show-toplevel`, derives `barcolabs-software-switcher`
- Lists existing notes for that project (or reports none found)
- project-confidence HIGH; no ambiguity prompt
- actual-choice = `barcolabs-software-switcher`

**Score dimensions:** explicit-activation, project-confidence, actual-choice

---

## Scenario 3 — Bare invocation outside Git with two plausible projects

**Setup:** CWD is `/home/karlie` (not a git repo).  
Existing project folders: `barcolabs-software-switcher`, `video-platform`.  
**User message:**
```
/project-knowledge
```

**Expected behavior:**
- git command fails; skill lists existing project folders as choices
- Prompts: "Which project should I save this under?"
  - `barcolabs-software-switcher`
  - `video-platform`
  - Create new project: ___
- Does NOT auto-pick; waits for user input

**Score dimensions:** project-confidence (expected LOW / asks), actual-choice (deferred)

---

## Scenario 4 — Related follow-up turns then unrelated request

**Setup:** CWD = `barcolabs-software-switcher`. Active project = same.  
**Turn 1 (user):** "We just figured out that GStreamer needs `GST_PLUGIN_PATH` set before the switcher starts or it silently falls back to software decode."  
**Turn 2 (user):** "Can you fix the CMakeLists to export that variable?"  
**Turn 3 (user):** "By the way, what is the capital of France?"

**Expected behavior:**
- Turn 1: note written to `gstreamer-pipeline-quirks.md` (or similar), sync runs synchronously per the sync rubric
- Turn 2: note updated with CMakeLists detail; still same project
- Turn 3: unrelated request → skill stops writing; responds to question normally; no note created

**Score dimensions:** immediate-capture, persistence, drift-detection, sync

---

## Scenario 5 — Fix with failed approaches, final root cause, next step

**Setup:** CWD = `barcolabs-software-switcher`.  
**User message:**
```
We tried three things to fix the null-deref in SwitcherController::init():
1. Null-check before dereference — didn't work, pointer valid but uninitialized
2. Moving init order — made it worse
3. Root cause: gst_init() must be called before any GstElement allocation.
   Fix: call gst_init() at top of main() before constructing SwitcherController.
Next step: add an assertion in SwitcherController::init() to enforce ordering.
```

**Expected behavior:**
- Note created: `null-deref-in-switcher-controller-init.md`
- Frontmatter: project=barcolabs-software-switcher, appropriate tags
- Body includes: failed approaches, root cause, fix applied, next step
- updated: date set correctly
- Sync runs synchronously and is silent on exit `0`

**Score dimensions:** immediate-capture, structured-fields, sync

---

## Scenario 6 — Existing topic note vs. distinct new topic

**Setup:** `~/knowledge-base/projects/barcolabs-software-switcher/gstreamer-pipeline-quirks.md` already exists.  
**Turn A (user):** "Also, `GST_DEBUG=3` really helps when the pipeline stalls."  
**Turn B (user):** "Totally separate thing: we use CMake FetchContent for all external deps — libsoup, glib, gstreamer-plugins-bad."

**Expected behavior:**
- Turn A: *updates* existing `gstreamer-pipeline-quirks.md` (adds debug tip, updates `updated:` date) — no new file
- Turn B: *creates* new `cmake-external-deps.md` — distinct topic
- No duplicate `gstreamer-pipeline-quirks-2.md` created

**Score dimensions:** duplicate-avoidance, structured-fields, immediate-capture

---

## Scenario 7 — Stop and switch commands with unavailable UI-state tooling

**Setup:** Skill is active; project = `barcolabs-software-switcher`.  
**Turn 1 (user):** `/project-knowledge stop`  
**Turn 2 (user):** `/project-knowledge video-platform`

**Expected behavior:**
- Turn 1: Skill acknowledges stop; no further auto-capture in this session
- Turn 2: Skill switches active project to `video-platform`; lists its notes
- If "stop" is not a defined command, skill responds gracefully (does not error, explains available commands)
- No writes to knowledge base during either turn — nothing is pending to finalize in this scenario, so the "finalize unrecorded focus" branch does not apply

**Score dimensions:** explicit-activation, actual-choice, drift-detection

---

## Test execution notes

- Each scenario runs in a **fresh agent** with an **isolated knowledge base** copy.
- The project-knowledge SKILL.md is **absent** during RED runs (moved out of discovery path).
- Baseline behavior = what a generic Copilot CLI agent does *without* the skill.
- RED pass records the actual agent output verbatim (truncated to key evidence).
- Agents must **not edit any project source code**, run builds, or modify any
  repository. A code edit is a test-protocol violation and is recorded as such.
- Delete every temporary knowledge base after collecting evidence.
