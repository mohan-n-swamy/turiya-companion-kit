# manuf-qa — output format, stamps, grades, examples

## Output format (always)

```markdown
# manuf-qa · <pack slug> · env=<local|staging|prod>

## Grade: A+++ | A | B | C | F
(A+++ = all layers PASS with evidence; any CRITICAL = max C; MISSING design = max C; pack invalid or never bound to design/ = F)

## Layer scores
| Layer | Score | Notes |
| pack fidelity | PASS/FAIL | |
| design fidelity | PASS/FAIL/DRIFT | per-screen |
| data fidelity | PASS/FAIL | |
| execution fidelity | PASS/FAIL | |
| performance | PASS/FAIL/UNVERIFIED | |
| ui quality | PASS/FAIL | |

## Pack inventory
- validate.sh: VALID|INVALID
- screens: N · mocks: N · contracts: N

## Top findings (severity order)
1. ...

## A+++ path (ordered fixes)
1. ...
2. ...

## Evidence log
- commands run + key outputs
- files compared (mock ↔ built)
```

## HARD: stamp the grade (G-guard)

After a **full** run, write the machine stamp (the manufacture workflow and your pre-deploy check read it; partial runs do not stamp):

```bash
bash ~/.claude/hooks/manuf-qa-stamp.sh write manuf-qa specs/NNN-feature <GRADE> --env=local|staging|prod --notes='pre-merge|pre-deploy'
bash ~/.claude/hooks/manuf-qa-stamp.sh check manuf-qa specs/NNN-feature --min=A
```

Stamp path: `specs/NNN-feature/.qa/manuf-qa.json`.

| Gate | Min grade | When |
|---|---|---|
| **Merge / implementation PR** | **A** | End of manufacture (workflow Build QA phase) |
| **Prod deploy** | **A+++** + stamp `--env=prod` | Before ship — run the prod check below |

```bash
# merge floor
bash ~/.claude/hooks/manuf-qa-stamp.sh write manuf-qa specs/NNN A --env=local
bash ~/.claude/hooks/manuf-qa-stamp.sh check manuf-qa specs/NNN --min=A

# prod floor (separate — A alone will not pass)
bash ~/.claude/hooks/manuf-qa-stamp.sh write manuf-qa specs/NNN A+++ --env=prod --notes='live probe OK'
bash ~/.claude/hooks/manuf-qa-stamp.sh check manuf-qa specs/NNN --min=A+++ --env=prod
```


## Grade rubric

| Grade | Meaning |
|---|---|
| **A+++** | All layers PASS; live data probed when env is staging/prod; design MATCH on all screens; no dummy tokens; performance PASS or pack says N/A |
| **A** | Minor MEDIUM/LOW only; no CRITICAL/HIGH |
| **B** | Design DRIFT or data partial; ship blocked for prod |
| **C** | CRITICAL present (missing design, dummy in prod path, major journey missing) |
| **F** | Pack invalid or assemble never bound to design/ |

## Examples

**Example 1 — after assemble, before prod**  
> User: `/manuf-qa specs/003-saved-searches --env=staging`  
> Action: validate pack → map each ui_screen mock to app route → grep dummy → hit staging URL → Lighthouse-ish notes → grade + ordered fixes.

**Example 2 — "UI doesn't look like the mock"**  
> User: `/manuf-qa design-fidelity specs/003`  
> Action: open design/S1.html vs app Login component; list hierarchy diffs; root cause hand-rolled CSS in C4; fix: re-implement C4 from mock, not new design.

**Example 3 — dummy metrics in production**  
> User: prod shows 99.9% uptime never in PRD  
> Action: data-fidelity layer finds hard-coded string in component; contract missing field; FIX: NEEDS_LIVE_WIRE or wire real metric API; grade C until live probe green.

## Troubleshooting

- **"validate.sh VALID but grade C"** — expected: mechanical structure can pass while design/data drift fails judgment layers.  
- **"No live URL"** — mark performance/runtime UNVERIFIED; do not invent PASS.  
- **"Pack has no UI"** — skip design/ui layers; still score pack + execution + data for backend.  
- **"Should I rewrite the pack?"** — only if PRD or design lock was wrong. If code drifted from good pack → re-assemble, don't re-plan.
