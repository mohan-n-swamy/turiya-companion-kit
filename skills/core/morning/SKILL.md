---
name: morning
description: Interactive morning planner for a daily-note practice. Run on demand when the user says "/morning", "plan my day", or "what's on today". Reads today's and yesterday's daily notes from a folder of markdown notes (one note per day), proposes a Top 3 with reasoning, and surfaces the decisions the day actually needs. Assumes nothing beyond plain markdown files.
---

# /morning

Interactive daily planning layer. Runs on demand. Assumes only this: **a folder of markdown notes with one daily note per day**, named by date (e.g. `daily/2026-08-02.md`). No plugins, no specific app, no automation required.

> Optional: automate the boring half with your OS scheduler — a small script that pre-creates today's note from a template and pulls in your calendar before you wake up. This skill works with or without it; it only adds the reasoning layer.

## When to use

- User says `/morning`, "plan my day", "what's on today", "help me start"
- First session of the day, before diving into work

## Read these first (in order)

1. **Today's daily note** — if it doesn't exist, create it with a minimal scaffold:

   ```markdown
   # YYYY-MM-DD

   ## Top 3

   ## Notes
   ```

2. **Yesterday's daily note** — scan for unchecked `- [ ]` items and unfinished Top 3 entries (carry-forward candidates). If missing, skip silently.

3. **Any calendar or task source the user maintains** — only if it's already in the notes. Don't invent meetings or tasks that aren't written down.

## What you add (two sections)

### Top 3 proposal (approve / edit / reject)

Propose 3 items, each as a checkbox task:

```markdown
## Top 3 proposal

- [ ] <highest-leverage item, derived from carry-overs + today's commitments>
- [ ] <second>
- [ ] <third>
```

One line of reasoning under the block: *"Proposed because: X carried from yesterday, Y has a hard deadline today, Z unblocks the week's goal."*

If the user's `## Top 3` is already filled, treat yours as an alternative proposal — don't overwrite. Reference their Top 3 and comment on whether it's the right shape (three genuinely-highest-leverage items, not three easy ticks).

### Asks for Decision

From the carry-overs and anything the user mentions:

```markdown
## Asks for Decision

1. **<stalled item>** — stuck N days. [nudge / reassign / drop?]
2. **<meeting today>** — no agenda. [draft one / ask organizer / skip?]
3. **<open question>** — <1-line implication>. [respond / defer / delegate?]
```

Cap at 5 items. Choose ones that actually require the user's input today, not just "things exist."

## Rules

- **Don't auto-reply** to anything. Asks are proposed; the user acts.
- **Don't overwrite** a pre-filled `## Top 3` — add a separate `## Top 3 proposal` section.
- **Don't invent data.** If there's no calendar in the notes, don't guess at meetings.
- **Idempotent** — if `## Top 3 proposal` already exists from an earlier run today, add a new block marked `(refresh HH:MM)` below it; don't edit the prior one.
- **Three means three.** The whole value of Top 3 is the ranking pain. Never propose five.

## Related

- `/nightly` — interactive evening closer (mirror of this skill)
- `/triage-inbox` — drain the capture inbox; pairs well as a morning sub-step
