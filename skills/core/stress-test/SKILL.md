---
name: stress-test
description: |
  Mandatory post-design stress-test gate — 5 questions (how it fails, edge cases, half-resources alt, tenets/boundaries, best reason it misses the objective) + conditional pass@k (Q6) and unattended-loop budget+entropy (Q7). Iterate until it holds. SKIP: still-open subjective vote (council). Triggers: "/stress-test", "stress test this", "pressure test this", "best reason this fails", "is this design ready", "before shipping", "pre-mortem this".
---

# /stress-test — post-design rigor gate

> Every design ships through this. Not one pass — the loop is the work.

## When to invoke

**Mandatory** before declaring done on:
- New skills · new hooks · new rules · new mechanisms
- Architecture / design proposals
- Refactor plans · migration plans
- Process / discipline updates
- Significant tactical decisions (pricing, scope, deploy strategy)

**Skip** for:
- Typo / log-line / one-character fixes
- Trivial data lookups
- Reading / understanding tasks (no proposal to test)
- Already-stress-tested designs being re-applied

## The 5 questions (run in order)

### Q1 — How can this fail?
Enumerate failure modes. Be specific. *"It might break"* doesn't count. *"If the hook fires before flag-create, race condition produces duplicate emit"* counts.

### Q2 — What edge cases?
What inputs / states / sequences haven't been considered? Cold start. Empty input. Concurrent runs. Interrupted mid-flow. Cross-machine. Permission denials. Tool not found. Stale cache. New tool version.

### Q3 — If I had half the time and resources, what would I do? Why am I doing it THIS way?
Forces simplicity-vs-elaboration justification. If the half-resource version is *almost as good*, the elaborate version is probably over-engineered. State the tradeoff explicitly.

### Q4 — Boundary conditions checked?
Walk five boundary checks:
- **Cover** — designed for the union of cases, not one usage pattern?
- **Restructure-over-patch** — is this patch #4 on a surface that needs restructure?
- **Cadence** — probe how often this fires / surfaces / matters
- **Use-cases** — walked ≥3 stress scenarios (cold-start, multi-session, interrupted-resumed, cross-machine handoff)?
- **Fail-modes** — does every failure mode have a detection mechanism (a guard, a lint, an alert)?

### Q5 — Best reason this doesn't deliver the primary objective?
**The entry stress-test.** Not "can it fail" (too soft, produces enumeration). Not "what edge cases" (also enumeration). **The strongest single reason this design doesn't deliver what it was built for.** Forces ranking. Picks the one mode that, if unaddressed, kills the design.

### Q5 external challenge (optional but valuable)

After you answer Q5, get an independent second opinion: run the same proposal past a second model, a fresh session with no context, or a colleague. Ask for the single strongest reason the design misses its objective, ≤100 words, no praise.

**If the external Q5 matches yours:** reinforced — address it before continuing.
**If it differs:** both failure modes enter the loop.
**If no independent pass is available:** your own Q5 is sufficient, but state explicitly that the independent check is missing.

Optionally in parallel: search the web for `"[design name or pattern] production failure post-mortem lessons learned"`. Surface findings that directly support or contradict either Q5 answer; skip silently if nothing useful.

### Q6 — Reliability gate (pass@k) — CONDITIONAL, non-deterministic objectives only

Q1–Q5 stress a design by *reasoning* about failure. Necessary, but blind to one class: designs whose primary objective is **non-deterministic behavior** — an LLM prompt, a classifier, an agent flow, a skill, any step that depends on model output. Such a design can pass Q1–Q5 cleanly on paper and still fail 30% of runs in practice. Reasoning cannot measure reliability; only repeated runs can.

**Fires when** the primary objective depends on model / LLM output, classification, agent behavior, or any stochastic step.
**Skips when** the objective is deterministic — a lint rule, grep, path-exclusion, schema migration, file move, a hook that pattern-matches a fixed string. One run proves a deterministic mechanism; pass@k on it is theater (and would violate this skill's own Q3).

**Method:** fix an eval input, run the behavior k times, record pass/fail per run.
- `pass@k` = ≥1 success in k attempts (capability floor — "can it do this at all, reliably enough")
- `pass^k` = all k succeed (reliability bar — for critical paths and regression checks)

**Targets:** capability designs → `pass@3 ≥ 90%`. Critical or regression paths → `pass^3 = 100%`. Raise k above 3 when a silent miss is expensive (data loss, wrong classification on user-facing output, money).

**Feeds the loop:** pass@k below target = the design is NOT done, no matter how clean Q1–Q5 read. Refine the mechanism (tighten the prompt, add a guardrail, narrow the input, add a deterministic post-check) and re-measure. This is the iterate-loop with an *empirical* gate, not just a reasoning gate.

**OOD-verifier caveat:** if the design's *verifier itself* is an agent / LLM-judge, it is unreliable when the verification target is **out-of-distribution** — novel paper, unfamiliar benchmark, a check the model hasn't seen patterns for. An OOD agent-evaluator silently passes weak work. So: when the check is novel, the deterministic floor is not optional — it is the only trustworthy layer; agent-review degrades to advisory. Run Q6's pass@k on the *verifier*, not just the generator, whenever the verifier is itself stochastic.

### Q7 — Unattended-loop gate (budget + entropy) — CONDITIONAL, unattended metric-descent runs only

Q1–Q6 stress a design's *correctness and reliability*. Blind to one class: designs that **run unattended in a loop, descending toward a metric** — overnight builds, any "drop agent in feedback loop until target met." Such a design can pass Q1–Q6 and still burn 10 hours for a 2% gain, or memorize the eval instead of generalizing. The agent is an optimizer; every cheap path you don't fence, it sprints down.

**Fires when** the design runs an agent unattended across multiple cycles toward an outcome metric.
**Skips when** the design is single-pass-per-item (Plan→Code→Test→Review once per feature — no metric to descend, no overfit risk) or anything non-loop.

Four checks — each a *named cheap path the optimizer takes if unfenced*:
1. **Blind eval?** — answer key hidden during the run, revealed only at scoring. Eval set big enough that enumeration doesn't pay.
2. **Wall-clock cap, queryable mid-run?** — token-budget ≠ time-budget. A slow-but-cheap run grinds past a token cap. The agent has no sense of time; it must be able to query elapsed wall-clock and stop.
3. **Overfit-reflection per cycle?** — each cycle the agent asks "am I generalizing or memorizing the eval?" If memorizing, next change must *remove* an eval-shaped artifact (cap a list, blind a feature, widen the eval), not add one.
4. **Stall-kick + iteration-log?** — if last cycle didn't move the metric, next cycle can't be "same idea harder" (local-maxima lock-in — turning one knob ignoring 1000). Force a non-obvious jump. Iteration-log (hypothesis · expected failure · diagnostic) survives context resets so the agent can reflect across runs.

**Feeds the loop:** any unfenced cheap path = design NOT done. Add the instrument/fence, re-check. "Constraint without an instrument is a vibe" — a wall-clock cap the agent can't query is not a constraint.

## The loop (iterate until it holds)

```
1. State the proposal in 1-2 sentences (the primary objective is part of it).
2. Run Q1-Q5. Then run Q6 if the objective is non-deterministic, and Q7 if the design runs unattended in a metric-descent loop (both conditional — skip if N/A).
3. The Q5 answer (best reason it fails) is the entry test.
4. If Q5 answer is STRONG: refine the design to address it. Go to step 2.
5. If Q5 answer is WEAK / acceptable tradeoff: ship Phase 1 (the floor).
6. After ship, monitor in production. New failure modes feed back into Q5 for next iteration.
```

**Default minimum: 2 loop iterations.** A design that survives only one Q5 round is probably under-tested.

**Default cap: 5 iterations.** If after 5 rounds the strongest failure mode still kills the design, **restructure the substrate**. The design is wrong, not just incomplete.

## Working dir

For each /stress-test run, create `<cwd>/.stress-test-temp/<timestamp>-<slug>/` and log each iteration:
- `iteration-1.md` — proposal + Q1-Q5 answers + refinement chosen
- `iteration-2.md` — refined proposal + Q1-Q5 + refinement
- ...
- `final.md` — what shipped + remaining acceptable Q5 (the explicit tradeoff)

Audit trail stays. Don't delete after ship.

## Output format

After the loop completes, return:

```markdown
## Stress-test verdict — <design name>

**Primary objective:** <one sentence>
**Iterations:** N
**Final design:** <one paragraph>

**Q1 (failure modes addressed):**
- ...

**Q2 (edge cases handled):**
- ...

**Q3 (half-resource alternative considered + this-way justification):**
- ...

**Q4 (boundary conditions verified):**
- Cover: ✓ / ✗
- Restructure-over-patch: ✓ / ✗
- Cadence: ✓ / ✗
- Use-cases (≥3 scenarios walked): ✓ / ✗
- Fail-modes (guards installed): ✓ / ✗

**Q5 (best reason this still doesn't deliver):**
<the residual failure mode that survived all iterations — accepted as explicit tradeoff>

**Q6 (reliability — pass@k, non-deterministic objectives only):**
- N/A — deterministic objective — OR —
- pass@<k>: <X>% (<successes>/<runs>) · pass^<k>: <PASS/FAIL> · target (<pass@3≥90% | pass^3=100%>): ✓ / ✗

**Q7 (unattended-loop gate — metric-descent runs only):**
- N/A — single-pass design, no metric descent — OR —
- Blind+large eval: ✓ / ✗ · Wall-clock cap queryable mid-run: ✓ / ✗ · Overfit-reflection per cycle: ✓ / ✗ · Stall-kick + iteration-log: ✓ / ✗

**Ship: Phase 1 floor** (reversible, narrow scope) — <what ships>
**Phase 2 (guards, deferred):** <what fills the residual>
```

## Composition with other skills

- **Before /stress-test:** if subjective design choice, run `/council` first (5 advisors) — those verdicts feed Q1-Q3.
- **Q6 pass@k measures *same-config repeated-run* reliability** (does THIS design hold across N runs) — not cross-model A/B benchmarking. Different axes; don't conflate.

## V-gate

The skill is working when:
- Iterations log exists at `<cwd>/.stress-test-temp/<ts>-<slug>/`
- Each iteration has a Q5 answer (no skipping)
- Final ship explicitly states the residual Q5 (no hidden flaws)
- For non-deterministic designs, the verdict carries a real pass@k line (actual run counts, not `N/A` used as an escape)

**Known limitation (honest tradeoff):** Q6 is honor-system — a markdown question, no hook forces the k runs or verifies the reported numbers. A hook can't easily know whether a given design's objective is non-deterministic, so enforcing it would over-fire (theater on deterministic designs) or under-fire. Deliberately left as method-discipline, not an automated guard. If pass@k starts getting skipped in practice, revisit — but don't pre-build the enforcement (over-engineering per this skill's own Q3).

## G-guard

Optional: automate a weekly audit with your OS scheduler — how many designs shipped this week without a `.stress-test-temp/` audit trail? If >0, surface it — designs are slipping past the gate.

## Rules

1. **Q5 is non-negotiable** — every iteration ends with "best reason this doesn't deliver primary objective." Skipping = honor-system, the rule this exists to break.
2. **Minimum 2 iterations.** If you find yourself wanting to ship after iteration 1, run iteration 2 anyway. Often the second pass surfaces the real flaw.
3. **Cap 5 iterations** — beyond that, restructure substrate.
4. **Keep audit trail** — don't delete `.stress-test-temp/` after ship.
5. **Compose with /council for subjective designs** — advisors first, then stress-test.
6. **Cost discipline** — when budget tight, the half-resource Q3 answer might be the right ship.
7. **pass@k for non-deterministic objectives (Q6)** — if the design's primary objective is model / LLM / classifier / agent behavior, a clean Q1–Q5 is NOT enough: run k trials and report pass@k before shipping. Skip for deterministic mechanisms (one run proves those). This is method-discipline surfaced in the output, not hook-enforced (see V-gate limitation) — honesty about the k runs is the gate.

## Why this exists

The author repeatedly observed that proposals were not being stress-tested. The missing discipline had a name: hypothesis-first, pre-mortem questions, best-reason-to-fail, iterate-the-loop. This skill is the durable mechanism that codifies the discipline so no future session needs to be told the same lesson.

## Provenance

- Q6 (pass@k reliability gate) concept adapted from affaan-m/ECC `eval-harness` skill (eval-driven development, pass@k / pass^k metrics). ECC's version was unconditional + product-test-suite-shaped; this absorption makes it conditional (non-deterministic objectives only) and folds it into the existing loop rather than standing up a parallel framework.
- Q7 (unattended-loop gate: budget + entropy) concept adapted from Elvis Sun's loss-function-development essay (target/constraints/instruments/forced-entropy). The two additive ideas — wall-clock cap queryable mid-run, and forced entropy per cycle (overfit-reflection + stall-kick) — became Q7.
