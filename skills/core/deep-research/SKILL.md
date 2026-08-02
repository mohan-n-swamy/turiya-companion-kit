---
name: deep-research
description: |
  Deep research harness — fan-out web searches, fetch sources, adversarially verify claims, synthesize a cited report. Use when the user wants a deep, multi-source, fact-checked research report on any topic. BEFORE invoking, check if the question is specific enough to research directly — if underspecified (e.g. "what car to buy" without budget/use-case/region), ask 2-3 clarifying questions to narrow scope first.
---

# /deep-research — adversarially verified research

Not a single search-and-summarize. Five phases: decompose the question, search it from independent angles in parallel, extract falsifiable claims from real sources, try to kill each claim, then synthesize only what survived — with citations.

## Phase 0 — Scope check (before anything)

If the question is underspecified, ask 2-3 clarifying questions (budget, use-case, region, constraints, time horizon) and weave the answers into the research question. A vague question produces a vague report no matter how good the harness is.

## Phase 1 — Scope: decompose into 5 angles

Break the refined question into ~5 independent search angles. Good angles differ in *kind*, not just keywords:

- the direct question itself
- the skeptic's angle ("[topic] problems / criticism / failure")
- the practitioner's angle ("[topic] real-world experience / post-mortem")
- the data angle ("[topic] benchmark / statistics / study")
- the adjacent-alternative angle ("[topic] vs alternatives")

## Phase 2 — Search: parallel fan-out

Dispatch one search sub-agent per angle, **in parallel** (single message, multiple Agent calls, each with WebSearch). Each agent returns: top URLs found + one-line relevance note per URL. Keep the raw search dumps in the sub-agent forks; only the URL lists come back.

## Phase 3 — Fetch and extract claims

- Deduplicate URLs across angles.
- Fetch the top ~15 sources (WebFetch), preferring primary sources over aggregators.
- From each source, extract **falsifiable claims** — statements specific enough to be wrong ("X costs $Y as of DATE", "study of N found Z"), each tagged with its source URL. Opinions and vibes are noted but not treated as claims.

## Phase 4 — Verify: adversarial 3-vote per claim

For each load-bearing claim (the ones the report's conclusions rest on), run an adversarial check: three independent verification passes (separate sub-agents or separate reasoning passes), each asked *"what evidence would refute this claim?"* and instructed to actively search for counter-evidence, not confirmation.

- A claim dies on **2 of 3 refutes** with cited counter-evidence.
- A claim survives with a confidence grade: **high** (multiple independent sources agree), **medium** (single good source, no counter-evidence found), **low** (survived but thin — label it).
- Contradictions between sources are reported as contradictions with both citations — never silently resolved.

## Phase 5 — Synthesize

- Merge semantically duplicate claims (same fact, different wording).
- Rank by confidence, lead with the answer to the user's actual question.
- Every claim in the report carries its citation. No citation → the sentence says "unverified".
- Close with: what couldn't be verified, where sources conflict, and what a deeper pass would check next.

## Output format

```markdown
# <Question>

## Answer (short)
<2-4 sentences, the verified bottom line>

## What the evidence says
<claims grouped by sub-topic, each with [source] links and confidence grades>

## Where sources conflict
<contradiction pairs, both cited, dated — newer/primary favored but both shown>

## What survived thin / couldn't be verified
<low-confidence and unverifiable items, honestly labeled>

## Sources
<numbered list of URLs actually used>
```

## Rules

1. **Falsifiable claims only enter verification.** "Many people like X" is not a claim; "X has N stars / M% market share as of DATE" is.
2. **Search for refutation, not confirmation.** The verify phase asks "how is this wrong?", never "find support for this."
3. **Contradictions are results, not noise.** Report both sides with dates.
4. **No citation, no claim.** Anything you can't source gets an explicit "unverified" tag or gets cut.
5. **Parallelize the fan-out.** Sequential searching wastes the harness; the angles are independent by design.
6. **Cost sanity:** a full run is ~10-20 web fetches + several sub-agents. Don't deep-research questions a single lookup answers.
