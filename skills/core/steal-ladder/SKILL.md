---
name: steal-ladder
description: "Evaluate and absorb someone else's tool, skill, or mechanism the disciplined way: see → record → evaluate against a real problem → lift the piece (not the whole rig) → adapt → attribute. Use when you find something promising on X/GitHub/a blog/someone's setup and feel the urge to install it. Triggers: '/steal-ladder <url or name>', 'should I adopt this', 'I saw this tool', 'steal this', 'evaluate this repo'. SKIP WHEN: it's your own idea (just build it) or a full dependency decision for production software (use a proper tool evaluation)."
argument-hint: "[url, repo, or description of the thing you saw]"
---

# Steal Ladder — absorb mechanisms, not tools

The failure this prevents: same-day installing every shiny thing, ending with a rig you don't understand and can't maintain. The ladder converts impulse into capability. Nothing gets adopted the day it's seen.

## The rungs (run in order; stop at any rung and the thing dies — that's a feature)

1. **SEE** — name precisely what caught your eye. Not the tool: the *mechanism* inside it (a loop, a gate, a file format, a prompt shape). One sentence.
2. **RECORD** — write it down with its source URL, author, license, and date, in a running `steal-ladder.md` note. This rung is mandatory even if you go no further. A mechanism with no recorded source becomes unattributable later — you will either misrepresent it as yours or be unable to credit it. Record now or lose the trail.
3. **EVALUATE** — against a problem you actually have, not a problem it demos well. Ask: which of my recurring failures does this address? If the answer is "none, but it's cool" — it stays on the ladder, unadopted. Evaluation is hands-on, in quarantine:
   - `git clone` the repo into a throwaway dir (`$TMPDIR/steal-ladder/<name>` or your session scratchpad) — never into your real setup.
   - Read the actual source, not just the README. Then TEST the core primitive on your own real data — one honest run.
   - Nothing from the clone gets installed, linked, or copied into your live environment during evaluation.
   - **Clean up when done**: delete the clone whatever the verdict. If the verdict is lift, the lift (rung 4) is a deliberate extraction into your own conventions — never "keep the clone around and use it from temp."
4. **LIFT THE PIECE** — take the mechanism, not the rig. A straight copy of someone's whole setup is a dump: you inherit their constraints without their reasons. Extract the one loop/gate/pattern that fixes your failure.
5. **ADAPT** — rewrite it in your own conventions, your own paths, your own vocabulary. If you can't rewrite it, you don't understand it yet — go back to rung 3.
6. **ATTRIBUTE** — in the adapted artifact, one line: what was stolen, from whom, URL, license. Ship nothing derived from someone else's public work without this line. If the upstream has no license, link and credit but do not republish their content.

## Invocation behavior

Given a URL/name: fetch/clone into the throwaway dir → read the source → identify the mechanism(s) → run rungs 1–3 with the user (what real problem of yours does this address? test the primitive on their real data) → if it clears rung 3, propose the minimal lift (rung 4) and the adaptation sketch (rung 5) → append the record (rung 2 format) to the user's steal-ladder note → **delete the clone** and confirm cleanup in the report. Default verdict is RECORD-ONLY; adoption requires a named real problem. The clone must not survive the session either way.

## Record format (append-only)

```markdown
- YYYY-MM-DD · <mechanism, one line> · source: <url> · author · license · status: recorded | lifted | adapted | rejected(<why>)
```

## The test

Six months later you should be able to answer, for every piece of your setup: where did this come from, why did I take it, what problem was it solving? Any piece with no answer is a candidate for removal.
