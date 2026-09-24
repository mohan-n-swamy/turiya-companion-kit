---
name: manuf-product-design
description: |
  The planning half of the build pipeline. Use BEFORE any code on a non-trivial build — especially one a cheaper model will type in. Starts with a hard-gated PRODUCT phase: PRD + PR-FAQ iterated WITH you until you say LOCKED, then a taste brief, then real screen designs you lock, exported into the repo. Only then writes a "pack" in specs/NNN-feature/ — architecture, interfaces, and one zero-decision spec per component — that /manufacture assemble builds from. SKIP WHEN: a small change (use /manufacture single) or the pack already exists (use /manufacture assemble). Triggers: "/manuf-product-design", "design pack", "PRD this", "plan this build", "spec this so a cheaper model can build it".
---

# manuf-product-design — author a pack a cheaper model can build without deciding anything

## What this is for

Most bad builds are decided before the first line of code: the goal was fuzzy, the screens were invented while coding, the product turned out wrong after it was built. This skill moves every decision to the front, where it is cheap, and writes them down so the build is typing, not thinking.

It produces a **pack**: a folder `specs/NNN-feature/` holding the product brief, the locked designs, the architecture, and one spec per component so exact that a small, cheap model can execute it. `/manufacture assemble` then builds from the pack, and `/manuf-design-qa` / `/manuf-qa` grade it before and after.

```
/manuf-product-design  →  specs/NNN-feature/  →  /manuf-design-qa  →  /manufacture assemble  →  /manuf-qa  →  merge
   (you + big model)         (the pack)          (plan complete?)     (cheap models type)      (built = planned?)
```

**The core idea: intelligence lives in the plan, not the executor.** (Ousterhout: pull complexity down into the deep module, away from the caller.) The planner absorbs all the design complexity so each component's interface becomes trivially shallow: exact file, verbatim code, exact command, expected output. A component spec is **zero-decision** ("Haiku-proof" — the smallest model could run it) when every choice is pre-made and every check pre-written. If the executor must *decide* anything, the plan failed — split the component smaller.

## The pipeline, in order (each arrow is a gate)

```
PRD + PR-FAQ  LOCKED by you       ⇄  later discoveries write BACK here
        ↓
FLOWS, per stakeholder            (3a — the primary artifact)
        ↓
ENTITIES + SCENARIO MATRIX (3b)   ACTOR CATALOGUES (3c)
        ↓
SCREEN LIST                       (derived from flows — never written directly)
        ↓
TASTE BRIEF                       (design direction, written once, fed to every screen)
        ↓
PROMPT AUDIT                      (check every screen prompt against the pack before generating)
        ↓
SCREEN DESIGNS                    (any design tool; LOCKED by you)
        ↓
export → specs/NNN-feature/design/  (mocks + data contract — not optional)
        ↓
architecture / interfaces / components / ui-flow   (implement design/ faithfully)
        ↓
/manufacture assemble             (builds from the pack only — never re-designs)
```

**Failure modes this kills (each seen shipping to production):**

| Failure | Ban |
|---|---|
| **Designs never land in the repo** | Gate #2 is incomplete until the files exist under `design/` and `manifest.json` `ui_screens[].mock` points at them. A design that lives only in a browser tab = REJECT. |
| **Specs invent their own UI** | Architecture, interfaces and component CODE for any UI surface MUST cite `design/<file>` and implement its structure and tokens. No parallel CSS system invented by the planner. |
| **Design system attached but unused** | If your design tool binds a component library or token set, the prompt must say to use it (use the bound components and tokens, style with the tokens, never guessed hex). Otherwise the generator hand-rolls something that only looks on-brand. Verify the library's files actually appear in the output. |
| **Generation spent on prompts already known to be wrong** | Screen generation is slow and often serial. A prompt defect costs nothing to fix before, and a full re-run after. Audit every prompt against the pack before generating. |
| **Dummy values on production paths** | The data contract uses **real source-of-truth field names** (API path, table, column). A placeholder requires `NEEDS_LIVE_WIRE` + a STOP in its component — never silently shipped. |

## Who plans

Phase 0 always runs in this session, because it needs you. The design half (architecture onward) should run on the **strongest model you have, at maximum effort** — this is the one place where paying for the big model is the whole point, because every decision it makes here is one a cheap model does not have to make later.

Optional: if you have access to another model family (through an MCP router, or another CLI), a second planner can author or critique the pack. The **output contract is identical** whoever writes it — assemble cannot tell and does not care. State the job and the output contract at goal level; enforce granularity on the *deliverable* (the validator), never by micro-scripting the planner's reasoning. Rigid step-by-step prompts make strong models worse.

## Phase 0 — PRODUCT (hard-gated, interactive, before ANY architecture)

The pattern this kills: architecture designed off a fuzzy goal, UI generated during the build, the product discovered to be wrong after components exist. Work backward from the product instead, in four steps — **Impact, Problem, Solution, Prototype** — and hand nothing to engineering without a working prototype.

1. **PRD** — `prd.md`: **§Impact** (what should change: objective and subjective metrics — what moves, what the user feels or does differently) · **§Problem** (evidence and baseline data — who hits it, when) · full functionality · end-to-end flow · non-goals. Nothing downstream may exist that the PRD does not imply.
2. **Solution + PR-FAQ** — prd.md **§Solution** (plain English · minimum user experience · data sources · any AI capability used · what it does NOT do · whether this is a one-off tool or a lasting system) + `pr-faq.md`: a working-backwards announcement and FAQ (customer questions and the hard internal ones).
3. **USER LOCK GATE #1 (forced iteration)** — present PRD + PR-FAQ with AskUserQuestion. At least ONE critique round: surface your own weakest points before accepting approval. Loop until the user explicitly answers LOCKED, then stamp both files with a line `Locked: YYYY-MM-DD by <user>`. **Stamp only on an explicit user lock** — self-stamping defeats the gate. `manuf-pack-validate.sh` rejects an unstamped pack.

3a. **FLOWS FOR EVERY STAKEHOLDER (the FIRST derivation — before entities, before screens).**

   **The flows are the primary artifact. The screen list is derived from them, never the other way round.** A screen list written straight from the PRD narrative covers the moments the narrative mentioned. Flows enumerated per stakeholder cover the work people actually do.

   **Group by stage in the thing's life, not by feature area.** Feature grouping hides gaps because it mirrors how the team is organised; life-stage grouping exposes them because a thing must pass through every stage. A set of eleven groups that has held up:

   > **Acquire · Hold · Service · Software & services · People · Release · Money · Truth · Governance · Push · Observe**

   `Truth` (reconciliation, corrections, sync health, legacy import), `Push` (digests, reminders, send history) and `Observe` (leadership views, catalogues) are the three groups teams almost always omit, because nobody asked for them — they keep the other eight honest.

   **Enumerate per stakeholder.** Walk each actor and ask what jobs they come to do. The same flow reached by two actors is one flow with two entry points — but a job only one actor has is the one most likely to be missed.

   **Two checks, both written into the pack:**
   - **A flow with no screen is a gap.** Something has to carry it.
   - **A screen in no flow is dead weight.** Cut it, or find the flow it serves.

   Expect the count to grow on a second pass: fifty flows became fifty-nine, and the nine were not new scope, they were things nobody had named.

3b. **ENTITY MODEL + SCENARIO MATRIX (before any screen is named).** A narrative-derived screen list is recall, not coverage. Derive it instead, from two artifacts in the pack:

   **`ENTITY-MODEL.md` — stop at each entity.** An entity has its own identity, its own lifecycle, and something else can refer to it. For EACH, answer all four before moving on: (1) what gives it identity · (2) every attribute it NEEDS to exist and be useful · (3) everything it DOES or that happens to it · (4) every STATE it can be in, as a closed list. Then declare **one status model** every entity uses, so no screen improvises its own words: **Provisional · Active · Inactive · Suspended · Archived · Superseded · Purged.** Three rules: *inactive is not archived* (a paused subscription is still owned and counted) · *archived is not deleted* (it still answers what it was, who held it, what it cost) · *renewal makes a chain, never an overwrite* (the old period is superseded and points forward, because "what did we pay last time" is the question at every negotiation).

   **`SCENARIO-MATRIX.md` — generate, do not recall.** Scenarios are the cross-product **ENTITY × PHASE × MODE.** Phases: Acquire · Prepare · Assign · Operate · Move · Recover · Retire · **Archive**. Modes: Normal · Exception · **Correction** · Bulk. Every cell is filled or marked not-applicable **with a reason** — a gap then shows as an empty cell instead of something nobody thought of.

   **Two axes are always forgotten; check them by name.** **Archive** is a phase, not an endpoint: the disposed asset and the departed person keep answering questions. **Correction** is a mode: if state comes from an append-only log, a wrong fact needs a superseding row, and if no screen offers one, the only route is a hand-written database update — the side channel the design exists to prevent.

   Then derive screens from the model: every attribute needs a capture surface and a display surface · every action needs a screen · every state needs something that moves records in and out · every relationship needs a screen that sets it. **Fold into an existing screen before inventing a new one; a screen per action is a failure, not thoroughness.** No two screens may WRITE the same attribute — name the owner; the rest read.

   Prove it with two tables in the pack: a **coverage table** (per entity: which screen captures its attributes and moves its states — nothing missing) and an **ownership matrix** (entity × screen, marked write or read, nothing written twice).

   Worked example (an IT asset-management product): a narrative-derived list of 15 screens became 35 once entities were exhausted, and three entities surfaced that nothing had — **vendor** (a warranty claim needs a counterparty), **contract** (renewal needs something to attach to), **asset model** (without it, "is this model a lemon" cannot be asked).

3c. **ACTOR CAPABILITY CATALOGUES + END-TO-END TRACES (same gate as 3b).** 3b proves every *entity* is represented. It does not prove any *person* can finish a job. An entity gap ships a fact nothing can record; an actor gap ships a product where every screen is defensible and nobody can complete their work.

   **One catalogue per actor**, by role. For each actor list the **capabilities** they exercise ("close the quarter", "decide repair versus replace"), and for each: the **steps in order**, the **screens and services** each step touches, what it **refuses** and why, and what is **blocked or undecided** with an owner. That last field stops a catalogue reading as finished when it is not.

   **Trace every capability end to end across screens.** A capability that needs four screens and has three is a broken journey, invisible from any single screen's spec. The sharpest defect lives here: the screen that owns a write was specified as a read-only view, so the action exists in the model and has no surface anywhere.

   Three checks, all in the pack:
   - **Every capability traces to a screen, and every screen to a capability.**
   - **Every actor can complete every capability inside the product.** Where they cannot, it is a named gap with an owner.
   - **Navigation follows jobs-to-be-done, not the entity list.** Admin sits apart and last.

   Also write down **ladders** (a decision that walks options in order — the rungs, what each reads, what makes it refuse) and one **refusals catalogue** (what the product will not do, why, which service enforces it). Refusals scattered across screens get designed away one screen at a time.

4. **UI design (UI builds only) — taste → design → export** (never skip one):

   **4a. Taste brief.** Before any screen: one line on the design read (genre, tone, audience) plus three dials — **variance** (how far from convention), **motion** (how much movement), **density** (how much per screen). Pre-flight against the generic-AI look: default fonts, purple gradients, invented metrics, em-dashes in UI copy. Write `design/TASTE-BRIEF.md`. If you have a brand (palette, logo files), copy the assets into `design/brand/` and list them in the brief. Never redraw a logo.

   **4b. Screens.** The screen list comes **from 3a–3c, never from the PRD narrative**. One design prompt per screen, **every prompt opening with the taste brief**. Any design tool works: claude.ai/design (the [auteur](https://github.com/pejmanjohn/auteur) CLI drives it from the terminal), Figma, a UI kit, or hand-drawn and photographed. What matters is that a real design exists before code does.

   **4c. USER LOCK GATE #2** — present the screens; iterate until LOCKED. Stamp `ui-flow.md`: `Locked: YYYY-MM-DD by <user>`.

   **4d. Export (mandatory).** Every screen has a file under `design/`. Name the **data-contract** file (e.g. `design/app-data.js`): field names and types plus the **real source** for each (API path, table, column). A value with no live source yet → `"status": "NEEDS_LIVE_WIRE"`, and the owning component STOPs. Never invent production numbers.

   Backend-only work skips 4a–4d. The PRD, PR-FAQ and lock #1 stay mandatory.

Only a locked Phase 0 feeds the design half. **Screens are designed HERE only.** Assemble *implements* `design/`; it never re-designs and never hand-rolls CSS that diverges from it.

## The job (what the planner produces)

From a **locked Phase 0**, the pack in `specs/NNN-feature/` covers the full arc:

1. **Direction + diagnosis** — the WHY. Hypothesis, root need, phantom-gap check (prove any claimed gap is real by citing the actual code, not memory). Design it twice: two approaches, one chosen with the reason.
2. **Architecture** — deep modules (simple interface, powerful implementation), information hiding, boundaries, data flow. Define errors out of existence.
3. **Interfaces** — types, signatures, contracts. The exact shapes each component plugs into.
4. **Parts** — each component owns exactly ONE surface: FUNCTION · BOUNDARY (owns / must-not-touch / must-preserve) · PLACEMENT (file:line). One part = one commit.
5. **UI flow** (product builds) — screens, flow and states, and a map from each screen to its **locked mock** in `design/` and its data contract. **Every ui_screen row lists `mock: design/...` and `data_contract: design/...`, both on disk.**
6. **Fit checks** — per component, the exact BEFORE checks (is the slot what the spec expects?) and AFTER checks (did it seat?).
7. **Coupling map** — every piece of shared state (DB, cache, external API): set by · read by (far-off readers too) · what breaks if it stops being set.
8. **Entry hardening** — each component rejects foreign inputs, not just accepts its own.
9. **Risks** — per component and whole: how it fails · blast radius · mitigation · **detection**. A failure mode with no detector is a future patch.
10. **Execution order** — dependency graph, gates between components, rollback.
11. **Verification** — end-to-end checks, plus a recipe proving the running system is the code you built.

Adversarial review and pressure-testing are NOT done by the planner — it is blind to your live runtime. They run at assemble time. The planner writes the recipes; assemble runs them.

## Design rules the planner applies to every component

- **YAGNI ladder** — each component stops at the first rung that works: (1) does it need to exist · (2) standard library · (3) native platform feature · (4) a dependency already installed · (5) one line · (6) the minimum that works. Record the rung. A new dependency is flagged for review (the kit's `dep-gate.sh` pauses it).
- **Deep modules** (Ousterhout) — simple interface over powerful implementation; design the API so the error cannot occur rather than handling it.
- **Never cut to save lines:** input validation, data-loss handling, security (escape before `innerHTML`; an OAuth token is not an API key; no secrets in logs), accessibility, loud errors.

## The zero-decision component contract

Every `components/CN.md` carries all 7 fields, each as a heading or `LABEL:` line:

| Field | Removes the decision |
|---|---|
| **1. PLACEMENT** — exact `file:line` | "find the right place" |
| **2. CODE** — verbatim before/after, or full file | "write code that does X" — the code IS the spec |
| **3. COMMANDS** — exact build/test/lint strings | "run the tests" |
| **4. EXPECTED** — exact output of each command | judging whether it passed |
| **5. PRECONDITIONS** — what must be true before starting | coding against a wrong slot |
| **6. POSTCONDITIONS** — binary checks | "looks done" |
| **7. STOP** — the halt condition | improvising when something is red |

Plus per component: **tier** (below), **rung**, **deps**. If a component cannot be reduced to these 7 fields with zero freedom, it is too big — split it. `manuf-pack-validate.sh` enforces the labels mechanically.

## Worker tier (which model builds each component)

Each component carries a `tier` in `manifest.json`; `/manufacture assemble` routes by it (see `workflows/manufacture.js`):

| tier | Use for | Default executor |
|---|---|---|
| `cheap` | mechanical edit, boilerplate, rename, config | Haiku subagent |
| `code` | logic, algorithm, standard implementation | Sonnet subagent |
| `adversarial` | security-sensitive, tricky control flow | Sonnet subagent (or another model family through a router) |
| `native` | needs this repo's context across many tool steps | Sonnet in-session |

A zero-decision spec means even the `cheap` tier cannot go wrong — the tier is a cost lever, not a safety net.

## The pack layout (the output contract)

```
specs/NNN-feature/
  prd.md             # Phase 0: impact · problem · solution · flow · non-goals + Locked: stamp
  pr-faq.md          # Phase 0: announcement + FAQ + Locked: stamp
  design/            # Phase 0: locked mocks + TASTE-BRIEF.md + the data contract
  spec.md            # WHAT/WHY + ## End-State + ## Success Criteria
  architecture.md    # modules, boundaries, data flow, design-it-twice rationale
  lld.md             # interfaces and types — uses the data contract's field names verbatim
  manifest.json      # MACHINE CONTRACT — components[] · DAG · tier · order (assemble reads this)
  ui-flow.md         # screens · states · mock↔screen map + Locked: stamp
  components/
    C1.md            # 7 fields + tier + rung + deps
    C2.md ...
  execution-plan.md  # order, gates between components, rollback
  risks.md           # per component + whole: fail · blast · mitigation · detection
  verification.md    # end-to-end checks + "running = built" recipe
```

`manifest.json` shape (assemble parses this, not prose):

```json
{
  "feature": "003-saved-searches",
  "components": [
    { "id": "C1", "surface": "auth middleware", "spec": "components/C1.md",
      "tier": "adversarial", "deps": [], "order": 1,
      "checks": ["npm test -- auth"] }
  ],
  "ui_screens": [
    { "id": "S1", "name": "Login", "mock": "design/login.html", "data_contract": "design/app-data.js" }
  ]
}
```

## Steps

1. **Slug + number** — a 2–4-word kebab slug; `NNN` = highest existing `specs/NNN` + 1, zero-padded.
2. **Author `prd.md` + `pr-faq.md`** (Phase 0 above).
3. **LOCK #1** — AskUserQuestion loop; your weakest points first; stamp only on an explicit LOCKED.
4. **Flows → entities → actors → screens → taste → designs → LOCK #2 → export** (UI builds only).
5. **Diagnose** — read the real code (no memory). Prove each claimed gap. Design it twice. Write `spec.md` End-State + Success Criteria FIRST, from prd.md §Impact.
6. **Architect** — `architecture.md`, then `lld.md`. The interfaces use the data contract **verbatim**. Never re-derive shapes. Never invent a parallel UI system. Name which `design/` file is the visual source for each surface.
7. **Decompose** — one surface per component, all 7 fields + tier + rung + deps.
   **UI component rules:** CODE for any visual surface references its mock (`design/S1.html`) and translates it to your stack — **do not redesign**. Forbidden on production paths: `dummy`, `placeholder`, `sampleData`, `lorem`, `fakeUser`, hard-coded demo metrics, `TODO: wire later` without a STOP. Live data: name the real fetch or query; EXPECTED asserts real values (or an explicit empty state).
8. **Couplings + hardening + risks** — `risks.md`. Always include "design not implemented" and "dummy data in production", each with a detector.
9. **Order + verification** — `execution-plan.md`, `manifest.json`, `verification.md`. verification.md includes a design-fidelity check (built screen vs `design/` mock) and a live-data check (no dummy values on production paths).
10. **No `tasks.md`** — the pack IS the task list.
11. **Validate** — `bash ~/.claude/hooks/manuf-pack-validate.sh specs/NNN-feature` → `VALID`. Never bypass.
12. **Plan QA** — run `/manuf-design-qa` on the pack. It finds gaps *in the plan* (journeys with no screen, architecture not citing design/, components without mock references, verification holes) and stamps a grade. **Grade ≥ A before anyone calls it ready.**
    ```bash
    bash ~/.claude/hooks/manuf-qa-stamp.sh check design-qa specs/NNN-feature --min=A
    ```
13. **Several packs in one repo?** Check the seams by hand before assembling a later pack: every anchor it edits still exists in the code an earlier pack wrote; every status or enum it uses was declared by an earlier pack; no file is edited by many packs without that pack re-running the full earlier test suite. Packs written in sequence drift at exactly these seams.
14. **Commit the pack on its own branch** (stage only `specs/NNN-feature/`, never `git add -A`), push, open a PR. The pack must be in git so a fresh session can assemble it cold.
15. **Report** — the path, the PR, the design-qa grade, and the next command: `/manufacture assemble specs/NNN-feature`.

## Handoff to assemble

The planning session ends here. The pack sits in `specs/NNN/`. Later, a fresh session runs `/manufacture assemble`, reads the pack cold, implements the exported designs, dispatches each component by tier, fit-checks, reviews adversarially, and gates. It **never re-designs**; on a red check it halts and reports, and you fix the pack here.

## The design writes back to the PRD

**A locked PRD is locked, not finished.** Specifying screens and service contracts *discovers* product decisions that more thinking about the PRD would never have surfaced — they only appear when something has to be drawn or a query has to be written.

**Keep a dated revision table at the top of the PRD:** number, date, the decision, and — the column that matters — **what it changes downstream**. The lock stamp stays; revisions accumulate under it. One real pack ran to twenty-three revisions in two days, each a genuine product decision.

What design found that the PRD could not:

| Found while | The revision it forced |
|---|---|
| Modelling entities: nothing held a phone line or a maintenance contract | A new master list had to exist; they were being smuggled into other entities, and both smuggles broke something |
| Writing the depreciation policy | The previous revision's depreciation rule made *every* repair exceed the replace threshold. Arithmetic, invisible in prose |
| Specifying a holder field | "No holder" and "held by the organisation" are different facts; collapsing them silenced the orphan-detection queue on exactly the rows it exists for |
| Writing a service contract | A queue keyed on the wrong state **returns zero rows forever** and looks drained rather than broken |

Three rules:
1. **Propagate every revision the same day.** A revision in the table but not swept through the pack is worse than none: the pack now contradicts itself. One sweep found sixteen files still gating on an overturned rule.
2. **Annotate dated snapshots, never rewrite them.** Keep a quoted source's original text and put the amendment beside it.
3. **A revision that closes an open question closes it everywhere**, including every "undecided" field that named it.

Corollary: "PRD locked" is not permission to stop asking product questions. Design generates them faster than the PRD phase did.

## Prompt audit — before generating a single screen

Generation is slow and often serial; a defect caught in the prompt costs nothing, the same defect caught after costs the whole generation again.

**Audit each screen prompt against the pack, and make every finding survive a second reviewer trying to refute it.** Unrefuted audits inflate: about 1 in 8 claimed defects does not survive, and the biggest source of false positives is **two documents using the same id scheme** (revisions R1..R23 vs reports R1..R23). Make the refuter check which file an id came from.

Five defect shapes, in priority order:

| Shape | Looks like |
|---|---|
| **A contradicts the pack** | The prompt encodes a rule a later revision overturned |
| **B missing a binding rule** | The screen needs it and the prompt does not carry it |
| **C scope drift** | Prompt scope disagrees with the screen list, or omits a write this screen solely owns |
| **D a query that returns nothing** | A queue keyed on the wrong state renders drained instead of broken |
| **E no blast-radius line** | Every prompt opens: `Create ONLY the file "<name>". Do not create, edit or restyle any other file in this project.` |

Cross-file patterns — each is one bug, not N: prompts written against an older revision of the PRD · screens that own writes prompted as read-only views · figures that cannot be known presented as if computable (name the specific figure in the prompt; a generic "be honest about gaps" line does nothing).

**Never bulk string-replace audit fixes into prompts** — audit commentary ("Replace the closing line with:") ends up inside the prompt. Sweep before committing:
```bash
grep -ln '^Replace \|^Insert \|^Add to \|^Apply the\|the auditor\|proposed fix' prompts/*.txt
```
Never audit while the files are still being edited. And say which screens were *examined and clean* versus *never in scope* — silence is not a pass.

## If you generate screens with a browser-driven tool

Lessons from generating dozens of screens through claude.ai/design with the auteur CLI; most apply to any slow, asynchronous generator.

- **The tool returns long before the work is done.** Exit code 0, a "done" banner, a file size or a handoff URL are not evidence — all can appear when nothing was generated.
- **Give it a long timeout** (auteur: `--timeout 1200`; the default is short and real runs take up to 17 minutes). A watchdog that fires kills the generation and leaves no file at all, which looks exactly like a service outage.
- **The server copy is the truth; the local copy is a cache** written before the body exists.
- **Only a size that has stopped growing is evidence** — two reads with the same etag. One screen read 14 KB and finished at 73 KB.
- **When regenerating over an existing file, watch the etag, not the size.**
- **No file at all** → the run was killed; retry with a longer timeout. **A tiny file that never grows while idle** → a genuinely failed generation.
- **One browser window, never killed between screens.** Killing it aborts the previous generation.
- **Record the other files' etags before each run;** unchanged etags afterwards prove the `Create ONLY` line held.

## Design system vs product pack — who wins

> **The design system wins on STYLE. The product pack wins on MEANING.**

Take the system's colour values, type, spacing, components and motion. Take the pack's meaning for what those values signify in this product. Example: a design system used red for below-target, pending and error; the product reserved red for "needs action". Resolution: the system's red, the pack's meaning, and both edges written into every prompt (*waiting is not an issue; old is not an issue*). State the override in the prompt itself — a precedence rule in a separate document does not reach the generator.

## Troubleshooting

- **"The validator rejected my pack"** — it names the field: a component missing one of the 7 labels, a risk without mitigation or detection, a malformed DAG, a ui_screen with no mock, or an unstamped PRD/PR-FAQ/ui-flow. Fix the pack. Never self-stamp a lock you were not given.
- **"spec.md has no End-State"** — write End-State and Success Criteria first, backward from prd.md §Impact.
- **"Assemble re-designed instead of building"** — a bug in the run: assemble consumes the pack as written and halts on red. Fix the plan here.

## Related

- `/manufacture` — assemble mode builds this pack; single/loop mode handles smaller changes
- `/manuf-design-qa` — grades the plan before assemble · `/manuf-qa` — grades the build before merge
- `hooks/manuf-pack-validate.sh` — the structural gate · `hooks/manuf-qa-stamp.sh` — the grade stamps
- `hooks/design-source-gate.sh` — blocks hand-rolled UI without a `design/` folder
- `/spec` — the lighter end-first spec for work that does not need a full pack
- `/engineering` — deep modules, complexity · `/stress-test` — pre-mortem a finished pack
