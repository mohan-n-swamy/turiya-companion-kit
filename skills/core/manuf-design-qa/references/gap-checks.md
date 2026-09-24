# manuf-design-qa — gap check tables (load when grading)

### 1. PRD / journey coverage

From locked `prd.md` (Impact · Problem · flow · non-goals):

| Gap check | FAIL if |
|---|---|
| Journey → screens | A PRD step has no `ui_screens` row (UI packs) |
| Screens → journey | A ui_screen not justified by PRD flow (scope creep) |
| Non-goals | Spec/components implement a non-goal |
| Success Criteria | `spec.md` SC not traceable to prd Impact |
| Backend-only | PRD is UI-heavy but pack skipped design without stamp |

### 2. Taste + design pack presence

| Gap check | FAIL if |
|---|---|
| TASTE-BRIEF | Missing for UI packs |
| Mock files | ui_screen.mock path missing or not under `design/` |
| Design orphan | design/ files not referenced by any ui_screen |
| Lock #2 | ui-flow.md missing Locked stamp |
| Data contract | Missing, or only dummy values with no `NEEDS_LIVE_WIRE` |

### 3. HLD / LLD fidelity to design (plan gaps)

| Gap check | FAIL if |
|---|---|
| Visual SoT | architecture.md never names `design/` as UI source of truth |
| Field parity | lld.md fields ≠ data_contract fields (extra or missing) |
| Re-derived shapes | LLD invents DTOs that don't match data contract |
| Hand-roll plan | Components describe freehand UI ("make a card grid") without mock citation |

### 4. Component completeness vs plan

For each `manifest.json` component + each ui_screen:

| Gap check | FAIL if |
|---|---|
| Screen ownership | A screen has no component that owns its implementation |
| Mock citation | UI component CODE/PLACEMENT lacks `design/...` reference |
| Dummy without STOP | CODE has dummy/sample/lorem without NEEDS_LIVE_WIRE + STOP |
| Haiku freedom | Component prose still has degrees of freedom (even if labels exist) — note as HIGH |
| DAG hole | Screen depends on data from C_j but no dep edge |
| Verification hole | No AFTER/verification recipe for a primary journey |

### 5. Risks + verification recipes (plan gaps)

| Gap check | FAIL if |
|---|---|
| Design not implemented | risks.md missing this risk + detection |
| Dummy in prod | risks.md missing this risk + detection |
| verification.md | Missing design-fidelity check and live-data check |
| detection G-guard | Risk has mitigation but no detection |

### 6. Cross-pack (if multi-pack repo)

Run when other `specs/*` exist. Check the seams a single-pack read cannot see:

| Gap check | FAIL if |
|---|---|
| Anchors | A component edits a file:line an earlier pack's code no longer has |
| Declared before use | A status/enum/symbol is used before the pack that declares it |
| Hotspot | A file edited by many packs, and this pack's checks do not re-run the earlier suites |

MISS → FAIL with seam detail.
