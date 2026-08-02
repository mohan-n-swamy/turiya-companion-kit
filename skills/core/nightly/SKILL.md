---
name: nightly
description: Interactive evening closer for a daily-note practice. Run on demand when the user says "/nightly", "close the day", "wrap today", or "prep tomorrow". Transforms today's daily note — puts "what happened" (Day Summary, Scheduled done, Unscheduled Wins, Pushed out with why) at the TOP, demotes the morning plan to a reference zone below a divider, and seeds tomorrow's note. Assumes only a folder of markdown notes with one daily note per day.
---

# /nightly

Interactive evening closer. Assumes only this: **a folder of markdown notes with one daily note per day**. The skill's job is a structural transform plus narrative reasoning — turning a plan-forward note into a record-forward one before the day ends.

> Optional: automate the deterministic half with your OS scheduler — a small evening script that appends the day's git commits or file changes to the note. This skill works with or without it.

## The two-view model

Same note, same day, evolves in the evening.

- **Morning view (pre-nightly):** open the note → see commitments and plans. Plan-forward.
- **Evening view (post-nightly):** open the note → see what happened. Record-forward. Morning sections still there, demoted to a reference zone at the bottom.

`/nightly` **transforms** the note. It does not just append.

## Step 1 — Read

1. **Today's daily note.** Scan every `- [ ]` / `- [x]` line — tick status determines what's done vs pushed.
2. **Tomorrow's daily note** — note whether it exists (you'll seed it in Step 4).

## Step 2 — Pushed-out Q&A (interactive, mandatory)

For each unchecked task that was expected today, ask the user:

*"Why didn't this land? Rolled to when?"*

Never invent a reason. If the user says "skip", record `_(no reason given)_`. Collect all answers before writing anything — the "why" is the whole value of the evening ritual; a pushed task with no reason is a pushed task you'll push again.

### Block priming (pre-decide tomorrow before closing the laptop)

For each of tomorrow's Top 3 candidates, ask:

1. *"What hour-block tomorrow does this run? (e.g. 08:30-10:00 deep work, 14:00-15:00 admin)"*
2. *"Any pre-decided blocker / dependency? (e.g. wait for X's reply, need Y ready)"*

The point (per Cal Newport-style time-blocking): *you stop worrying about open loops once the lid closes, because you've already decided when they get done.* If the user says "skip block priming" — record it, but flag: `_(block-priming skipped — Top 3 will float)_`.

## Step 3 — Transform today's note

Rewrite the note into this order (never delete content — relocate it):

```markdown
# YYYY-MM-DD

## Day Summary
<1-3 lines of prose: shape of the day, dominant theme, energy if mentioned>

## Scheduled — done
- [x] "<Top 3 item>" — <outcome note>
- [ ] "<Top 3 item>" — see Pushed out

## Unscheduled — also done
- <wins not in the morning plan: bonus clears, unplanned fixes, non-work accomplishments>

## Pushed out — with why
- [ ] <task> — <reason from Q&A>, rolled to <date or "undated (stretch)">

---

## How I started the day (reference)
### Top 3 (as planned)      ← demoted original, verbatim
### Notes                    ← demoted original, verbatim
### <any other morning sections, verbatim>
```

Rules for the transform:
- **Never delete content.** A section that doesn't fit the shape stays where it is, flagged to the user.
- **Don't auto-check tasks.** Only the user ticks.
- **Idempotent.** If `## Day Summary` already exists, append a new summary marked `(refresh HH:MM)` below it — don't re-transform the rest twice.

## Step 4 — Seed tomorrow

Create tomorrow's note if missing (same minimal scaffold as `/morning`). Fill its `## Top 3` with:

- carry-forward items from Pushed out (with their block-primed hour-blocks noted)
- prep items for tomorrow's known commitments

Don't overwrite existing Top 3 entries in tomorrow's note — append, and flag duplicates.

## Step 5 — Close

Present a short confirmation:

```markdown
## Nightly complete — HH:MM

✓ Today transformed: <N> sections moved
✓ Tomorrow seeded: <N> tasks

Day shape: <one line from Day Summary>
Tomorrow's lead: <first carry-forward item>
```

## Weekly carry-forward (optional)

If it's the last workday of the week OR ≥3 items pushed to next week, append the Pushed-out block to your weekly note (if you keep one) under `## Carry-forward`, dated. Append, never replace. If no weekly note exists, ask before creating one.

## Rules

1. **The Q&A comes first.** Reasons are collected from the user, never invented.
2. **Transform, don't just append.** The morning plan gets demoted below the divider.
3. **Never delete content.**
4. **Don't auto-check tasks.**
5. **Idempotent** — safe to run twice.
6. **Weekends don't skip.** Tomorrow's note gets created regardless.

## Related

- `/morning` — interactive morning mirror (proposes Top 3, surfaces decisions)
- `/triage-inbox` — inbox drain; a good pre-nightly step
