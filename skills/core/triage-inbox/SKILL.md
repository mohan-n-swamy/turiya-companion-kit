---
name: triage-inbox
description: Drain a capture-inbox folder interactively. Per Andy Matuschak's "inboxes only work if you trust how they're drained." For each captured note, present a 2-line summary + ask [E]vergreen / [T]ask / [K]ill / [S]kip, then route to a durable home or trash. Triggers on "/triage-inbox", "drain capture", "process inbox", "what's in my inbox". Run daily (ideally as part of /morning) or on demand when the inbox feels heavy.
---

# /triage-inbox — drain the capture inbox

> Matuschak: *"Inboxes only work if you trust how they're drained."*
>
> If you capture faster than you triage, the inbox becomes a graveyard and you stop trusting it — which kills the capture habit itself. This skill is the drain.

Assumes only this: **a folder where quick captures land** (call it `inbox/`, `capture/`, whatever your notes use) and durable destination folders for the stuff worth keeping.

## First run

On first use, ask the user where their daily notes and capture inbox live (suggest `~/notes/daily/` if they have no preference). Record the answer — at the top of the daily note or in their CLAUDE.md — so subsequent runs don't re-ask. No inbox folder yet? Create `inbox/` next to your daily folder.

## When to invoke

- User says `/triage-inbox`, "drain capture", "process inbox", "what's in my inbox"
- As part of `/morning` (ideal — daily cadence)
- When the inbox count grows past ~10 (signal the queue is growing faster than the drain)

## Execution

### Step 1 — Inventory + sort

List the inbox folder's files sorted by modification time, **oldest first** — oldest stuff drains first, preventing "always triage the latest, oldest rots."

### Step 2 — Per-file decision loop (interactive)

For each file (cap at 10 per session — decision fatigue is real; don't try to drain 50 in one go):

1. **Show a 2-line summary**: filename + first 2 lines of content (or for non-text: file type + size).
2. **Ask the user**: `[E]vergreen / [T]ask / [K]ill / [S]kip`
3. **Route per answer**:
   - **E (Evergreen)**: ask "destination?" — suggest one based on content (your reference folder, notes garden, or topic folder). Move the file there.
   - **T (Task)**: ask "context?" (project / person / today's daily note). Append as `- [ ] <one-line summary>` to the target note. Trash the original.
   - **K (Kill)**: move to a trash folder (e.g. `.trash/`) — recoverable, never `rm`.
   - **S (Skip)**: leave in place; note it so it isn't re-asked this session.

### Step 3 — Log the drain

Append one line to a running log note (or the daily note):

```
YYYY-MM-DD HH:MM — triage-inbox: <N> evergreen / <N> task / <N> kill / <N> skip
```

### Step 4 — Drain-rate health

After the session, report:
- Started: <N> files in the inbox
- Drained: <N> (E + T + K)
- Remaining: <N>
- If the inbox has grown for a week straight, surface it: "inbox growing faster than it's drained — capture rate too high or drain cadence too low?"

## Rules

1. **Cap at 10 files per session.** Decision fatigue kills the drain.
2. **Skip is a valid answer.** Don't force a decision when context is missing — but note it.
3. **Never auto-classify.** This is a discipline skill, not an LLM classifier. The user's decision IS the value.
4. **Trash, never `rm`.** Keep kills recoverable.
5. **Append to the log, never overwrite.**
6. **Oldest first.** Don't let recency bias starve old items.
7. **One file at a time.** Each file gets its own decision moment; don't batch the prompt.

## Anti-patterns

- Letting the inbox grow indefinitely on the assumption "I'll get to it"
- LLM auto-classifying — defeats the discipline; the value of triage IS the moment of decision per item
- Reading every file in full before deciding — the 2-line summary IS the cue; needing more context is a separate read, not the triage
- Mass-deleting — only the per-file decision builds trust in the drain

## Related

- `/morning` — daily entry point; triage-inbox works well as an optional sub-step
- Andy Matuschak, [A writing inbox for transient and incomplete notes](https://notes.andymatuschak.org/A_writing_inbox_for_transient_and_incomplete_notes)
