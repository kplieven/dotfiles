---
name: guiding-codebase-walkthroughs
description: Use when the user wants to understand, learn, get familiar with, or "get a grip on" an existing codebase, module, or architecture — "walk me through the code", "explain the flow", "explain all the traits/structs", "how does this fit together", "I'm getting lost in this code". Not for explaining a diff, PR, or commit range.
---

# Guiding Codebase Walkthroughs

## Overview

People learn a codebase by following **one real request** through it, meeting each type at the moment the request reaches it. A full inventory of files, types or "tricky bits" in one reply reads as a wall; the user nods, then says "I'm really failing to get this".

**Core principle:** one hop per reply, in → out → state change, then stop and offer the next hop.

## Reply recipe

**First reply** has exactly these parts, in order:

1. **Opening line:** one sentence on what the program does. The reply starts with this line.
2. **The request you'll trace**, chosen as the main entry point (e.g. `PUT /v1/configuration`, `ttctl apply`).
3. **The path** as one line: `main.rs → api::apply → ControllerService::apply → … → Nomad`.
4. **Hop 1** in the hop format below.

**Every later reply** is the next hop in the hop format, unless the user asks a question, in which case answer only that question, then offer the hop you were at.

**Hop format:**

- **Where:** `file.rs:line` — function name.
- **In → Out → State:** what arrives, what leaves, what changes (one line each).
- **New here:** only the types first met at this hop, one line each of ≤ 15 words: what it is and why it exists.
- **Language bits:** at most 3 constructs on this hop that trip up someone at the user's stated level, each tied to the line it's on.
- **Next:** `Next hop: <function> in <file>. Continue?`

**Word budget:** first reply ≤ 350 words, every later reply ≤ 250. Plain words, short sentences, no recap of earlier hops.

## Conditionals

- **User asks for "all traits/structs" or "the architecture":** the first reply is parts 1–3 plus each type placed at the hop where it appears (one line of ≤ 15 words per type), ending with `Start hop 1?` That *is* the inventory, ordered by the request.
- **You notice bugs or design problems:** add one final line: `Noticed N possible issues — want them after the walkthrough?` Details only if they say yes.
- **User restates their understanding** ("so X does Y, right?"): start with *Yes* or *Not quite*, then the correction in ≤ 2 sentences.
- **User wants to stop for now:** record path, hops done, open questions and next hop in the handoff file (per global instructions).
- **Explaining a diff, PR, or branch instead of a codebase:** this skill doesn't apply.

No quizzes or HTML pages unless the user asks for them.
