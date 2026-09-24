export const meta = {
  name: 'manufacture',
  description: 'The manufacture protocol as a Workflow. assemble mode builds a pack from /manuf-product-design: validate → plan QA stamp → dispatch each component by tier → fit-check halt-on-red → build QA stamp → adversary → pressure-test → gate. single/loop mode runs Diagnose → Machine → Fit-check → Adversary → Pressure-test → Gate on a goal + success criteria.',
  whenToUse: 'assemble: args = { mode:"assemble", pack:"/abs/path/specs/NNN-feature", cwd:"/abs/repo" }. single/loop: args = { mode:"single"|"loop", goal, criteria:[{id, check, pass_when}], maxIters }. Optional: lenses (override adversary lenses), minBudget.',
  phases: [
    { title: 'Diagnose', detail: 'Read real files, form hypothesis, trace fix in head, verify trace — no phantom gaps' },
    { title: 'Machine', detail: 'Decompose into parts (one surface each), write part-specs, commit per part' },
    { title: 'Validate pack', detail: 'assemble: structural validator + read manifest.json (the machine contract)' },
    { title: 'Plan QA (manuf-design-qa)', detail: 'HARD START: manuf-design-qa grade ≥ A stamped under pack/.qa/ before any component dispatch' },
    { title: 'Design (verify mocks)', detail: 'assemble: verify the exported mocks + data contract exist in the pack' },
    { title: 'Build (dispatch)', detail: 'assemble: walk DAG, dispatch each component by tier, fit-check halt-on-red' },
    { title: 'Build QA (manuf-qa)', detail: 'HARD END pre-merge: manuf-qa grade ≥ A stamped under pack/.qa/ before adversary/merge' },
    { title: 'Fit-check', detail: 'BEFORE: probe real slot. AFTER: build clean + full suite green + no-drift diff' },
    { title: 'Map-couplings', detail: 'Enumerate shared-state: SET-by / READ-by / breakage-if-stopped' },
    { title: 'Harden', detail: 'Every entry point rejects foreign inputs — contamination check per branch' },
    { title: 'Adversary', detail: 'Blast-sized 2–5 distinct-lens refuters — concrete breakage in real code + the single best reason it fails' },
    { title: 'Pressure-test', detail: 'Design-judgment triad: edge-cases · half-resources · tenets (adversarial Qs moved to Adversary)' },
    { title: 'Gate', detail: 'MERGED: Success Criteria + SERVED==BUILT; re-check manuf-qa stamp ≥ A before SHIP/merge' },
  ],
}

// ─── what this is ────────────────────────────────────────────────────────────
// The /manufacture protocol as a Claude Code Workflow script, so the gates run
// in a fixed order instead of relying on the model to remember them.
// Requires Claude Code's Workflow tool. Installed by `install.sh --harness`
// into ~/.claude/workflows/. Start it by asking Claude, e.g.
//   "run the manufacture workflow in assemble mode on /abs/repo/specs/003-saved-searches"
//
// MODES
//   assemble  args = { mode:'assemble', pack:'/abs/specs/NNN-feature', cwd:'/abs/repo' }
//             Builds a pack written by /manuf-product-design:
//             validate → design-qa stamp ≥ A → each component by tier (halt on
//             red) → manuf-qa stamp ≥ A → adversary → pressure-test → gate.
//   single    args = { mode:'single', goal:'…', criteria:[{ id, check, pass_when }], cwd }
//             One pass of Diagnose → Machine → Implement → adversary → pressure → gate
//             on a change that has no pack.
//   loop      same args as single, plus maxIters (default 5). Repeats the pass,
//             feeding the previous pass's blockers into the next Diagnose, until
//             SHIP or the cap.
//   Optional: base: 'main' (the branch the change is diffed against);
//             lenses: ['name — the question the reviewer must answer', …]
//             overrides the adversary lenses; minBudget stops loop mode early.
//
// OUTPUT  { verdict: 'SHIP' | 'NEEDS_WORK' | 'BLOCK', reason, … } — a BLOCK
//         names the failing gate, component or finding.
//
// HONEST LIMIT  Each gate is a step an agent runs (validator, QA skill, stamp
// check). The script fixes the ORDER and refuses to continue on a red result;
// it cannot stop a model that fabricates a QA grade. The stamps are a record
// you can audit (pack/.qa/*.json), not a proof.

// ─── args ────────────────────────────────────────────────────────────────────
// args may arrive as an object OR a JSON string (runtime-dependent); parse both.
const a = (() => {
  if (args && typeof args === 'object') return args
  if (typeof args === 'string' && args.trim()) { try { return JSON.parse(args) } catch { return {} } }
  return {}
})()
const GOAL       = String(a.goal || '').trim()
const CRITERIA   = Array.isArray(a.criteria) ? a.criteria : []
const PACK       = String(a.pack || '').trim()          // specs/NNN-feature dir for assemble mode (pass ABSOLUTE)
// Workers do NOT reliably inherit the workflow's launch directory — they may
// start in whatever git repo they detect, so relative PACK / PLACEMENT paths
// resolve to missing files and fit-checks go falsely RED. CWD is the absolute
// directory every worker must cd into; pass args.cwd = the repo root that PACK
// and its PLACEMENT paths are relative to.
const CWD        = String(a.cwd || '').trim()
const MODE       = (a.mode === 'assemble') ? 'assemble'
                 : (a.mode === 'single') ? 'single' : 'loop'
const BASE       = String(a.base || 'main').trim()   // branch the change is diffed against
const MAX_ITERS  = Number(a.maxIters) > 0 ? Number(a.maxIters) : 5
const MIN_BUDGET = Number(a.minBudget) > 0 ? Number(a.minBudget) : 60_000
// Full lens set (5). Sized down by blast-radius at run time (sizeLenses) unless
// the caller passes an explicit args.lenses override. control-flow + foreign-input
// are the ALWAYS-ON floor (a foreign input reaching the wrong branch is the
// commonest real break); the state-touching lenses (mutation/coupling/exception)
// are added only when the diff actually touches shared state.
const ALWAYS_LENSES = [
  'control-flow — can a foreign input reach the wrong branch and be mishandled?',
  'foreign-input — can an input meant for another branch reach this one and be mishandled (wrongly closed, deleted, sent)?',
]
const STATE_LENSES = [
  'mutation/purity — does the change corrupt shared state or violate immutability?',
  'coupling — does this silently break a far-off reader of shared state?',
  'exception-safety — do catch blocks re-throw, swallow, or leave state dirty?',
]
const FULL_LENSES = [...ALWAYS_LENSES, ...STATE_LENSES]
const LENS_OVERRIDE = Array.isArray(a.lenses) && a.lenses.length ? a.lenses : null

// Pick lenses by blast-radius: grep the actual diff for shared-state patterns.
// No state touched → 2 always-on lenses. State touched (or grep fails) → full 5.
// Explicit override always wins. Returns { lenses, blast }.
async function sizeLenses(diffScope) {
  if (LENS_OVERRIDE) return { lenses: LENS_OVERRIDE, blast: 'override' }
  const probe = await agent(
    `Run: \`git diff ${BASE}...HEAD | grep -ciE 'redis|\\\\.set\\\\(|\\\\.get\\\\(|UPDATE |INSERT |DELETE |process\\\\.env|global|shared|cache|await fetch|axios|requests\\\\.'\` in ${diffScope}. ` +
    `Return ONLY the integer count (0 if no match / no diff).`,
    { label: 'blast-probe', phase: 'Adversary', schema: {
      type: 'object', required: ['shared_state_hits'],
      properties: { shared_state_hits: { type: 'integer' } } }, model: 'sonnet' }
  ) // delegate-considered: greps the live diff — needs Bash
  const hits = probe?.shared_state_hits ?? 99  // probe failed → assume worst (full)
  return hits > 0 ? { lenses: FULL_LENSES, blast: `state-touching (${hits} hits)` }
                  : { lenses: ALWAYS_LENSES, blast: 'no shared state' }
}

if (MODE === 'assemble') {
  if (!PACK) return { error: 'assemble mode needs args.pack = the specs/NNN-feature directory of a manuf-product-design pack.' }
} else {
  if (!GOAL) {
    return { error: 'No goal provided. Pass args: { goal, criteria, mode, maxIters }.' }
  }
  if (!CRITERIA.length) {
    return { error: 'No success criteria. Each criterion needs: { id, check, pass_when }. Cannot define DONE without measurable criteria.' }
  }
}

// ─── delegate-first helpers (see workflows/lib/delegate-first.js) ──────────
// Worker stages go to the cheapest capable model, not the one running the
// workflow. Tier → model: cheap → haiku · code / adversarial → sonnet.
// Optional: set ROUTER_TOOL to an MCP router tool name (e.g.
// 'mcp__brain-router__delegate') to send worker stages to another model family.
const ROUTER_TOOL = null
const TIER_MODEL = { cheap: 'haiku', code: 'sonnet', adversarial: 'sonnet' }
async function smart(task, opts = {}) {
  const { complexity = 'code', schema, label, phase: ph } = opts
  if (!(complexity in TIER_MODEL)) throw new Error(`smart(): bad tier "${complexity}"`)
  const cwdLine = CWD ? `Work in the directory "${CWD}" (cd there first).
` : ''
  const prompt = ROUTER_TOOL
    ? `Call the ${ROUTER_TOOL} tool once with role="worker"${CWD ? `, cwd="${CWD}"` : ''}, and the task below passed verbatim. If it errors, do the task yourself.
` +
      `TASK:
<<<
${task}
>>>

Return ONLY the task answer.`
    : `${cwdLine}${task}`
  return agent(prompt, { schema, model: TIER_MODEL[complexity], label: label ?? `delegate:${complexity}`, ...(ph ? { phase: ph } : {}) })
}
// ─── end helpers ─────────────────────────────────────────────────────────────

// ─── schemas ─────────────────────────────────────────────────────────────────
const DIAGNOSIS_SCHEMA = {
  type: 'object', required: ['hypothesis', 'root_cause', 'files_to_read', 'phantom_gap_check'],
  properties: {
    hypothesis: { type: 'string' },
    root_cause: { type: 'string' },
    files_to_read: { type: 'array', items: { type: 'string' } },
    phantom_gap_check: { type: 'string', description: 'Proof the gap is REAL — cite file:line from actual read, not memory' },
    fix_trace: { type: 'string', description: 'End-to-end trace of the fix in your head before proposing' },
  },
}
const PARTS_SCHEMA = {
  type: 'object', required: ['parts'],
  properties: {
    parts: { type: 'array', items: {
      type: 'object', required: ['id', 'function', 'boundary', 'placement'],
      properties: {
        id: { type: 'string' },
        function: { type: 'string' },
        boundary: { type: 'object', required: ['owns', 'must_not_touch', 'must_preserve'],
          properties: { owns: { type: 'string' }, must_not_touch: { type: 'string' }, must_preserve: { type: 'string' } }
        },
        placement: { type: 'string', description: 'file:line' },
      },
    }},
  },
}
const COUPLING_SCHEMA = {
  type: 'object', required: ['couplings'],
  properties: {
    couplings: { type: 'array', items: {
      type: 'object', required: ['shared_state', 'set_by', 'read_by', 'breakage_if_stopped'],
      properties: {
        shared_state: { type: 'string' },
        set_by: { type: 'string' },
        read_by: { type: 'string' },
        breakage_if_stopped: { type: 'string' },
        structural_prevention: { type: 'string' },
      },
    }},
  },
}
// (CRITERIA_SCHEMA retired — success-criteria check merged into GATE_SCHEMA.)
const ADVERSARY_SCHEMA = {
  type: 'object', required: ['blocking', 'verdict'],
  properties: {
    blocking: { type: 'array', items: { type: 'string' } },
    verdict: { enum: ['NO BLOCKING ISSUES', 'BLOCKING ISSUES FOUND'] },
    unverifiable: { type: 'array', items: { type: 'string' }, description: 'Cannot be proven from code — flag to user' },
  },
}
// The two ADVERSARIAL pressure questions ("how does it fail", "best reason it
// fails") are asked by the adversary lenses. What remains here is the
// design-judgment triad (edge cases · half-resources · tenets) — one agent.
const PRESSURE_SCHEMA = {
  type: 'object', required: ['verdict'],
  properties: {
    verdict: { enum: ['SHIP', 'NEEDS_WORK', 'BLOCK'] },
    edge_cases: { type: 'array', items: { type: 'string' } },
    half_resources_alt: { type: 'string' },
    tenets_checked: { type: 'string' },
    fixes_needed: { type: 'array', items: { type: 'string' } },
  },
}
// Gate now ALSO owns success-criteria (merged Criteria-check + Gate into one
// proof agent — Gate already asserted "all criteria passed"; two round-trips
// for one served==built proof were redundant).
const GATE_SCHEMA = {
  type: 'object', required: ['verdict', 'served_equals_built', 'criteria_all_met'],
  properties: {
    verdict: { enum: ['SHIP', 'NEEDS_WORK', 'BLOCK'] },
    criteria_all_met: { type: 'boolean' },
    criteria: { type: 'array', items: {
      type: 'object', required: ['id', 'met', 'evidence'],
      properties: { id: { type: 'string' }, met: { type: 'boolean' }, evidence: { type: 'string' } } },
      description: 'Each success criterion with real check-command output as evidence' },
    served_equals_built: { type: 'boolean' },
    proof: { type: 'string', description: 'Evidence from inside running container / health endpoint, or explicit unverifiable flag + live-check recipe' },
    unverifiable_flags: { type: 'array', items: { type: 'string' } },
  },
}

// ─── shared merged back-half (adversary + pressure-test + gate) ─────
// Both change-mode (runManufacturePass) and assemble-mode (runAssemble) run this
// identical block — previously copy-pasted. adversaryGoal/pressureContext/
// criteriaSpec/gateContext are the only per-mode differences.
async function runBackHalf({ adversaryGoal, diffScope, pressureContext, criteriaSpec, gateContext }) {
  // Adversary — blast-sized lenses; folds pressure Q1/Q5 into the reasoning.
  phase('Adversary')
  const sized = await sizeLenses(diffScope)
  log(`Adversary: blast=${sized.blast} → ${sized.lenses.length} lens(es)`)
  const advResults = await parallel(sized.lenses.map((lens, i) => () =>
    smart(
      `## Adversarial verifier — lens: ${lens}\n\n${adversaryGoal}\n\n` +
      `Read the ACTUAL changed code (git diff ${BASE}...HEAD or the relevant files). ` +
      `Try HARD to find a CONCRETE way this change breaks under this lens.\n` +
      `Also answer, from this lens: what is the SINGLE strongest reason this change does NOT deliver its objective? ` +
      `(folds the old pressure-test Q1/Q5 — "how it fails" + "best reason it fails" — into the adversarial read).\n\n` +
      `Rules: real code not mocks; BLOCKING issues only (file:line + scenario); ` +
      `none → verdict="NO BLOCKING ISSUES", blocking=[]; runtime-only-undeterminable → unverifiable[] (never assert safe).`,
      { complexity: 'code', label: `adversary:lens-${i}`, phase: 'Adversary', schema: ADVERSARY_SCHEMA }
    )
  ))
  const va = advResults.filter(Boolean)
  const blocking = va.flatMap(r => r.blocking || [])
  const unverifiable = va.flatMap(r => r.unverifiable || [])
  const ran = va.length, total = sized.lenses.length
  log(`Adversary: ${ran}/${total} lenses · ${blocking.length} blocking · ${unverifiable.length} unverifiable`)
  // Completion floor: a dropped lens (tier down) is unverified, not safe.
  if (ran < Math.ceil(total * 0.75)) {
    return { verdict: 'BLOCK', reason: `adversary coverage incomplete: ${ran}/${total} lenses returned — a dropped lens is unverified, not safe. Retry when the delegate tier is healthy.`, lensesRan: ran, lensesTotal: total }
  }
  if (blocking.length) return { verdict: 'BLOCK', reason: 'adversarial issues found', blocking, unverifiable }
  if (unverifiable.length) log(`⚠️ Unverifiable (cannot prove from code): ${unverifiable.join(' | ')}`)

  // Pressure-test — NON-adversarial triad only (edge/half-resource/tenets).
  phase('Pressure-test')
  const pressure = await smart(
    `## Pressure-test — design-judgment triad${pressureContext}\n\n` +
    `The adversarial "how it fails / best reason it fails" was just covered by the refuter lenses. Answer the remaining three:\n` +
    `1. Edge cases: cold-start · empty input · concurrent runs · interrupted mid-flow · two processes at once · permission denial · stale cache.\n` +
    `2. Half-resources alternative + why this way? If the half-resource alt is almost as good, this is over-engineered — justify.\n` +
    `3. Tenets (as defined in the stress-test skill): Cover · Restructure-over-patch · Cadence · Use-cases · Fail-modes.\n\n` +
    `Verdict: SHIP (no fixable gap) · NEEDS_WORK (fixable gaps in fixes_needed) · BLOCK (fatal design miss).`,
    { complexity: 'code', label: 'pressure', phase: 'Pressure-test', schema: PRESSURE_SCHEMA }
  )
  if (!pressure) return { verdict: 'BLOCK', reason: 'pressure-test returned nothing' }
  log(`Pressure-test: ${pressure.verdict}`)
  if (pressure.verdict === 'BLOCK') return { verdict: 'BLOCK', reason: 'pressure-test fatal', fixes: pressure.fixes_needed }

  // Gate — MERGED: success-criteria check + served==built in one agent.
  phase('Gate')
  const gate = await agent(
    `## Gate-the-ship${gateContext}\n\n` +
    `Do BOTH, in order:\n` +
    `A. SUCCESS CRITERIA: ${criteriaSpec}\n` +
    `   Run each criterion's exact check command, record actual vs pass_when with REAL stdout/exit-code as evidence. ` +
    `criteria_all_met=true only if ALL pass.\n` +
    `B. SERVED==BUILT: read the deployed/running artifact's actual version (health endpoint / running container commit / process output); it must equal the intended SHA. ` +
    `Runtime-only-unverifiable → unverifiable_flags[] with an exact live-check recipe — never assert safe.\n\n` +
    `Verdict: SHIP (all criteria met AND served==built proven) · NEEDS_WORK (a criterion unmet, fixable) · BLOCK.`,
    { label: 'gate', phase: 'Gate', schema: GATE_SCHEMA, model: 'sonnet' }
  ) // delegate-considered: runs SC checks + reads running container — needs Bash
  if (!gate) return { verdict: 'NEEDS_WORK', reason: 'gate returned nothing' }
  log(`Gate: ${gate.verdict} · criteria_met=${gate.criteria_all_met} · served==built=${gate.served_equals_built}`)
  if (!gate.criteria_all_met) {
    const unmet = (gate.criteria || []).filter(c => !c.met).map(c => c.id)
    return { verdict: 'NEEDS_WORK', reason: `success criteria unmet: ${unmet.join(', ') || '(none reported)'}`, criteria: gate.criteria }
  }
  return { verdict: gate.verdict, gate, pressure, adversaryClean: blocking.length === 0, unverifiable, blast: sized.blast }
}

// ─── one manufacture pass ────────────────────────────────────────────────────
async function runManufacturePass(iter, prior = null) {
  const iterTag = MODE === 'loop' ? ` (iteration ${iter})` : ''
  const criteriaStr = CRITERIA.map(c => `  - ${c.id}: \`${c.check}\` passes when ${c.pass_when}`).join('\n')
  // loop mode: the previous pass's blockers are the first thing this pass must fix
  const priorStr = prior
    ? `\n\nPREVIOUS PASS ENDED ${prior.verdict}: ${prior.reason ?? ''}\n` +
      [...(prior.blocking || []), ...(prior.fixes || []), ...((prior.criteria || []).filter(c => !c.met).map(c => `${c.id} unmet: ${c.evidence}`))]
        .map(x => `  - ${x}`).join('\n') +
      `\nStart by diagnosing and fixing exactly these. Do not repeat the previous pass unchanged.`
    : ''

  // ── 9.1 Diagnose ──────────────────────────────────────────────────────────
  phase('Diagnose')
  const diagnosis = await agent(
    `## Diagnose${iterTag}\n\nGoal: ${GOAL}\n\nSuccess criteria:\n${criteriaStr}${priorStr}\n\n` +
    `READ the actual files (no memory). Form the hypothesis. Trace the fix end-to-end in your head. ` +
    `BEFORE claiming a gap exists, read the surface that supposedly has it — prove it is REAL (cite file:line). ` +
    `If the gap is already handled, say so (phantom gap = do not fix a non-bug). ` +
    `List exactly which files need to change and why.`,
    { label: `diagnose${iterTag}`, phase: 'Diagnose', schema: DIAGNOSIS_SCHEMA, model: 'sonnet' }
  )
  if (!diagnosis) return { verdict: 'BLOCK', reason: 'diagnosis returned nothing', iter }
  log(`Diagnose: ${diagnosis.hypothesis.slice(0, 80)}`)

  // ── 9.2 Machine into parts ────────────────────────────────────────────────
  phase('Machine')
  const machined = await agent(
    `## Machine into parts${iterTag}\n\nGoal: ${GOAL}\nDiagnosis: ${JSON.stringify(diagnosis)}\n\n` +
    `Decompose the change into PARTS, each owning exactly ONE surface. ` +
    `For each part write: FUNCTION (what exactly), BOUNDARY (owns/must-not-touch/must-preserve), PLACEMENT (file:line). ` +
    `One part = one commit. If a part needs to touch a second surface, split it into two parts.`,
    { label: `machine${iterTag}`, phase: 'Machine', schema: PARTS_SCHEMA, model: 'sonnet' }
  )
  if (!machined || !machined.parts?.length) return { verdict: 'BLOCK', reason: 'no parts produced', iter }
  log(`Machine: ${machined.parts.length} parts: ${machined.parts.map(p => p.id).join(', ')}`)

  // ── 9.3 + 9.4 + 9.5: Implement (fit-check + coupling-map + harden) ────────
  phase('Fit-check')
  const implemented = await agent(
    `## Implement (fit-check + coupling-map + harden-entries)${iterTag}\n\n` +
    `Goal: ${GOAL}\nParts spec:\n${JSON.stringify(machined.parts, null, 2)}\n\n` +
    `For each part:\n` +
    `1. BEFORE (slot check): read the EXACT file:line. Confirm interfaces/types/signatures match the spec. Fix spec if reality differs — never code against a wrong slot.\n` +
    `2. IMPLEMENT: write the code. One commit per part with tight message.\n` +
    `3. AFTER (seat check): build clean (compiler strict) + part's own tests green + FULL suite green + no-drift diff (only files in part-spec changed).\n` +
    `4. COUPLING MAP: for any shared state (Redis/DB/external API) you touch, list: set-by / read-by(far-off) / breakage-if-this-part-stops-setting-it.\n` +
    `5. HARDEN ENTRIES: for each decision branch, press each OTHER branch's inputs against it — contamination check. Defense-in-depth: ordering + per-branch guard.\n\n` +
    `A failed AFTER-check STOPS the line — do not start the next part. Rattles compound.\n` +
    `Report couplings found and how each is structurally preserved (or named if not).`,
    { label: `implement${iterTag}`, phase: 'Fit-check', schema: COUPLING_SCHEMA, model: 'sonnet' }
  )
  if (!implemented) return { verdict: 'BLOCK', reason: 'implementation returned nothing', iter }
  log(`Fit-check: ${implemented.couplings?.length ?? 0} couplings mapped`)

  // ── 9.6 + 9.7 + 9.8 back-half (shared, blast-sized, merged criteria+gate) ──
  const back = await runBackHalf({
    adversaryGoal: `Goal: "${GOAL}"`,
    diffScope: 'the current repo',
    pressureContext: iterTag,
    criteriaSpec: `${CRITERIA.length} criteria:\n${criteriaStr}`,
    gateContext: `${iterTag}\nGoal: "${GOAL}"`,
  })
  return { ...back, iter }
}

// ─── assemble mode (consume a manuf-product-design pack) ──────────────────────
// The workflow is a PURE ORCHESTRATOR here: it reads the pack, verifies the
// exported mocks, dispatches each component by tier (smart()), fit-checks each
// (halt-on-red), then runs the adversary/pressure/gate back-half on the whole.
// It NEVER re-designs; a red check HALTS and reports so the user fixes the
// pack. Diagnose + Machine are skipped — the pack owns them.

const MANIFEST_SCHEMA = {
  type: 'object', required: ['components'],
  properties: {
    feature: { type: 'string' },
    components: { type: 'array', items: {
      type: 'object', required: ['id', 'spec', 'tier', 'order'],
      properties: {
        id: { type: 'string' }, surface: { type: 'string' }, spec: { type: 'string' },
        tier: { enum: ['cheap', 'code', 'adversarial', 'native'] },
        deps: { type: 'array', items: { type: 'string' } },
        order: { type: 'integer' },
        checks: { type: 'array', items: { type: 'string' } },
        status: { type: 'string' },
        evidence: { type: 'string' },
      },
    }},
    ui_screens: { type: 'array', items: {
      type: 'object', required: ['id', 'name'],
      properties: { id: { type: 'string' }, name: { type: 'string' },
        mock: { type: 'string' }, data_contract: { type: 'string' } },
    }},
  },
}
const COMPONENT_RESULT_SCHEMA = {
  type: 'object', required: ['id', 'status', 'evidence'],
  properties: {
    id: { type: 'string' },
    status: { enum: ['GREEN', 'RED'] },
    evidence: { type: 'string', description: 'Actual command output — fit-check BEFORE + AFTER, not a summary' },
    commit: { type: 'string' },
  },
}

async function runAssemble() {
  // 1. Validate the pack (structural gate) before touching anything.
  phase('Validate pack')
  const val = await agent(
    `Validate the manuf-product-design pack at \`${PACK}\`. Run \`bash ~/.claude/hooks/manuf-pack-validate.sh ${PACK}\` and report its exit code + output verbatim. ` +
    `If it exits non-zero, the pack is not zero-decision — return status="INVALID" with the exact failing field.`,
    { label: 'validate-pack', phase: 'Validate pack', schema: {
      type: 'object', required: ['status', 'detail'],
      properties: { status: { enum: ['VALID', 'INVALID'] }, detail: { type: 'string' } } } }
  ) // delegate-considered: runs the validator hook via Bash — needs tool access
  if (!val || val.status !== 'VALID') {
    return { verdict: 'BLOCK', reason: 'pack failed structural validation', detail: val?.detail }
  }

  // 1b. HARD START — manuf-design-qa ≥ A before any dispatch (stamp under pack/.qa/).
  //     The stamp is the gate; the judgment lives in the /manuf-design-qa skill.
  phase('Plan QA (manuf-design-qa)')
  const dqaCheck = await agent(
    `HARD START GATE for assemble of pack \`${PACK}\`.\n` +
    `1. Run: \`bash ~/.claude/hooks/manuf-qa-stamp.sh check design-qa ${PACK} --min=A\`\n` +
    `   If PASS, return status="PASS" with the command stdout as detail.\n` +
    `2. If FAIL (missing stamp or grade < A):\n` +
    `   a. Load the manuf-design-qa skill (~/.claude/skills/manuf-design-qa/SKILL.md).\n` +
    `   b. Run full plan-side QA on the pack (read pack files; no memory scoring).\n` +
    `   c. Write the grade stamp: \`bash ~/.claude/hooks/manuf-qa-stamp.sh write design-qa ${PACK} <GRADE> --notes='assemble-start'\`\n` +
    `      where <GRADE> is A+++|A|B|C|F from the skill rubric.\n` +
    `   d. Re-run check. If still < A, return status="FAIL" (do NOT dispatch components).\n` +
    `Return status PASS only when check exits 0.`,
    { label: 'plan-qa-design', phase: 'Plan QA (manuf-design-qa)', schema: {
      type: 'object', required: ['status', 'grade', 'detail'],
      properties: {
        status: { enum: ['PASS', 'FAIL'] },
        grade: { type: 'string', description: 'A+++|A|B|C|F' },
        detail: { type: 'string' },
      } } }
  ) // delegate-considered: stamp check + optional skill run — needs Bash + Read
  if (!dqaCheck || dqaCheck.status !== 'PASS') {
    return {
      verdict: 'BLOCK',
      reason: 'manuf-design-qa start gate: grade < A or stamp missing — fix pack via manuf-product-design, re-QA, then reassemble',
      grade: dqaCheck?.grade,
      detail: dqaCheck?.detail,
    }
  }
  log(`Plan QA: design-qa grade=${dqaCheck.grade} PASS — assemble may proceed`)

  // 2. Read manifest.json (the machine contract — deterministic, not prose).
  const man = await agent(
    `Read \`${PACK}/manifest.json\` and return it parsed. This is the build contract.`,
    { label: 'read-manifest', phase: 'Validate pack', schema: MANIFEST_SCHEMA }
  )
  if (!man || !man.components?.length) return { verdict: 'BLOCK', reason: 'manifest has no components' }
  const components = [...man.components].sort((x, y) => x.order - y.order)
  const screens = man.ui_screens || []
  log(`assemble: ${components.length} components · ${screens.length} UI screens · pack=${PACK}`)

  // 3. UI screens. Mocks are LOCKED in Phase 0 and exported into <pack>/design/ —
  //    assemble only VERIFIES they exist (the validator gated the lock stamps)
  //    and implements them. It never generates designs.
  const mocked = screens.filter(s => s.mock)
  if (mocked.length) {
    phase('Design (verify mocks)')
    const v = await agent(
      `Verify the exported Phase 0 mocks for pack \`${PACK}\`. For each path below, run \`test -f ${PACK}/<path> && echo OK <path> || echo MISSING <path>\`:\n` +
      mocked.flatMap(s => [s.mock, s.data_contract].filter(Boolean)).map(p => `- ${p}`).join('\n') +
      `\nReport verbatim output.`,
      { label: 'verify-mocks', phase: 'Design (verify mocks)', schema: {
        type: 'object', required: ['all_present', 'detail'],
        properties: { all_present: { type: 'boolean' }, detail: { type: 'string' } } } }
    ) // delegate-considered: filesystem checks — needs native tools
    if (!v?.all_present) return { verdict: 'BLOCK', reason: 'exported mock/data_contract missing — Phase 0 gate #2 incomplete; fix the pack', detail: v?.detail }
    log(`mocks verified: ${mocked.length} screen(s), data contract present`)
  }
  // 4. Walk the DAG. Dispatch each component by its tier tag. Fit-check BEFORE + AFTER. A RED check HALTS the line.
  phase('Build (dispatch)')
  const done = new Set()
  const built = []
  // Manifest components already marked status:"done" (shipped in a prior run/PR,
  // evidence recorded) satisfy deps without re-dispatch — re-verifying them against
  // a spec's baked-in PRECONDITIONS baseline false-BLOCKs once the baseline drifts
  // (the file is already at the target state, so "reality == pre-edit baseline"
  // trips even though the component is genuinely finished). Require non-empty
  // evidence, not just the status string, so a bare status:"done" with no audit
  // trail still gets re-verified for real.
  for (const c of components) {
    if (c.status === 'done' && c.evidence && String(c.evidence).trim().length >= 10) {
      done.add(c.id)
      log(`Component ${c.id}: SKIP (status:done, evidence on file)`)
    }
  }
  for (const c of components) {
    if (done.has(c.id)) continue
    const unmet = (c.deps || []).filter(d => !done.has(d))
    if (unmet.length) return { verdict: 'BLOCK', reason: `component ${c.id} depends on unbuilt ${unmet.join(',')} — manifest DAG order is wrong` }

    // Pass the spec path, not the spec body — the executor reads it in its own
    // context. Pattern from gsd-build/get-shit-done (MIT).
    const buildPrompt =
      `## Build component ${c.id}${c.surface ? ` (${c.surface})` : ''}\n\n` +
      `Read the zero-decision spec at \`${PACK}/${c.spec}\`. It has zero degrees of freedom — 7 fields:\n` +
      `PLACEMENT (exact file:line) · CODE (verbatim) · COMMANDS (exact) · EXPECTED (exact output) · PRECONDITIONS · POSTCONDITIONS · STOP.\n\n` +
      `Execute EXACTLY:\n` +
      `1. FIT-CHECK BEFORE: verify PRECONDITIONS — read the exact slot (file:line), confirm it matches the spec. ` +
      `A precondition file path is checked AT THE PATH THE SPEC WRITES (resolve \`~\`/\`$HOME\` to the real home directory) — do NOT restrict the check to the working directory. Use \`ls <abs-path>\` / \`test -f <abs-path>\`, never a cwd-scoped \`find\` for a file the spec locates outside the cwd. ` +
      `If reality ≠ spec, STOP with status="RED" (do NOT code against a wrong slot; the planner must fix the pack).\n` +
      `2. APPLY: write the verbatim CODE at the PLACEMENT. One commit, tight message. Touch ONLY files the spec names (no-drift).\n` +
      `3. FIT-CHECK AFTER: run each COMMAND, diff actual output against EXPECTED, verify all POSTCONDITIONS (binary). Any mismatch → status="RED".\n` +
      `4. If the STOP condition triggers at any point → status="RED", halt.\n\n` +
      `Do NOT improvise, do NOT redesign, do NOT expand scope. You are a typist executing a proven spec. ` +
      (CWD ? `ALL paths in the spec (PLACEMENT, COMMANDS) are relative to "${CWD}" — cd there first; the spec file is at the absolute path given above. ` : '') +
      `Return status="GREEN" only if every postcondition passed with evidence = the real command output.`

    let res
    if (c.tier === 'native') {
      // needs THIS repo's context + multi-step tools → Claude in-session (Sonnet)
      res = await agent(buildPrompt, { label: `build:${c.id}`, phase: 'Build (dispatch)', schema: COMPONENT_RESULT_SCHEMA, model: 'sonnet' })
    } else {
      res = await smart(buildPrompt, { complexity: c.tier, label: `build:${c.id}`, phase: 'Build (dispatch)', schema: COMPONENT_RESULT_SCHEMA })
    }

    // A cheap worker can return status:'GREEN' while omitting the evidence, or
    // a timeout returns null. Enforce the full contract, not just the status
    // field: no GREEN is trusted without an evidence trail.
    const bad = !res || res.status !== 'GREEN' || !res.evidence || String(res.evidence).trim().length < 10
    if (bad) {
      const why = !res ? 'null result (tier timeout/exhausted)'
        : res.status !== 'GREEN' ? `status=${res.status}`
        : 'GREEN but missing evidence trail (audit-incomplete → treated as RED)'
      log(`Component ${c.id}: RED — HALT (${why})`)
      return { verdict: 'BLOCK', reason: `component ${c.id} fit-check RED: ${why}`, failedComponent: c.id, evidence: res?.evidence, built }
    }
    done.add(c.id); built.push(c.id)
    log(`Component ${c.id}: GREEN (${built.length}/${components.length})`)
  }

  // 5. HARD END — manuf-qa ≥ A before adversary/merge (stamp under pack/.qa/).
  //    Build/runtime fidelity; plan gaps already gated at start.
  phase('Build QA (manuf-qa)')
  const mqaCheck = await agent(
    `HARD END GATE (pre-merge) for assembled pack \`${PACK}\`.\n` +
    `1. Load the manuf-qa skill (~/.claude/skills/manuf-qa/SKILL.md).\n` +
    `2. Run full build/runtime QA on pack + built code (env=local unless staging URL known).\n` +
    `3. Write stamp: \`bash ~/.claude/hooks/manuf-qa-stamp.sh write manuf-qa ${PACK} <GRADE> --env=local --notes='post-assemble pre-merge'\`\n` +
    `4. Run: \`bash ~/.claude/hooks/manuf-qa-stamp.sh check manuf-qa ${PACK} --min=A\`\n` +
    `Return status PASS only if grade ≥ A and check exits 0. If FAIL, list top findings — do NOT claim merge-ready.`,
    { label: 'build-qa-manuf', phase: 'Build QA (manuf-qa)', schema: {
      type: 'object', required: ['status', 'grade', 'detail'],
      properties: {
        status: { enum: ['PASS', 'FAIL'] },
        grade: { type: 'string' },
        detail: { type: 'string' },
      } } }
  ) // delegate-considered: full QA + stamp — needs Bash/Read/grep
  if (!mqaCheck || mqaCheck.status !== 'PASS') {
    return {
      verdict: 'BLOCK',
      reason: 'manuf-qa merge gate: grade < A — fix build/data/design drift, re-run /manuf-qa, then re-gate before merge',
      grade: mqaCheck?.grade,
      detail: mqaCheck?.detail,
      pack: PACK,
      built,
    }
  }
  log(`Build QA: manuf-qa grade=${mqaCheck.grade} PASS — may proceed to adversary + merge path`)

  // 6. Back-half (adversary / pressure / gate) on the assembled whole (shared helper, blast-sized).
  //    The pack's design is now real code — adversary verifies it against LIVE
  //    reality the planner was blind to; pressure-test finds objective gaps; the
  //    merged gate checks SC + proves served==built + re-checks manuf-qa stamp.
  const assembledGoal = `assembled pack ${PACK} (${built.length} components: ${built.join(', ')})`
  const back = await runBackHalf({
    adversaryGoal:
      `Goal: build the pack at "${PACK}". ` +
      `The design came from a planner BLIND to the live runtime — find what it could not see from a plan.`,
    diffScope: 'the current repo',
    pressureContext: ` on ${assembledGoal}`,
    criteriaSpec:
      `Read the pack's \`${PACK}/spec.md\` ## Success Criteria and \`${PACK}/verification.md\`. ` +
      `Run each measurable criterion (the exact check command); record actual vs pass_when. ` +
      `Also require: \`bash ~/.claude/hooks/manuf-qa-stamp.sh check manuf-qa ${PACK} --min=A\` exits 0 (pre-merge floor).`,
    gateContext: ` for ${assembledGoal}. Before SHIP: re-confirm manuf-qa stamp ≥ A (merge floor). Prod deploy later needs A+++.`,
  })
  return { ...back, pack: PACK, built, designQa: dqaCheck.grade, manufQa: mqaCheck.grade }
}

// ─── main ────────────────────────────────────────────────────────────────────
log(`manufacture: mode=${MODE} ${MODE === 'assemble' ? `pack="${PACK}"` : `goal="${GOAL.slice(0, 60)}" criteria=${CRITERIA.length}`} lenses=${LENS_OVERRIDE ? LENS_OVERRIDE.length + ' (override)' : 'blast-sized 2–5'}`)

if (MODE === 'assemble') {
  return runAssemble()
}

if (MODE === 'single') {
  return runManufacturePass(1)
}

// loop mode
let lastResult = null
for (let i = 1; i <= MAX_ITERS; i++) {
  if (budget.total && budget.remaining() < MIN_BUDGET) {
    log(`Budget floor hit (${MIN_BUDGET} remaining) at iteration ${i} — stopping`)
    return { status: 'capped', reason: 'budget', iter: i, lastResult }
  }
  lastResult = await runManufacturePass(i, lastResult)
  if (lastResult.verdict === 'SHIP') {
    log(`SHIP at iteration ${i}`)
    return { status: 'done', ...lastResult }
  }
  if (lastResult.verdict === 'BLOCK') {
    log(`BLOCK at iteration ${i}: ${lastResult.reason}`)
    if (i === MAX_ITERS) break
    log(`Fixing blockers and retrying (${MAX_ITERS - i} iterations left)...`)
  }
  if (lastResult.verdict === 'NEEDS_WORK') {
    log(`NEEDS_WORK at iteration ${i}: ${lastResult.reason ?? ''}`)
    if (i === MAX_ITERS) break
  }
}

return { status: 'capped', reason: 'max-iters', maxIters: MAX_ITERS, lastResult }
