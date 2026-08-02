---
name: council
description: |
  Five-advisor peer-review council for subjective decisions — Contrarian, First Principles, Expansionist, Outsider, Executor, then peer-review + chairman synthesis. Breaks single-judge sycophancy. SKIP: factual lookups; writing; summaries; simple yes/no; retros. Triggers: "/council", "council this", "pressure-test this", "war room this", "debate this", "five advisors".
---

# /council — five-advisor peer-review

> Single-judge bias is real. *"Ask Claude if your idea is good, you get a case for it. Ask if it's bad, you get a case against it."* The council fixes this with five advisors trained to disagree with each other and with you, then a peer-review pass before verdict.

> What the council is: it surfaces the *space* of perspectives usually weighed on a question of this shape — five lenses by base-rate, not one verdict. It expands what's considerable; the user judges what's right. The chairman's recommendation is the strongest *reading*, not the answer — the dissent log exists because the call is theirs. (The per-lens voice lives in `advisors/*.md`; the same frequency-discipline applies there.)

## When to use

| ✅ Council this | ❌ Don't council this |
|---|---|
| Pricing decisions | Factual lookups |
| Pivot or stay | Writing tasks |
| Copy critique | Summaries |
| Hire vs automate | Simple yes/no |
| Positioning angles | Research distillation |
| Strategy / goal scope | Daily / weekly retros |

## The five advisors

| # | Lens | Advisor file |
|---|---|---|
| 01 | DOWNSIDE — hunt the fatal flaw | `advisors/contrarian.md` |
| 02 | REFRAME — strip assumptions | `advisors/first-principles.md` |
| 03 | UPSIDE — what if it works *better* | `advisors/expansionist.md` |
| 04 | FRESH EYES — zero-context catch | `advisors/outsider.md` |
| 05 | ACTION — fastest path to doing | `advisors/executor.md` |

## How to run

You will execute three layers — DO NOT collapse them:

### Layer 1 — Parallel advisor dispatch (context fork)

For each of the 5 advisors, dispatch a `general-purpose` Agent in **parallel** (single message, 5 tool calls). Each agent gets:

1. The full text of the user's question.
2. The advisor's prompt (read from `advisors/<lens>.md`).
3. Instruction to write a verdict (≤200 words) to `temp/<advisor>.md` and return a one-line summary.

This isolates each advisor's reasoning from the others — no contamination — and keeps the orchestrator's main context lean (tool dumps stay in the agent forks).

### Layer 2 — Peer-review pass (file handoff)

Once all 5 verdicts are written to `temp/`, dispatch ONE more `general-purpose` Agent:

- Reads all 5 advisor files via `cat temp/*.md`
- For each advisor, writes a refined verdict to `temp/<advisor>-revised.md` that updates based on the other 4 perspectives
- The instruction MUST emphasize: **refine, do not collapse to consensus.** If an advisor still disagrees, they sharpen — they do not fold.

### Layer 3 — Chairman synthesis

YOU (the orchestrator) read the 5 revised files via `cat temp/*-revised.md` and produce the final output:

```markdown
## Council verdict

### Where they agree
- ...

### Where they clash (and the substance of the clash)
- ...

### Blind spots all 5 missed (your read)
- ...

### Recommendation
<one paragraph — opinionated, with reasoning>

### Dissent log
<verbatim one-sentence dissent from each advisor that didn't get incorporated>
```

## Optional Layer 1.5 — external adversarial challenge

After the 5 advisor agents return but before peer review, you can add an independent break on groupthink: run the full question plus one-line summaries of all five verdicts past a second model or a fresh zero-context session. Ask for the fatal flaw all five missed, ≤150 words, no praise.

Write the returned answer to `temp/external-challenge.md`. Include it in peer review alongside the five advisor files. The peer-review agent must address the challenge explicitly; disagreement is allowed, silent dismissal is not.

If no second model is available, keep the work native and state that the external break is missing.

## File handoff conventions

- Working dir: `<cwd>/.council-temp/<timestamp>/` (NOT polluting any other temp/)
- Filenames: `contrarian.md`, `first-principles.md`, `expansionist.md`, `outsider.md`, `executor.md`, then `*-revised.md` after peer-review
- Cleanup: after chairman synthesis, leave the temp/ in place so the user can audit. Don't delete.

## Variants

`/council` (default) · lighter: skip the peer-review pass · heavier: 2 peer-review rounds · debate: just contrarian + expansionist, skip the other 3 · `/steelman` (inverted — see below).

## /steelman — charitable inversion of the council

Council attacks YOUR idea. Steelman does the opposite: builds the strongest, most charitable case **for a position you reject**, so you stop being surprised by what smart people on the other side actually believe.

Input: the position you disagree with + your current view (one line each).

Reuse the machinery, reframed. Dispatch **2 advisors in parallel** (single message), each instructed to *genuinely advocate* the rejected position — no caveats, no counterarguments, argue as if they believe it:
- `first-principles.md` — reframed: "what fundamental truth is this position built on?"
- `expansionist.md` — reframed: "what's the strongest single argument a brilliant advocate would deliver?"

Each writes ≤200 words to `temp/steelman-<lens>.md`. NO peer-review pass (no adversarial layer — that defeats the purpose). YOU synthesize:

```markdown
## Steelman

### The core insight this position is built on
- ...

### The evidence that supports it most powerfully
- ...

### Where MY view is weakest (the blind spot this reveals)
- ...

### The strongest single argument (as a brilliant advocate would put it)
<one paragraph — committed, no hedging>
```

**Rules:** no counterarguments to the steelman (that's the user's job). Don't say "but I disagree." The goal is the user walking away thinking *"I can see why intelligent people believe this."* Cost: ~3 calls (2 advisors + chairman).

## What this skill is NOT

- Not a research tool. If the question is factual ("what does X mean") use a normal search.
- Not a brainstorm. If you need many ideas, run a plain divergent-ideas session instead.
- Not an SOP. If you need a checklist, use the relevant process skill.

## Cost note

~7-8 LLM calls per run (5 advisors + optional external challenge + 1 peer-review + 1 chairman). Don't council factual questions — token waste.

## Related

- `antifragile-advisor` — solo precursor (single advisor, always-on)
- `stress-test` — post-design gate; run council first for subjective choices, then stress-test the winning design
