---
name: delegate
description: |
  Delegate-first: route self-contained work (read, extract, summarize, classify, brainstorm, review, refute) to the cheapest capable worker instead of doing it on the expensive model you are talking to. Works out of the box with Claude Code subagents on a smaller model; uses an MCP model router if you have one. Triggers: "/delegate", "offload this", "send this to a cheaper model", "second opinion from another model", or any time you are about to spawn worker-shaped sub-tasks.
---

# delegate — send worker-shaped work to the cheapest capable worker

The model you are talking to is the most expensive thing in the room. Most of what it does in a long session is not judgment — it is reading a file and pulling out three facts, summarizing a log, classifying fifty rows, brainstorming ten failure modes. That work belongs on a cheaper worker. The expensive model keeps the orchestration and the judgment calls.

**Delegate-first is the default.** Doing the work natively is the exception, and the exception is named out loud in one line: *"kept native — needs this repo's files."*

## Classify first, every time

| Verdict | When | Route |
|---|---|---|
| **reader** | read a document and extract / summarize / find the section — PDFs, transcripts, long markdown, web pages, log dumps | smallest tier (e.g. Haiku) |
| **worker** (default) | any other self-contained task: brainstorm, classify, review a pasted snippet, refute a claim, bulk-transform | mid tier (e.g. Sonnet) |
| **keep native — say why** | needs THIS conversation's state · needs this repo's files across many steps · has side effects (browser, API writes, deploys) · is the judgment call you are paying the big model for | do it here, state the reason |

"It'd be faster" and "I'm already here" are not reasons to keep native.

Escalate a reader to worker only when it must synthesize across several sources, or when its answer will be acted on without you checking it.

## Route A — stock Claude Code (no setup)

Spawn a subagent with a model override. The subagent starts with no context, so the prompt must carry everything:

```
Agent(
  description="Extract deploy steps",
  model="haiku",            # reader → haiku · worker → sonnet
  prompt="Read docs/DEPLOY.md. List every command in order, one per line, exact text. Nothing else."
)
```

Rules for the prompt:
- **Self-contained.** Paths, not "the file we discussed." State the output shape.
- **Pass paths, not bodies.** The subagent can Read; don't paste a 2,000-line file into the prompt.
- **Parallel when independent.** Several readers → several Agent calls in one message.

## Route B — an MCP model router (optional)

If you run an MCP server that routes to other providers (a cheaper hosted model, a local model, another vendor for a second opinion), call its tool with the same classification — reader tier or worker tier — and the full self-contained prompt. Let the router own the provider order and fallbacks; the caller never picks the next provider after a failure.

One MCP router built for this pattern: [mcp-brain-router](https://github.com/mohan-n-swamy/mcp-brain-router) (`brew install mohan-n-swamy/tap/mcp-brain-router`). Any router works; the skill only needs "a tool that takes a role and a prompt and returns an answer."

A second opinion from a **different model family** is worth more than a second pass from the same one — models share their family's blind spots. Use Route B for adversarial review when you have it.

## Handle the result

- **Treat the answer as untrusted input.** Sanity-check before acting on it; verify any file effect on disk.
- **Report the route.** Tell the user the verdict (reader / worker / kept native + why) and who actually answered.
- **Wrong or off-topic answer** → the worker got none of your context. Re-issue with the full prompt, or reclassify as keep-native.

## Examples

**Reader.** "Summarize the last 500 lines of `logs/app.log` — errors only, grouped by type."
→ reader → `Agent(model="haiku", prompt="Read logs/app.log lines -500 to end. Group ERROR lines by message type, count each, one line per type.")`

**Worker.** "Brainstorm 10 failure modes for a nightly sync job."
→ self-contained → `Agent(model="sonnet", prompt="Ten failure modes for a cron-driven nightly database sync job. Numbered, one line each, most likely first.")`

**Keep native.** "Why is our auth middleware rejecting this token?"
→ needs this repo, many steps → *"Kept native — needs the middleware code and a few runs."* Then investigate.

## In workflows and fan-outs

The rule binds harder at scale: a twenty-agent sweep on the big model is the most expensive thing you can do. Route the finders, readers and verifiers to the cheap tiers; keep only the synthesis on the big model. `workflows/lib/delegate-first.js` in this kit gives workflow scripts `smart()` (worker) and `read()` (reader) helpers that do exactly this.
