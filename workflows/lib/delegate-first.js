// delegate-first.js — send worker-shaped stages of a Workflow script to the
// cheapest capable worker, not to the expensive model running the workflow.
//
// WHAT IT IS FOR
//   A Claude Code Workflow script orchestrates many agent() calls. Most of them
//   are volume work — read a file, extract fields, review a diff from one angle.
//   Running all of them on the top model is the most expensive thing you can do.
//   These helpers pick the tier for you:
//
//     smart(task)  worker stage (review, refute, classify, bulk-transform) → Sonnet
//     read(task)   reader stage (read / extract / summarize a document)    → Haiku
//     agent(task)  keep raw agent() for stages that need THIS repo across many
//                  tool steps — and say why in a comment
//
// OPTIONAL MODEL ROUTER
//   If you run an MCP model router (any server exposing a tool that takes a role
//   and a prompt — e.g. mcp-brain-router), set ROUTER_TOOL below to that tool's
//   name. smart()/read() then ask the subagent to route through it, which lets a
//   different model family do the work (useful for adversarial review: models
//   share their own family's blind spots). Leave it null and everything runs on
//   Claude subagents with no setup.
//
// USAGE — Workflow scripts cannot import, so paste this body at the top of the
// script (workflows/manufacture.js does exactly that):
//   const findings = await smart(reviewPrompt, { schema: FINDINGS })
//   const facts    = await read('Read docs/DEPLOY.md and list every command')
//   const map      = await agent('Map the auth code in THIS repo', { schema: MAP }) // repo-context stage

const ROUTER_TOOL = null // e.g. 'mcp__brain-router__delegate'

const TIERS = { worker: 'sonnet', reader: 'haiku' }

/**
 * @param {string} task      Full, self-contained prompt. The worker sees nothing else.
 * @param {object} [opts]
 * @param {'worker'|'reader'} [opts.role='worker']
 * @param {object} [opts.schema]  JSON Schema for structured output.
 * @param {string} [opts.label]   Display label.
 * @param {string} [opts.phase]   Progress group.
 */
async function smart(task, opts = {}) {
  const { role = 'worker', schema, label, phase } = opts
  if (!(role in TIERS)) throw new Error(`smart(): role must be worker|reader, got "${role}"`)
  const prompt = ROUTER_TOOL
    ? `Call the ${ROUTER_TOOL} tool once with role="${role}", the current absolute working directory as cwd, ` +
      `and the task below passed verbatim. If it errors, do the task yourself and say so.\n\n` +
      `TASK:\n<<<\n${task}\n>>>\n\nReturn ONLY the task answer.`
    : task
  return agent(prompt, {
    schema,
    model: TIERS[role],
    label: label ?? `delegate:${role}`,
    ...(phase ? { phase } : {}),
  })
}

/** Reader lane: document read / extract / summarize. Pins the smallest tier. */
async function read(task, opts = {}) {
  return smart(task, { ...opts, role: 'reader', label: opts.label ?? 'delegate:read' })
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { smart, read, TIERS }
}
