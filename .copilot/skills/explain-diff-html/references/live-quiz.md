# Live chat quiz mode

Deliver the same narrative (background, intuition, code walkthrough) as normal
conversational explanation in the chat, then run the five-question quiz as a real
back-and-forth instead of a document the reader clicks through alone. The point of
this mode is pacing and honest feedback — don't let the reader skim past a wrong
answer.

## Explaining before quizzing

Walk through background → intuition → code as plain prose and short code excerpts in
the chat (use `pre`/code fences, precise file/line references, small before/after
comparisons where useful — same content as the HTML mode, just delivered as
conversation rather than a page). Keep it concise enough to read in a chat window;
lean on follow-up questions rather than dumping everything at once if the change is
large or the reader seems to want to go slower.

Tell the reader up front, briefly, that a five-question quiz follows so they know to
read actively.

## Running the quiz

- Ask **one question at a time**. Present the question and its (shuffled) options,
  then stop and wait for the reader's answer — do not reveal the answer or move to the
  next question until they respond.
- Shuffle option order per question exactly like the HTML mode: don't let the correct
  answer fall into a fixed or guessable position across the five questions, and keep
  option wording comparable in length and confidence so nothing gives it away.
- After the reader answers, immediately say whether they got it right, then explain
  *why* — the actual behavior or code path that makes the correct option correct, and
  if they picked a distractor, name the misconception it represents so the wrong
  answer is also a learning moment, not just a "no."
- If the reader asks a clarifying question mid-quiz instead of answering, answer it,
  then re-present the same question before continuing — don't silently skip ahead.

## Wrapping up

After the fifth question, give a short summary: how many they got right, and if any
were missed, a one-line callback to the concept behind each miss (not just "you got
2/5" with no follow-up). Offer to re-explain any part of the change that tripped them
up, or to generate the HTML version too if they'd like a reference to keep.
