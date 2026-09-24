# manuf-qa — layer checks (load when scoring)

Procedure layers **1–7**. Layer 0 (inventory + plan baseline) stays in `SKILL.md`.

### 1. Pack fidelity (PRD ↔ design ↔ HLD/LLD ↔ components)

For each PRD impact / user journey:

| Check | Pass if |
|---|---|
| Screen coverage | Every PRD flow step has a `ui_screens` row + mock file |
| Non-goals respected | Specs do not add features outside PRD |
| HLD cites design SoT | architecture.md names `design/<files>` as visual source of truth |
| LLD = data contract | Types/fields in lld.md match data_contract field names **exactly** |
| Components implement packs | UI components' CODE/PLACEMENT reference `design/...` paths |
| No freehand UI in CODE | No parallel "redesign" or new design system invented in components |
| Verification recipes | verification.md includes design-fidelity + live-data checks |

**FAIL patterns:** mock path missing; LLD invents fields not in data contract; components say "build a card grid" without mock citation.

### 2. Design fidelity (exported design ↔ built UI)

Compare **built** UI (source in app, or live URL) to each locked mock in `design/`.

| Axis | How to check | Pass |
|---|---|---|
| Hierarchy | Primary headline / CTA / nav structure | Same order and weight as mock |
| Layout family | Split hero vs centered, bento vs list | Same family (not color-swap only) |
| Tokens | Accent, type roles, spacing rhythm | Matches taste brief + mock |
| Chrome | Nav/footer pattern | Not AI-default if mock wasn't |
| Copy slots | Labels/CTAs | Same intent; no invented metrics |
| Anti-slop | No generic-AI tells (default fonts, purple gradients, invented metrics) | None, or justified |

**Method:** side-by-side mock file vs app component (read both). Optional: screenshot live page.  
**Grade per screen:** MATCH | DRIFT | MISSING  

Any MISSING or systemic DRIFT → cap overall grade at B or below until fixed.

### 3. Data fidelity (contract ↔ wiring ↔ runtime)

| Check | How | Pass |
|---|---|---|
| Contract real SoT | data_contract lists the API/DB source per field | Sources named |
| NEEDS_LIVE_WIRE | Any such field has a component with STOP | Not silently shipped |
| Code wiring | Grep app for contract field names / fetch paths | Present |
| Dummy ban | Grep app+fixtures: `dummy|sampleData|fakeUser|lorem|placeholder|hardcoded demo|TODO: wire` on prod paths | Zero hits (or behind non-prod flag only) |
| Runtime values | Hit live/staging endpoint or UI; values look real | Not fixture-only on prod env |

**Named failure:** "works with fixtures" ≠ production. For `env=prod` or "deploy production", **require live probe evidence**.

### 4. Execution fidelity (plan ↔ manufacture output)

Against `execution-plan.md` + `manifest.json` DAG:

| Check | Pass |
|---|---|
| Every component id built | Files from PLACEMENT exist; CODE intent landed |
| Order respected | No dep used before built |
| AFTER checks | Re-run key COMMANDS/EXPECTED from components |
| No silent plan patches | Diff vs pack: no "we decided to skip C3" without re-plan |
| Risks detection | Each risk's G-guard exists or is flagged open |

### 5. Performance

| Check | Method | Target (defaults; use pack verification.md if stricter) |
|---|---|---|
| Bundle / load | Lighthouse or network panel if URL | LCP &lt; 2.5s mobile-ish; no multi-MB dump |
| Main thread | Long tasks / jank on primary flow | No multi-second freezes on happy path |
| API | Timing of primary data fetch | Reasonable; N+1 / waterfalls named |
| Motion | prefers-reduced-motion; no scroll-listener thrash | Reduced-motion safe |

If no URL yet: static analysis only (heavy deps, image sizes in design, unbounded lists) and mark **UNVERIFIED** not PASS.

### 6. UI quality (A+++ bar)

Beyond fidelity:

- Full interactive states on primary controls (default/hover/focus/active/disabled/loading/error/success where applicable)
- A11y: focus visible, contrast, labels, alt
- Empty/error states exist for live data failures
- Mobile: no horizontal scroll on primary screens (320–414)
- The TASTE-BRIEF dials (variance / motion / density) still respected

### 7. Troubleshoot (only on FAILs)

For each FAIL, emit:

```
FINDING: <short title>
Layer: pack | design | data | execution | performance | ui
Severity: CRITICAL | HIGH | MEDIUM | LOW
Evidence: <file:line or URL observation>
Root cause: <one sentence>
Fix: <smallest next action — re-plan vs re-assemble vs wire SoT>
Owner skill: manuf-product-design | manufacture | code
Verify: <command or probe that turns this green>
```

Do **not** re-author the whole pack unless root cause is plan-level. Prefer: wire data → fix one component → re-vendor mock if design was wrong.

## Modes (shortcuts)

### pack-only
**Deprecated here** — use **`manuf-design-qa`** for plan-only. If invoked, redirect.

### design-fidelity
Layers 0 + 2. Requires built UI vs design/ mocks.

### data-fidelity  
Layers 0 + 3. Grep + optional live fetch.

### full (default after assemble / pre-prod)
All layers 0–7.
