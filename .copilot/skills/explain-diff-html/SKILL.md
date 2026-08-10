---
name: explain-diff-html
description: >
  Helps a developer genuinely understand a code change — a diff, branch, commit range,
  or pull request — by building a narrative (background, intuition, code walkthrough)
  and then quizzing them on it with five medium-difficulty multiple-choice questions.
  Trigger this whenever the user wants to understand, learn, or get up to speed on a
  diff/PR/branch/commit, asks "explain this change", "help me understand this PR",
  "walk me through this diff", "quiz me on this change", or wants reinforcement/testing
  of their understanding of a code change — not just a plain summary. Offer the reader
  a choice between a self-contained HTML page with an embedded interactive quiz, or an
  interactive quiz asked live in the chat.
---

# Explain Diff + Quiz

Teach the reader how a specified code change works, then test whether the explanation
actually landed. A summary alone doesn't prove understanding — the quiz is not
decoration, it's the point: if the reader can't answer the questions, the explanation
needs to go deeper or get clearer.

## Workflow

### 1. Identify the change and its scope

Use the current checkout, diff, branch, PR metadata, or user-supplied files as the
source of truth. If the target is ambiguous (e.g. "explain this change" with several
candidate diffs in view), infer the most likely one from context and state the
assumption up front rather than blocking on a question — this skill is usually invoked
mid-flow and shouldn't interrupt momentum for something recoverable.

### 2. Explore before explaining

Investigate the surrounding system, not just the changed lines: related tests, callers,
data models, configuration, and documentation. Trace the old and new code paths far
enough to explain *behavior*, not merely file-by-file edits. Prefer checked-in examples
and tests over speculation — if you can't verify a claim from the source, mark it as
interpretation rather than fact.

### 3. Build the narrative

Work out these five things before writing anything for the reader:

- what problem or constraint motivated the change;
- how the old system behaved;
- the smallest useful mental model of the new behavior;
- how the implementation realizes that model;
- edge cases, trade-offs, and observable consequences.

This narrative is shared by both output modes below — do this once.

### 4. Ask which output mode the reader wants

Ask the user (unless they already said which they want): a **self-contained HTML
page** they can open and click through at their own pace, or a **live quiz in the
chat** where you ask one question at a time and react to their answer immediately.
Both modes use the same narrative and the same five questions — only the delivery
differs. The user can also ask for both.

- For the HTML page, read `references/html-report.md` for the full page structure,
  diagram patterns, and quiz-embedding rules.
- For the live chat quiz, read `references/live-quiz.md` for how to pace questions,
  give feedback, and wrap up.

### 5. Design the five quiz questions once, reuse for either mode

Regardless of delivery mode, the quiz is five medium-difficulty multiple-choice
questions built from the same rules — write them before branching into a mode so both
paths stay consistent:

- Ask about behavior, causality, contracts, edge cases, or trade-offs introduced by the
  change — never trivia that only tests whether the reader memorized a copied phrase.
- Every distractor must be plausible and tied to a real misunderstanding of the change
  (e.g. "the old default still applies here" when it doesn't). Avoid joke answers,
  obviously impossible claims, and "all/none of the above."
- Keep options comparable in length, grammar, specificity, and confidence — don't let
  the correct option be conspicuously longer or more hedged than the distractors.
  Shorten or enrich distractors as needed so they read as equally confident.
  Reader should not be able to guess by which option merely sounds most careful.
  Vary which position (1st, 2nd, 3rd...) holds the correct answer across the five
  questions so there's no positional pattern.
- Write the explanation for each option now (both why the correct one is right and the
  misconception behind each wrong one) — you'll need this whether you're revealing it
  in HTML/JS or saying it out loud in chat.

## Reference files

- `references/html-report.md` — read this when the reader wants (or you default to) a
  self-contained HTML deliverable: page structure, diagrams-without-ASCII-art rules,
  code block escaping, and how to embed the quiz so it works offline with no
  positional or styling tells.
- `references/live-quiz.md` — read this when the reader wants the quiz asked live in
  the chat: pacing, one-question-at-a-time delivery, immediate feedback, and how to
  summarize the score at the end.
