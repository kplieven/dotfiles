# guiding-codebase-walkthroughs — Scenarios

Fixture: `bash setup-fixtures.sh <dir>` builds `controller/`, a layered async Rust service:
`main.rs` → `api.rs` (axum, `State<Arc<ControllerService<R>>>`) → `service.rs` (`ControllerService<R: ConfigurationRuntime>`) → `runtime.rs` (trait) → `convergence.rs` (`DesiredStateConverger<D: ReconcilerDependencies>`, `RwLock<Option<…>>`) → `nomad.rs` (`NomadDependencies`), plus `events.rs` (event-stream loop with buffer/`last_index`).
Each scenario runs in a fresh general-purpose subagent with cwd = `controller/`. Agents aren't told they're tested. Responses are kept verbatim for scoring.

## Scoring dimensions

| Dimension | Pass condition |
|---|---|
| **no-quiz** | Does not invoke explain-diff-html, generate HTML, or quiz the user |
| **traced** | Structured as one concrete request followed hop by hop (in → out → state change), introducing each type when the request reaches it — not a per-file/per-type inventory |
| **mechanics-in-place** | Explains the confusing language mechanics (generic bounds, `Arc`, extractor, `async_trait`, `RwLock<Option<…>>`) at the hop where they appear |
| **chunked** | Ends at a natural stopping point and offers the next hop, instead of covering the whole codebase in one reply. Word count recorded. |
| **concise** | No preamble, no restating the request, short sentences; ≤ ~600 words |

---

## W1 — "Walk me through from main.rs" (real: "Continue Development Tasks", 2026-09-17)

**User message:**
```
Walk me through the code starting from main.rs. Explain the tricky bits to me. I know basic Rust, but still get confused when reading the main with all these traits...
```
**Real failure:** walkthrough + quiz offered; user: "Forget about the quiz. I understand the code." Elsewhere: "Explain … Remove cognitive clutter and be concise. Use clear language."

## W2 — "Explain all traits and structs" (real: "Overview Current Architecture Flow", 2026-09-24)

**User message:**
```
Explain all traits and structs that make up the functionality and to which block they belong. Explain the flow between them. I'm trying to get a grip on the architecture.
```
**Real failure:** agent produced a type inventory grouped by block; next turn the user said "Trying to get familiar with the code but really failing to. How would you help me getting up to speed piece by piece?" — the agent then proposed tracing one `apply` request hop by hop, which worked.
