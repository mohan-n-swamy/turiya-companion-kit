---
name: manuf-qa
description: |
  Build/runtime QA for the manufacturing pipeline AFTER assemble (and HARD before merge/deploy). Reads pack + built code + optional live env. Scores design fidelity (built vs the exported designs), data wiring (no dummies), execution completeness, performance, UI. Troubleshoots toward A+++ execution. For **plan gaps before assemble**, use **manuf-design-qa**. Triggers: "/manuf-qa", "did manufacture implement the design", "is data wired for real", "pre-prod UI QA", "pre-merge QA", after assemble, before production. SKIP WHEN: pack not built yet (manuf-design-qa) or no pack.
---

# /manuf-qa — A+++ build/runtime QA (post-assemble · pre-merge · pre-deploy)

## What this is for

After assemble, the question is no longer "is the plan complete" but "did the build do what the plan said, with real data". Passing tests do not answer it: a screen can pass every test and look nothing like its design, and a dashboard can pass with fixture numbers that would be wrong in production. This skill compares the built product to the pack layer by layer and stamps a grade. Merge needs A; production needs A+++ with a live probe.

> Complements **`manuf-design-qa`** (plan gaps, pre-assemble) and `manuf-pack-validate.sh` (mechanical). This skill is the **built product** pass: does code/runtime match the locked PRD and the exported designs, with real data, performance, and UI quality?

**Progressive load:** core procedure below. Detail tables → [`references/layers.md`](references/layers.md). Output, stamps, grades, examples → [`references/output-and-grades.md`](references/output-and-grades.md).

**Pairing:**

| Skill | When | Blocks |
|---|---|---|
| `manuf-design-qa` | After pack authoring; assemble step 0 | Assemble / pack merge |
| **`manuf-qa` (this)** | After assemble; before PR merge & prod deploy | Merge / deploy claim |

## When to invoke

| Trigger | Mode |
|---|---|
| After `/manufacture assemble` | **full** (pack + code + runtime if available) |
| Before production deploy | **full** + prod lens |
| "Does the UI match the design?" | **design-fidelity** → load layers 0+2 |
| "Are we using dummy data?" | **data-fidelity** → load layers 0+3 |
| Pack authored but not built yet | **Redirect to manuf-design-qa** |

**Inputs (ask once if missing):** pack path `specs/NNN-feature/` · app root / serve URL · env `local|staging|prod` (default local).

## Procedure (always this order)

### 0. Inventory + plan baseline

```
PACK=specs/NNN-feature/
```

1. Run `bash ~/.claude/hooks/manuf-pack-validate.sh "$PACK"` — must be VALID.  
2. If plan-side grade unknown this session, run **`manuf-design-qa`** (or re-read last report). Plan grade &lt; A → overall max **C**.  
3. Inventory built surfaces for each `ui_screens[].mock`.

### 1–7. Score layers

**Read** [`references/layers.md`](references/layers.md) and run layers **1–7** (or mode subset). Do not invent checks from memory.

### Output + stamp

**Read** [`references/output-and-grades.md`](references/output-and-grades.md). Emit the report template, grade, then **always**:

```bash
bash ~/.claude/hooks/manuf-qa-stamp.sh write manuf-qa specs/NNN-feature <GRADE> --env=local|staging|prod --notes='pre-merge|pre-deploy'
bash ~/.claude/hooks/manuf-qa-stamp.sh check manuf-qa specs/NNN-feature --min=A
```

| Gate | Min | Read by |
|---|---|---|
| Merge PR | **A** | `workflows/manufacture.js` Build QA phase · your PR checklist |
| Prod deploy | **A+++** + `--env=prod` | `manuf-qa-stamp.sh check manuf-qa <pack> --min=A+++ --env=prod` before you deploy |

## Guards

1. **Read pack + code** — never score from memory.  
2. **Evidence before grade** — every FAIL has file:line or probe.  
3. **Don't silently re-plan** — surface fixes; user chooses.  
4. **Prod is special** — fixtures-only ≠ A+++ when env=prod.  
5. **Stamp or it didn't happen** — no `.qa/manuf-qa.json` → merge/prod stay closed.

## Related

- `manuf-design-qa` · `manuf-product-design` · `manufacture`  
- `stress-test` · `hooks/claim-vgate.sh` (blocks unevidenced "deployed" claims)  
- `hooks/manuf-pack-validate.sh` · `hooks/manuf-qa-stamp.sh`
