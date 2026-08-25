---
name: spec
description: |
  Scaffold a durable on-disk feature spec (start-with-the-end) — specs/NNN-feature/ with spec.md + plan.md, End-State & Success Criteria first; End-State + Success Criteria filled BEFORE tasks.md (order is discipline; gate hook retired 2026-07-31). For non-trivial multi-session/unattended builds. Triggers: "/spec", "scaffold a spec", "start a feature spec", "new feature spec", "spec this out", "begin with the end".

---

# /spec — scaffold a durable, end-first feature spec

> Implements `design-discipline.md §8` (spec-kit net-adds). The spec is the project-side twin of `/park`: it lives in the repo, git-versioned, readable by any agent across any `/clear`. Begin with the END.

## When to invoke

- Any build spanning **>1 session** or run **unattended** (overnight-build queue, People Desk, voc waves, anything resumed across `/clear`).
- Before generating a task list for non-trivial work.

**Skip** for: surgical 1-file changes, typos, log lines, throwaway scratch (those don't earn the ceremony — same bar as rigor-protocol's trivial-skip).

## The discipline this serves

Discipline (gate hook retired 2026-07-31): never write `specs/<feature>/tasks.md` until the sibling `spec.md` has a populated `## End-State` AND `## Success Criteria`. This skill makes that path the easy path: it scaffolds the spec with those two sections first, derived **backward from the gold artifact** (People Desk method), never forward from tasks.

## Steps

1. **Resolve the feature name** from the user's args → a 2-4-word kebab slug (e.g. `people-desk-tier1`). If none given, ask one short question.
2. **Find the repo root** of the current project (the `claude projects/**` dir you're working in, or cwd). Specs live at `<repo>/specs/`.
3. **Compute the next number**: list `specs/`, take `max(NNN)+1` zero-padded to 3 (`001`, `002`, …). New dir = `specs/<NNN>-<slug>/`.
4. **Write `spec.md`** from the template below. Leave the `[NEEDS CLARIFICATION: …]` placeholders in End-State + Success Criteria — fill them with real content before writing tasks.md (do NOT pre-fill with filler).
5. **Write `plan.md`** from the plan stub below (HOW + stack — filled after the spec is real).
6. **Do NOT create `tasks.md`.** It is gated. Tell the user: fill End-State + Success Criteria first, then run `/spec tasks` (or just write `tasks.md` — the gate will allow it once the spec is real).
7. **Report**: the created paths + the exact next action ("fill `## End-State` and `## Success Criteria` in spec.md, working backward from the ideal finished artifact").

## spec.md template

```markdown
# Feature: <NAME>

**Status**: draft
**Created**: <ISO date>
**Input**: <raw one-line ask from the user>

> WHAT and WHY only — NO tech stack, frameworks, APIs, or code. That lives in plan.md.

## End-State
<!-- The ideal FINISHED artifact. Describe the gold: what exists, what it looks
     like, what a human sees when it's done. Be concrete enough that you could
     diff a real output against it. This is the thing you work backward from. -->
[NEEDS CLARIFICATION: describe the ideal finished artifact (the gold)]

## Success Criteria
<!-- Measurable, technology-agnostic checks that DEFINE done. Derive these
     BACKWARD from the End-State above, not forward from any task list.
     Number them SC-001+. Each must be verifiable. -->
[NEEDS CLARIFICATION: SC-001 … the measurable checks that prove the End-State is met]

## User Scenarios
<!-- Prioritized P1/P2/P3. Each independently testable = standalone MVP.
     Given / When / Then acceptance. -->

### P1 — <story>
- **Given** … **When** … **Then** …

## Requirements
<!-- Functional, numbered FR-001+. "System MUST …" / "Users MUST be able to …".
     Each testable. -->
- FR-001:

## Key Entities (optional)
<!-- Data shape only — attributes/relationships, no implementation. -->
```

## plan.md stub

```markdown
# Plan: <NAME>

**Spec**: ./spec.md
**Status**: draft

> HOW — fill ONLY after spec.md's End-State + Success Criteria are real.

## Technical Context
- Language/version:
- Dependencies:
- Storage:
- Testing framework:
- Target platform:
- Performance/constraints:

## Decisions most likely to change
<!-- LEAD WITH THESE. The choices a reviewer is most likely to tweak: data-model
     shape, type/API contracts, user-facing flows, irreversible calls. One line each,
     highest-uncertainty first. Surfacing these at the TOP means a wrong assumption
     gets caught before the mechanical work is built on it. -->

## Approach
<!-- How the spec's requirements get met. Reference FR-/SC- numbers. -->

## Source Structure
<!-- Concrete paths + rationale. -->

## Complexity / risks
<!-- Anything that fights the four pillars or boundary conditions — justify it. -->

## Mechanical / low-risk (trust the executor)
<!-- BURY the boilerplate refactors, renames, wiring the reviewer won't argue about. -->
```

## Notes

- The split is load-bearing: **spec = WHAT/WHY + End-State + Success Criteria · plan = HOW + stack · tasks = checklist w/ file paths**.
- Do not reach for a spec-kit toolkit (`specify init` and friends). This skill *is* the pattern; a toolkit on top duplicates it.
- Pair with `/stress-test` once the spec is filled (the gate enforces order + presence; stress-test checks quality).

## Examples

**Example 1 — new multi-session build**
> User: `/spec people-desk tier-1 extraction`
> Action: find repo root, see `specs/` has `001-…` → next is `002`. Create `specs/002-people-desk-tier1/spec.md` + `plan.md` from templates. Do not create `tasks.md`.
> Report: "Created `specs/002-people-desk-tier1/{spec.md, plan.md}`. Next: fill `## End-State` (the ideal tracker — e.g. 5 Basava rows matching the gold) and `## Success Criteria` (e.g. SC-001 NOISE precision ≥ 0.9), working backward from the gold. `tasks.md` is gated until those are real."

**Example 2 — trying to skip ahead (the gate fires)**
> Agent fills only the user's ask into spec.md, leaves End-State as `[NEEDS CLARIFICATION]`, then tries to Write `specs/002-…/tasks.md`.
> Rule: define the END before the WORK — fill End-State + Success Criteria, then write tasks.md.

**Example 3 — genuinely trivial change**
> User: "fix the typo in the log line"
> Action: **skip /spec entirely** — surgical 1-file changes don't earn the ceremony.

## Troubleshooting

- **"spec-gate blocked my tasks.md write"** — working as designed. The sibling `spec.md` is missing or its `## End-State` / `## Success Criteria` is empty or placeholder-only (`[NEEDS CLARIFICATION]`, `TBD`, `<…>`). Fill both with real, ≥15-char content, then retry. Genuine scratch spec → user replies `spec-gate-ok` (literal) to bypass for the session.
- **"the gate didn't fire"** — it only matches paths ending `specs/<feature>/tasks.md`. A task list written anywhere else (e.g. `TODO.md`, `tasks/foo.md`) is not gated. Use the `specs/<feature>/` layout to get enforcement.
- **"what number do I use?"** — `max(existing NNN) + 1`, zero-padded to 3. If `specs/` is empty, start at `001`.
- **"plan.md and tasks.md both gated?"** — no, only `tasks.md` is gated. `plan.md` is free (it's downstream of a real spec but the gate doesn't enforce it). Fill plan after the spec's End-State + Criteria are real.

## Related
- `/park` — session-side twin (resume-state.md)
- `/stress-test` — quality gate after the spec is real
