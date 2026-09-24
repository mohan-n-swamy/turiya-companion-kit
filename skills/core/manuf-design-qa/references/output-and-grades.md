# manuf-design-qa — output, stamp, grade rubric

## Output format

```markdown
# manuf-design-qa · <pack slug>

## Grade: A+++ | A | B | C | F
(A = assemble-ready; A+++ = pack is tight; B or below = do NOT assemble)

## Plan gap findings (severity order)
1. FINDING: ...
   Layer: prd | taste | design | hld/lld | components | risks | verification
   Severity: CRITICAL | HIGH | MEDIUM | LOW
   Evidence: file:line
   Fix: re-plan action (not assemble)

## Coverage matrix
| PRD journey step | ui_screen | mock file | owning component | data_contract fields |
| ... | | | | |

## Gate recommendation
- [ ] READY TO ASSEMBLE (grade ≥ A)
- [ ] HALT — re-run manuf-product-design on gaps above
```

## HARD: stamp the grade (G-guard)

After grading, **always** write the machine stamp (hooks/workflow read this — prose alone is ignored):

```bash
bash ~/.claude/hooks/manuf-qa-stamp.sh write design-qa specs/NNN-feature <GRADE> --notes='session-summary'
bash ~/.claude/hooks/manuf-qa-stamp.sh check design-qa specs/NNN-feature --min=A
```

Stamp path: `specs/NNN-feature/.qa/design-qa.json`.  
Manufacture assemble **HALTs** without grade ≥ A.

## Grade rubric

| Grade | Meaning |
|---|---|
| **A+++** | No CRITICAL/HIGH; every journey mapped; HLD/LLD cite design; verification recipes complete |
| **A** | MEDIUM/LOW only; assemble allowed |
| **B** | HIGH plan gaps; HALT assemble |
| **C** | CRITICAL (missing design/, PRD uncovered, dummy without STOP) |
| **F** | pack-validate INVALID |
