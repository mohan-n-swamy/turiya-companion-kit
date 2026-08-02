---
name: session-ladder
description: "Session continuity as a three-rung ladder — /park (quick context switch: stamp where you are), /resume (pick up the freshest stamp and continue), /wrap-up (job done: update the docs to final state and close). Use when leaving work mid-flight, returning to parked work, or finishing a piece of work cleanly. Triggers: '/park', '/resume', '/wrap-up', 'park this', 'pick up where we left off', 'wrap this up'. State lives in plain files under .session/ — no scripts, no external tools."
---

# Session Ladder — park / resume / wrap-up

Context dies with the session. The ladder is the discipline that makes work survive it: every pause writes a **stamp** (a small resume file), every return reads the freshest stamp, and every finish rebases the real docs so the stamps can retire.

Three rungs, by weight:

| Rung | When | What it does |
|---|---|---|
| **/park** | Leaving mid-flight (interruption, end of day, context switch) | Write a resume stamp. 2 minutes, then go. |
| **/resume** | Returning to parked work | Read the freshest stamp, brief the user, continue. |
| **/wrap-up** | The job is DONE | Update docs/README to final state, note follow-ups, close the session dir. |

The test of a good park: **a stranger (or you in three weeks, or a different AI session) can continue the work from the stamp alone.**

## State layout

All state is plain markdown in the project:

```
<project>/.session/
└── <slug>/            # one dir per workstream, e.g. auth-refactor/
    └── resume.md      # the stamp — overwritten on every park
```

`<slug>` = short kebab-case name of the workstream. One workstream, one dir. Add `.session/` to `.gitignore` if you don't want stamps in history; commit it if you work across machines — your call, either works.

## /park — write the stamp

1. Determine the slug (ask if ambiguous; reuse the existing dir if this workstream was parked before).
2. Write `.session/<slug>/resume.md` from the template below. Overwrite the old stamp — the git history / your memory is not the stamp's job; *continuability* is.
3. If there are uncommitted code changes, say so in the stamp (and ideally commit to a WIP branch first).
4. Confirm in one line: `Parked <slug> — next: <first next-step>`.

### The stamp template

```markdown
# resume: <slug>
date: YYYY-MM-DD HH:MM

## Objective
<one sentence — what this workstream is trying to achieve, and how you'll know it's done>

## Where things stand
<2-5 bullets — what's DONE (verified, not hoped), what's half-done, key file paths touched>

## Next steps (in order)
1. <the very next concrete action — specific enough to start cold>
2. <then this>
3. <then this>

## Blockers / open questions
<anything waiting on a person, a decision, or an unknown — or "none">

## Context a stranger needs
<the 2-3 things that are obvious to you right now and will be obvious to nobody in two weeks:
gotchas found, approaches already rejected and why, where the bodies are buried>
```

Every section is mandatory. "Context a stranger needs" is the one people skip and the one that saves the resume — rejected approaches especially, or the next session re-walks the same dead ends.

## /resume — pick up the stamp

1. List `.session/*/resume.md`, sorted by the `date:` line (freshest first). If the user named a slug, use that one; otherwise offer the freshest and mention the others.
2. Read the stamp. Verify its claims cheaply before trusting them — `git log`/`git status` since the stamp date, a quick look at the named files. The stamp says where things stood; the repo says where things stand. Flag drift ("stamp says X done, but the file doesn't exist").
3. Brief the user in ≤6 lines: objective · where things stand · proposed next step · blockers.
4. On confirmation, continue the work from "Next steps" item 1.

Never start re-planning from scratch when a stamp exists — that's the failure the ladder prevents.

## /wrap-up — job done, close it out

Wrap-up is not a bigger park. Parking preserves *in-flight* state; wrap-up retires it:

1. **Verify done means done** — run the affected flow / tests; don't wrap on "should work."
2. **Rebase the durable docs** — update README / docs / comments to describe the FINAL state (not the journey). The knowledge moves from stamp to docs; docs are for strangers, stamps were for you.
3. **Harvest the leftovers** — anything from "Next steps" or "Blockers" that's still real becomes a tracked follow-up (issue, TODO note, task line) — not silently dropped.
4. **Capture lessons** — if the work surfaced a non-obvious lesson, run `/capture-lesson`.
5. **Close the session dir** — delete `.session/<slug>/`, or rename `resume.md` → `done.md` with a one-line outcome if you like a paper trail.
6. Commit if the user wants the final state committed.

## Rules

1. **One stamp per workstream, overwritten.** A pile of dated stamps is an inbox nobody drains.
2. **Stamps are for continuation, docs are for truth.** Never let a stamp substitute for updating the real docs at wrap-up.
3. **Verify on resume.** The repo outranks the stamp when they disagree.
4. **Park cheap, wrap thorough.** If park takes more than a few minutes it won't happen; if wrap-up is skipped the docs rot.
5. **No tooling dependencies.** Plain files only — this must work on any machine, any setup, day one.
