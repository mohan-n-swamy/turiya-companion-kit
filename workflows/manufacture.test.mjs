// Runs the REAL workflows/manufacture.js with stubbed Workflow globals
// (agent, parallel, phase, log, budget, args) and checks its gates.
// Run: node workflows/manufacture.test.mjs
import { readFileSync } from 'node:fs'

const src = readFileSync(new URL('./manufacture.js', import.meta.url), 'utf8')
  .replace(/^export const meta = /m, 'const meta = ')
const AsyncFunction = Object.getPrototypeOf(async () => {}).constructor

// respond(prompt, opts) decides what each stubbed agent() call returns.
async function run(args, respond) {
  const calls = []
  const agent = async (prompt, opts = {}) => { calls.push({ prompt, opts }); return respond(prompt, opts) }
  const parallel = async fns => Promise.all(fns.map(f => f()))
  const fn = new AsyncFunction('args', 'agent', 'parallel', 'phase', 'log', 'budget', src)
  const result = await fn(args, agent, parallel, () => {}, () => {}, { total: 0, remaining: () => Infinity })
  return { result, calls }
}

let pass = 0, fail = 0
const ok = (name, cond) => { cond ? pass++ : fail++; console.log(`  ${cond ? 'ok' : 'FAIL'} - ${name}`) }

const PACK = '/repo/specs/001-demo'
const manifest = {
  components: [
    { id: 'C1', spec: 'components/C1.md', tier: 'cheap', order: 1 },
    { id: 'C2', spec: 'components/C2.md', tier: 'code', deps: ['C1'], order: 2 },
  ],
  ui_screens: [],
}
// A happy-path responder; override one label to inject a failure.
const happy = (over = {}) => (prompt, opts) => {
  const l = opts.label || ''
  if (over[l]) return over[l]
  if (l === 'validate-pack') return { status: 'VALID', detail: 'ok' }
  if (l === 'plan-qa-design') return { status: 'PASS', grade: 'A', detail: 'ok' }
  if (l === 'read-manifest') return manifest
  if (l.startsWith('build:')) return { id: l.slice(6), status: 'GREEN', evidence: 'all postconditions passed' }
  if (l === 'build-qa-manuf') return { status: 'PASS', grade: 'A', detail: 'ok' }
  if (l === 'blast-probe') return { shared_state_hits: 0 }
  if (l.startsWith('adversary')) return { blocking: [], verdict: 'NO BLOCKING ISSUES' }
  if (l === 'pressure') return { verdict: 'SHIP' }
  if (l === 'gate') return { verdict: 'SHIP', criteria_all_met: true, served_equals_built: true }
  return null
}
const A = { mode: 'assemble', pack: PACK, cwd: '/repo' }

// 1. happy path ships, and each tier lands on the right model
{
  const { result, calls } = await run(A, happy())
  ok('assemble happy path → SHIP', result.verdict === 'SHIP')
  ok('cheap component runs on haiku', calls.find(c => c.opts.label === 'build:C1')?.opts.model === 'haiku')
  ok('code component runs on sonnet', calls.find(c => c.opts.label === 'build:C2')?.opts.model === 'sonnet')
  ok('worker prompt carries the cwd', calls.find(c => c.opts.label === 'build:C1')?.prompt.includes('/repo'))
}
// 2. invalid pack blocks before any build
{
  const { result, calls } = await run(A, happy({ 'validate-pack': { status: 'INVALID', detail: 'C1 missing STOP' } }))
  ok('invalid pack → BLOCK', result.verdict === 'BLOCK')
  ok('no component dispatched', !calls.some(c => (c.opts.label || '').startsWith('build:')))
}
// 3. plan QA below A blocks before any build
{
  const { result, calls } = await run(A, happy({ 'plan-qa-design': { status: 'FAIL', grade: 'B', detail: 'journey gap' } }))
  ok('design-qa < A → BLOCK', result.verdict === 'BLOCK' && result.grade === 'B')
  ok('no component dispatched after failed plan QA', !calls.some(c => (c.opts.label || '').startsWith('build:')))
}
// 4. a RED component halts the line; the next one never runs
{
  const { result, calls } = await run(A, happy({ 'build:C1': { id: 'C1', status: 'RED', evidence: 'precondition mismatch' } }))
  ok('RED component → BLOCK', result.verdict === 'BLOCK' && result.failedComponent === 'C1')
  ok('C2 never dispatched', !calls.some(c => c.opts.label === 'build:C2'))
}
// 5. GREEN without evidence is treated as RED
{
  const { result } = await run(A, happy({ 'build:C1': { id: 'C1', status: 'GREEN', evidence: '' } }))
  ok('GREEN with no evidence → BLOCK', result.verdict === 'BLOCK')
}
// 6. build QA below A blocks before adversary
{
  const { result, calls } = await run(A, happy({ 'build-qa-manuf': { status: 'FAIL', grade: 'C', detail: 'dummy data' } }))
  ok('manuf-qa < A → BLOCK', result.verdict === 'BLOCK' && result.grade === 'C')
  ok('no adversary after failed build QA', !calls.some(c => (c.opts.label || '').startsWith('adversary')))
}
// 7. an adversary finding blocks the ship
{
  const { result } = await run(A, happy({ 'adversary:lens-0': { blocking: ['auth.ts:12 bypass'], verdict: 'BLOCKING ISSUES FOUND' } }))
  ok('blocking adversary finding → BLOCK', result.verdict === 'BLOCK' && result.blocking?.length === 1)
}
// 8. loop mode feeds pass 1's blocker into pass 2's Diagnose, then ships
{
  let pass1 = true
  const L = { mode: 'loop', goal: 'fix the cache', criteria: [{ id: 'SC1', check: 'npm test', pass_when: 'exit 0' }], maxIters: 3 }
  const { result, calls } = await run(L, (prompt, opts) => {
    const l = opts.label || ''
    if (l.startsWith('diagnose')) return { hypothesis: 'h', root_cause: 'r', files_to_read: [], phantom_gap_check: 'p' }
    if (l.startsWith('machine')) return { parts: [{ id: 'P1', function: 'f', boundary: { owns: 'a', must_not_touch: 'b', must_preserve: 'c' }, placement: 'x:1' }] }
    if (l.startsWith('implement')) return { couplings: [] }
    if (l === 'blast-probe') return { shared_state_hits: 0 }
    if (l === 'adversary:lens-0' && pass1) { pass1 = false; return { blocking: ['cache.ts:9 stale key survives restart'], verdict: 'BLOCKING ISSUES FOUND' } }
    if (l.startsWith('adversary')) return { blocking: [], verdict: 'NO BLOCKING ISSUES' }
    if (l === 'pressure') return { verdict: 'SHIP' }
    if (l === 'gate') return { verdict: 'SHIP', criteria_all_met: true, served_equals_built: true, criteria: [{ id: 'SC1', met: true, evidence: 'exit 0' }] }
    return null
  })
  const d2 = calls.find(c => c.opts.label === 'diagnose (iteration 2)')
  ok('loop: second pass ran', !!d2)
  ok('loop: pass 2 Diagnose carries pass 1 blocker', !!d2 && d2.prompt.includes('cache.ts:9 stale key survives restart'))
  ok('loop: ships on pass 2', result.status === 'done' && result.verdict === 'SHIP')
}
// 9. argument validation
{
  const { result } = await run({ mode: 'assemble' }, happy())
  ok('assemble without pack → error', !!result.error)
  const r2 = await run({ mode: 'single', goal: 'x' }, happy())
  ok('single without criteria → error', !!r2.result.error)
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail ? 1 : 0)
