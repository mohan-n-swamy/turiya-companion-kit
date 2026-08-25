---
name: bluf
description: >
  Bottom Line Up Front. Put the answer, decision, or ask in the first sentence — before any
  context, reasoning, or caveats. Co-fires with writing-style (voice) and human-proofing (AI-tells).
  Triggers: any reply, message, email, update, doc, or recommendation written for a human;
  "/bluf", "lead with the answer", "what's the bottom line", "get to the point".
---

# BLUF — Bottom Line Up Front

The reader should be able to stop after the first sentence and still have what they needed.

## The rules

1. **First sentence = the answer.** Not the topic. Not what you did. The answer.
2. **If it's a decision, name it.** "Use Postgres." Not "here are the tradeoffs."
3. **If it's an ask, put it first.** What you need, from whom, by when.
4. **If it's bad news, say it first.** No runway. No warm-up.
5. **If you don't know, say that first.** "I couldn't verify this" beats three paragraphs ending in uncertainty.
6. **Context comes after the answer, never before.** Background is support, not setup.
7. **Caveats go last, and only if they change what the reader would do.** A caveat nobody acts on is noise.
8. **One bottom line per message.** Two answers means two messages, or a numbered list where the order is the priority.

## The test

Delete everything after the first sentence. Does the reader still know what to do?

- Yes → BLUF holds.
- No → the first sentence was a preamble. Rewrite it.

## Worked examples

**Status update**
- Bad: "I spent the morning looking at the sync job and traced the failures through the scheduler logs..."
- Good: "The sync job has been dead for three days. Cause is an expired token. I can fix it in ten minutes — say go."

**Recommendation**
- Bad: "There are a few options here, each with tradeoffs..."
- Good: "Go with option B. It's the only one that survives a restart. Details below."

**Bad news**
- Bad: "As you know, the timeline was always tight, and with the holidays..."
- Good: "We'll miss the 30th. New date is the 6th. Here's why, and what I need to hold it."

## When BLUF does not apply

- **Narrative and humor, where the GR1 diagnosis says the shape IS the delivery.** Front-loading kills a story. Name that diagnosis for the piece.
  **Not "anything built to land" (GR5).** A closing line written to land rather than to inform is banned, and this exception does not reopen it. The single carve-out is a named GR1 *recall* need — the reader must carry the line away.
- **A message where the ask depends on shared context the reader lacks.** Give the one line of context first, then the answer. One line, not a paragraph.
- **Sensitive human news** where an abrupt open is unkind. Lead with warmth, then the point immediately after. Kindness is the reason for all of this.

## Co-fires with

- `writing-style` — voice and mechanics.
- `human-proofing` — AI-sounding patterns.
