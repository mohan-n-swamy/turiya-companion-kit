---
name: capture-lesson
description: Capture a reusable lesson when the user says "/capture-lesson", "remember this", "save this lesson", or after a bug fix, debugging session, incident, or non-obvious failure pattern. Appends a numbered, append-only lesson entry to the project's lessons file and checks for recurring categories.
---

# /capture-lesson

Capture an incremental learning after a bug fix, debugging session, or production incident — so the same lesson never has to be learned twice.

## When to Use

- After fixing a bug (especially production bugs)
- After a debugging session that revealed something non-obvious
- After discovering a pattern that caused problems
- After a production incident or near-miss
- When the user says "remember this" about a technical lesson

## Step 1: Gather the Lesson

Ask (or infer from conversation context):

1. **What happened?** — The symptom or failure (1 sentence)
2. **Root cause** — Why it happened (the real "why", not the surface fix)
3. **Fix** — What was done (commit hash if available)
4. **Pattern** — The generalizable lesson (applicable beyond this specific case)
5. **Category** — One of: `logic-bug`, `data-issue`, `config`, `deployment`, `prompt`, `architecture`, `performance`, `security`, `other`

## Step 2: Save to Project Lessons File

Append to `tasks/lessons.md` (create if it doesn't exist; if the repo already has a lessons-file convention elsewhere, use that instead; not in a repo? use `~/notes/lessons.md`) in **GP-NN format**:

```markdown
### GP-NN — [imperative rule, the generalizable lesson]. ([date], [category])
- **Why**: [the incident or measurement — symptom + root cause, 1–3 sentences. Evidence bar: it HAPPENED, not first principles.]
- **Apply**: [concrete steps / checks. Fix commit hash if available.]
```

Rules:
- **NN = max(existing GP numbers in this file) + 1.** Numbering is append-only: never renumber, never repurpose a GP-ID.
- Superseded lesson → mark *Superseded by GP-MM* in place; do not delete or renumber.
- Title is the **imperative rule** (what to do next time), not the symptom.

## Step 3: Cross-Session Memory (optional)

If your setup has a durable memory system (a memory MCP server, a notes vault, a project wiki), save the lesson there too so it's searchable from other sessions. If not, the lessons file is the source of truth — skip this step.

## Step 4: Check for Recurring Patterns

Read the existing lessons file and look for:
- Same category appearing 3+ times → flag as systemic issue
- Same root cause appearing twice → flag as unresolved pattern
- Lessons that contradict each other → flag for review

If patterns found, tell the user:
> "This is the Nth [category] issue. Previous: [list]. Consider a systemic fix."

## Step 5: Confirm

> **Lesson captured.**
> [one-line summary]
> Saved to: tasks/lessons.md

## Attribution

The GP-NN append-only numbering format is adapted from the raw-to-knowledge-playbook project's CONTRIBUTING.md conventions.
