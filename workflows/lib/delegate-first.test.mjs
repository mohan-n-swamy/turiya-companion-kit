// Checks that smart()/read() pick the right tier and pass options through.
// Run: node workflows/lib/delegate-first.test.mjs
import { createRequire } from 'node:module'
const require = createRequire(import.meta.url)
const { smart, read } = require('./delegate-first.js')

let pass = 0, fail = 0
const ok = (name, cond) => { cond ? pass++ : fail++; console.log(`  ${cond ? 'ok' : 'FAIL'} - ${name}`) }

let last = null
globalThis.agent = async (prompt, opts) => { last = { prompt, opts }; return { answer: 'STUB' } }

const r = await smart('Brainstorm 5 ideas')
ok('worker runs on sonnet', last.opts.model === 'sonnet')
ok('task passed verbatim (no router)', last.prompt === 'Brainstorm 5 ideas')
ok('default label', last.opts.label === 'delegate:worker')
ok('returns agent result', r.answer === 'STUB')

const schema = { type: 'object' }
await smart('review', { schema, label: 'L', phase: 'P' })
ok('schema passes through', last.opts.schema === schema)
ok('label passes through', last.opts.label === 'L')
ok('phase passes through', last.opts.phase === 'P')

await read('Summarize this transcript')
ok('reader runs on haiku', last.opts.model === 'haiku')
ok('reader label', last.opts.label === 'delegate:read')

let threw = false
try { await smart('x', { role: 'thinker' }) } catch { threw = true }
ok('rejects unknown role', threw)

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail ? 1 : 0)
