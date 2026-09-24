---
name: manuf-design-qa
description: |
  Plan-side QA for a manuf-product-design pack BEFORE assemble or merge of the pack PR. Reads PRD, PR-FAQ, TASTE-BRIEF, the exported design/, ui-flow, architecture (HLD), lld, components, risks, verification, manifest. Finds gaps in the plan itself: missing screens, design not cited in HLD/LLD, components that don't implement mocks, dummy data without STOP, incomplete journeys, incoherent DAG, verification recipes missing design/data checks. Use when: "/manuf-design-qa", "QA the design pack", "gaps in the plan", "is the pack ready to assemble", "design pack review", after product-design before `/manufacture assemble`. SKIP WHEN: code already built (use manuf-qa) or no pack yet.
---

# /manuf-design-qa — plan gaps in the manuf pack (pre-assemble)

## What this is for

A pack can pass the structural validator and still have holes: a journey with no screen, an architecture that never cites the design, a component that builds UI nobody drew. Those holes become improvised code at assemble time. This skill reads the whole pack and grades the plan itself, before anything is built. `manufacture assemble` will not start below grade A.

> **Plan-side** complement to `manuf-qa` (build/runtime). Answers: **is the pack complete and coherent enough that assemble cannot invent UI or dummy data?** Mechanical structure is `manuf-pack-validate.sh`; this is judgment on **gaps in the plan itself**.

**Progressive load:** gap tables → [`references/gap-checks.md`](references/gap-checks.md). Output/stamp/rubric → [`references/output-and-grades.md`](references/output-and-grades.md).

## When manufacture/product-design must call this

| Caller | When | Gate |
|---|---|---|
| `manuf-product-design` | After pack written + `manuf-pack-validate.sh` VALID, **before** pack PR / handoff | HARD — do not say "ready to assemble" on grade &lt; A |
| `manufacture assemble` | **Step 0** before any component dispatch | HARD — HALT if grade &lt; A |
| Human | Reviewing a pack PR | default |

## Input

- Pack path: `specs/NNN-feature/`
- Optional: earlier packs in the same repo, for the seam check (gap check 6)

## Procedure (order fixed)

### 0. Mechanical baseline

```bash
bash ~/.claude/hooks/manuf-pack-validate.sh specs/NNN-feature
```

INVALID → overall **F**; list errors; stop (do not grade softer layers as PASS).

### 1–6. Gap checks

**Read** [`references/gap-checks.md`](references/gap-checks.md) and run checks 1–6. Stay plan-focused (not code).

### Output + stamp

**Read** [`references/output-and-grades.md`](references/output-and-grades.md). Emit report, then **always**:

```bash
bash ~/.claude/hooks/manuf-qa-stamp.sh write design-qa specs/NNN-feature <GRADE> --notes='session-summary'
bash ~/.claude/hooks/manuf-qa-stamp.sh check design-qa specs/NNN-feature --min=A
```

Stamp: `specs/NNN-feature/.qa/design-qa.json`. Assemble HALTs without ≥ A.

## Guards

1. **Read the pack files** — no memory scoring.  
2. **Gaps in the plan, not the code** — if code diverged, note "also run manuf-qa".  
3. **HALT is a feature** — better than assembling a hole.  
4. **Smallest re-plan** — fix specific missing mock/component/SC.  
5. **Stamp or it didn't happen** — chat grade without `.qa/design-qa.json` does not open assemble.

## Related

- `manuf-product-design` · `manufacture` · `manuf-qa`  
- `hooks/manuf-pack-validate.sh` · `hooks/manuf-qa-stamp.sh` · `workflows/manufacture.js` (reads the stamp at assemble start)
