# HTML report mode

Produce a single long-form HTML page that teaches a reader how the change works,
readable by a beginner while still giving an experienced engineer a concise path to
the changed behavior.

## Output location

Save it as one self-contained HTML file with inline CSS and JavaScript. Do not depend
on external fonts, CDNs, images, JavaScript packages, or network access. Save it
outside the repository, preferably at `/tmp/YYYY-MM-DD-explanation-<slug>.html`, using
the current date in `YYYY-MM-DD` format. Do not place the deliverable inside the code
repository unless the user explicitly requests that.

Validate the artifact before handing it off: confirm it exists, is a complete HTML
document, contains no external asset dependencies, has working quiz interactions, and
satisfies the code-block and quiz checks below. If practical, open it in a browser or
use a local HTML inspection tool to catch layout or JavaScript errors.

## Required page structure

Include a clear title, a short summary, and a table of contents linking to these
sections in this order:

1. **Background** — Explain only the system needed for the change. Start with an
   optional beginner-friendly mental model, then narrow to the exact components,
   contracts, and prior behavior involved.
2. **Intuition** — Explain the core idea before implementation detail. Use small
   concrete toy inputs and outputs. Show the old and new behavior when comparison
   makes the change clearer.
3. **Code** — Walk through the changes in conceptual groups, ordered by execution or
   dependency flow rather than arbitrary file order. Include precise file and line
   references when available, but do not dump the whole diff.
4. **Quiz** — The five questions designed in the main workflow, embedded as
   interactive multiple choice. Clicking an option must immediately show whether it
   is correct and explain why, including the relevant behavior or code path.

Use smooth transitions, plain language, and precise systems-oriented prose. Explain
jargon on first use. Use callouts for definitions, invariants, important edge cases,
and practical consequences. Keep the page readable on phones with responsive CSS. Do
not use top-level tabs; make it one continuous page.

## Diagrams and examples

Use a small, reusable set of HTML/CSS diagram patterns rather than ornamental
graphics:

- flow diagrams for requests, data, or control flow;
- before/after panels for changed behavior;
- labeled component cards for system boundaries;
- compact tables for mappings, invariants, and toy data.

Never use ASCII diagrams. Build diagrams with semantic HTML elements and CSS. Label
arrows and include example values whenever the diagram describes data movement. Add
accessible text or a caption so the explanation does not depend on visual inspection
alone.

## Embedding the quiz so it works offline and can't be gamed visually

- Randomize the option order independently for each question. Do not always place the
  correct answer first, second, or in any fixed position. A deterministic shuffle with
  a per-page seed is acceptable; the visible order must vary across questions.
- Balance correct-answer positions across the five questions as evenly as possible.
  Never let position, letter, punctuation, or a repeated pattern reveal the answer.
- Keep the correct answer and explanation in the page's JavaScript data or DOM so the
  interaction works offline. Reveal feedback only after selection. Mark the selected
  option and explain both the right reasoning and, when useful, the misconception
  behind the distractors.
- Ensure the UI does not expose the answer through styling before selection, DOM
  labels, `title` attributes, source ordering, or accessibility text. Accessibility
  labels should describe the option, not its correctness.

## HTML and code-block constraints

- Escape user/code-derived text for HTML and JavaScript contexts. Preserve meaningful
  whitespace in code examples.
- Use `<pre><code>...</code></pre>` for code blocks. The CSS for `pre` must explicitly
  include `white-space: pre` or `white-space: pre-wrap`; verify every code block in
  the saved source before delivery.
- Keep JavaScript small, namespaced, and dependency-free. Use event listeners rather
  than inline handlers when convenient, and handle repeated quiz cards without relying
  on fragile global selectors.
- Include visible focus states and sufficient color contrast. Do not make correctness
  depend on color alone.
- Avoid claiming behavior that the inspected source does not support. Distinguish
  observed facts from reasonable interpretation.

## Final handoff

Return the exact absolute path to the generated HTML file as a clickable local-file
link. Briefly state what was inspected and any assumptions or validation limitations.
