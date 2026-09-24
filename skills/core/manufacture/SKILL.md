---
name: manufacture
description: |
  The build half of the pipeline, and the protocol for any non-trivial change. Two modes. ASSEMBLE builds a pack written by /manuf-product-design: validate → plan QA → dispatch each component to the cheapest capable model → fit-check → build QA → adversarial review → gate. SINGLE/LOOP takes a goal + success criteria and runs the same protocol on a change with no pack: Diagnose · Machine into parts · Fit-check both ends · Map couplings · Harden entries · Adversarial-verify · Pressure-test · Gate the ship. SKIP WHEN: pure design with no code yet (/council then /stress-test) or a one-line fix. Triggers: "/manufacture", "assemble the pack", "manufacture this change", "machine this into parts", "is it good enough to ship?", "before claiming shipped", "risky live change".
---

# /manufacture — build a change so it does not drift, and do not call it shipped until adversaries fail to break it

## What this is for

A green test suite proves the code agrees with the tests. It does not prove the change works: mocked tests cannot see the far-off reader of a shared cache key, the external API that behaves differently than the mock, or the input that reaches the wrong branch. In one restructure of a production resolver, 1,020 passing tests missed four real bugs; four independent reviewers, each told to break it from a different angle, found all four.

This skill is the ritual that catches them: cut the change into parts that each touch one surface, check each part's fit before and after, map what else depends on shared state, then have adversaries try to break the whole — and only then gate the ship on evidence.

## Two modes

| Mode | Input | When |
|---|---|---|
| **assemble** | a pack at `specs/NNN-feature/` from `/manuf-product-design` | a planned feature; the plan already did Diagnose + Machine |
| **single** / **loop** | a goal + measurable success criteria | a change without a pack; `loop` retries until it ships or hits the iteration cap |

Both modes run as a Claude Code **Workflow** (`workflows/manufacture.js`, installed to `~/.claude/workflows/`). Ask for it by name: *"run the manufacture workflow in assemble mode on specs/003-saved-searches"*, or with `args = { mode:'assemble', pack:'/abs/path/specs/003-saved-searches', cwd:'/abs/repo' }`. For single/loop: `args = { mode:'single', goal:'…', criteria:[{ id:'SC1', check:'npm test', pass_when:'exit 0' }] }`. No Workflow tool in your Claude Code? Run the steps below by hand, in order — the protocol is the point, the script only makes it hard to skip.

## Assemble mode — the gates

| Step | Gate | Mechanism | Stops the line if |
|---|---|---|---|
| **0a** | Pack is structurally complete | `hooks/manuf-pack-validate.sh` | INVALID |
| **0b** | **Plan has no gaps** | `/manuf-design-qa` → stamp `pack/.qa/design-qa.json` | grade < A |
| 1…N | Build each component | dispatched by its `tier` (cheap→Haiku, code/adversarial→Sonnet, native→in-session) | a fit-check is RED |
| **N+1** | **Build matches plan** | `/manuf-qa` → stamp `pack/.qa/manuf-qa.json` | grade < A |
| **N+2** | Adversaries + pressure test | refuter lenses on the real diff | a blocking finding |
| **N+3** | **Production** | `/manuf-qa --env=prod` → stamp A+++ `env=prod` | not A+++ with a live probe |
| **N+4** | Running = built | read the version from the running system | mismatch |

Rules for assemble:
1. **Implement the exported designs only** — read `specs/NNN/design/*` and translate them faithfully. Never re-design, never invent parallel CSS, never skip 0b. If a design file is incomplete, re-export the *same* locked design.
2. **Pass paths, not file bodies**, to executors — they read the spec in their own context.
3. **Fit-check BEFORE and AFTER every component.** RED halts the line. AFTER includes a data check: grep for dummy/placeholder values on production paths → RED.
4. **A red check means the plan is wrong** — halt and fix the pack with `/manuf-product-design`. Assemble never patches the plan.

Stamps are written by the QA skills and read by the workflow — `hooks/manuf-qa-stamp.sh check <design-qa|manuf-qa> <pack> --min=A`. A grade in chat without a stamp does not open a gate.

| Symptom | Root cause | Fix |
|---|---|---|
| Built UI ≠ the design | specs never bound to `design/`; hand-rolled CSS | export mocks into the pack; rebuild from it |
| Dummy values in production | fake numbers in the contract; no STOP on `NEEDS_LIVE_WIRE` | wire the real source; ban dummy tokens |
| Assemble re-generated designs and drifted | wrong step | implement the exported files only |

## The ritual — every step, in order (single/loop mode, and the back half of assemble)

**Diagnose · Machine · Fit-check · Map couplings · Harden entries · Adversary · Pressure-test · Gate the ship.**

1. **Diagnose** — hypothesis → trace the fix in your head → verify against the REAL files → propose. Before fixing a reported gap, prove it is real by reading the code that supposedly has it (a *phantom gap* is a fix for a non-bug).

2. **Machine into parts** — each part owns ONE surface. Per part: `FUNCTION · BOUNDARY (owns / must-not-touch / must-preserve) · PLACEMENT (file:line)`. One commit per part; never bundle two surfaces.

3. **Fit-check both ends** — per part:
   - BEFORE: read the real slot, confirm interfaces and types match the spec. Reality ≠ spec → fix the spec first.
   - AFTER: builds clean · its own tests green · FULL suite green, and the test count moved by exactly the tests you added · a diff confined to the part's files. A failed AFTER stops the line.

4. **Map couplings** — before touching shared state (DB, cache, external API, in-memory), table it: `state · SET by · READ by (far-off too) · what breaks if it stops being set`. Make the breakage impossible by structure where you can; otherwise name it and test it.

5. **Harden entries** — every branch REJECTS inputs meant for other branches, not just accepts its own. Two layers: ordering AND a per-branch guard — an upstream classifier will mislabel something eventually.

6. **Adversarial-verify** — the load-bearing step. Run N reviewers, each with a different lens, reading the REAL code and trying to break it. **Pick lenses by how this change can fail**, not N copies of "review this". Use cheaper models for the reviewers (`/delegate`); a **different model family** as one reviewer catches what your own family shares as a blind spot.

   ```js
   // Workflow script — adapt the lenses to the change
   const SCHEMA = { type:'object', additionalProperties:false, properties:{
     lens:{type:'string'}, breaks:{type:'boolean'},
     findings:{type:'array', items:{type:'object', additionalProperties:false, properties:{
       severity:{type:'string', enum:['CRITICAL','HIGH','MEDIUM','LOW','NIT']},
       file:{type:'string'}, line:{type:'integer'}, claim:{type:'string'}, repro:{type:'string'} },
       required:['severity','claim','repro'] }},
     summary:{type:'string'} }, required:['lens','breaks','findings','summary'] }
   const base = `Adversarially review <CHANGE> in <REPO>. Diff: git diff <BASE>.
   Read the real code (file:line). Find a CONCRETE way it breaks: file:line + reproducing input.
   Default skeptical. breaks=false only if you genuinely cannot.`
   const lenses = [ /* choose the ones that fit */
     {key:'mutation',  prompt:`${base}\nLENS=MUTATION: does it change state the live path later reads?`},
     {key:'exception', prompt:`${base}\nLENS=EXCEPTION-SAFETY: can a throw escape into the live path? can the catch itself throw?`},
     {key:'control',   prompt:`${base}\nLENS=CONTROL-FLOW: does it change WHEN or WHETHER a live step runs? ordering, finally, early return?`},
     {key:'coupling',  prompt:`${base}\nLENS=COUPLING: does it break a far-off reader of shared state (a cache or DB key)?`},
     {key:'overclose', prompt:`${base}\nLENS=FOREIGN-INPUT: can an input meant for another branch reach this one through a mislabel?`},
     {key:'api-real',  prompt:`${base}\nLENS=API-SEMANTICS: does the external API ACTUALLY do what the code assumes? (the thing tests mock)`},
   ]
   const v = await parallel(lenses.map(l => () => agent(l.prompt, {label:`refute:${l.key}`, schema:SCHEMA, model:'sonnet'})))
   return { verdict: v.filter(Boolean).every(x=>!x.breaks)?'HOLDS':'HAS A HOLE',
            findings: v.filter(Boolean).flatMap(x=>x.findings||[]) }
   ```

   **Triage honestly:** real → fix it, add a guard (a test or check that fails if it returns), re-verify with the exact attack · false positive → say why, with evidence · **cannot be decided from code** (external runtime) → tell the user, with a live-check recipe. Never assert it is fine.

7. **Pressure-test** — run `/stress-test` on the assembled change. Iterate until the single best reason it fails is a tradeoff you chose and wrote down.

8. **Gate the ship** — only after the QA stamps pass their floors. Then prove the running system is the code you built: read the version from the health endpoint or the running container, not from git on your disk. "Works with fixtures" is not a merge gate and not a deploy gate.

## Examples

- **"Restructure the resolver into one module"** → nine part-specs (one surface each), fit-check before and after each with a no-drift commit, map the shared cache keys, adversarial lenses on each live switch-over, then prove the running version. The adversaries found four bugs 1,020 tests missed.
- **"Is the nightly re-open job safe to deploy?"** → the `api-real` lens asks "does the vendor API actually re-open a closed conversation when sent this status?" That cannot be decided from code → tell the user, with a one-off live check to run, instead of shipping it as proven.
- **"Add an auto-close branch for survey replies"** → harden entries: can a complaint phrased like a survey reply reach the close branch? Ordering AND an exact-match guard, then the foreign-input lens before going live.

## Troubleshooting

- **A reviewer found a "bug" that is not real.** Reproduce its `repro` against the actual code. False positive → say why and move on; fixing phantom findings is its own anti-pattern.
- **A finding cannot be verified from code.** Flag it with an exact live check and a signal to watch. Do not claim either way.
- **The full test count moved by more than the tests you added.** Something else moved — a regression or a shared-fixture leak. Stop and find it before the next part.

## Related

- `/manuf-product-design` — writes the pack assemble builds
- `/manuf-design-qa` (plan QA, before assemble) · `/manuf-qa` (build QA, before merge and before prod)
- `/delegate` — cheaper models for executors and reviewers · `/stress-test` · `/council` · `/spec`
- `hooks/manuf-pack-validate.sh` · `hooks/manuf-qa-stamp.sh` · `hooks/claim-vgate.sh` (blocks "deployed" claims with no evidence)
- `workflows/manufacture.js` — the protocol as a Workflow script
