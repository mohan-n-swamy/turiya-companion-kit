# turiya-companion-kit

Working Claude Code skills and hooks from the book — the actual files, not screenshots of them.

## What this is

The companion kit to the book's chapters 8 and 10. Chapter 8 shows two of these skills being built; chapter 10 tells you to stop reading and install them. This repo is the install: **twenty-seven skills and six hooks**, sanitized from the author's daily rig, that turn Claude Code from a code generator into a working partner with opinions, rituals, and memory.

These are not demos. Every skill here ran (and runs) in the author's setup daily. What you get is the generic version — the machinery without the author's vault paths, employer references, and home-grown automation glued to it.

The skills are advice the model chooses to follow. The hooks are not: they are shell scripts the harness runs, and they block. That difference is the whole reason the hooks are in this repo.

## Prereqs

- [Claude Code](https://claude.com/claude-code) installed and working (`claude` on your PATH)
- A terminal. That's it — no plugins, no MCP servers, no note-taking app required. The daily-ritual skills assume only "a folder of markdown notes, one per day."

## Install

```sh
git clone https://github.com/mohan-n-swamy/turiya-companion-kit.git
cd turiya-companion-kit
./install.sh              # skills only
./install.sh --hooks      # skills and hooks
```

`install.sh` copies each skill into `~/.claude/skills/`. It refuses to overwrite a skill directory you already have — delete yours first if you want the kit's version. Interrupted install? Delete that skill's folder and re-run.

Windows: run `install.sh` from Git Bash (ships with Git for Windows) or WSL. No shell? Manual install works everywhere: copy each folder inside `skills/core/` into `~/.claude/skills/` (Windows: `%USERPROFILE%\.claude\skills`).

Restart Claude Code (or start a new session) and the skills are live: `/council`, `/stress-test`, `/morning`, and so on.

## Making the always-on skills actually always-on

`brutal-honesty`, `human-proofing`, and `antifragile-advisor` are written as always-on, but on a stock install a skill fires when the model matches your request to its description — which is most of the time, not all of the time. To make them genuinely always-on, add this line to your `~/.claude/CLAUDE.md`:

> Apply the brutal-honesty and human-proofing skills to every interaction; use antifragile-advisor whenever I propose a plan or decision.

## Your first session

1. `cd` into the folder you want as your notes home.
2. Run `/morning` — it will ask where your daily notes should live, then propose your Top 3.
3. Tomorrow evening, run `/nightly` to close the day.
4. This week, run `/council` on one real decision you're actually facing.
5. Ignore the other twenty-four skills until these three are habits.

## The skills

One honest line each.

### Discipline and judgment

- **brutal-honesty** — the coworker pact: verified evidence over plausible guesses, bad news first, no "should work." The skill the newsletter readers asked for most.
- **antifragile-advisor** — always-on analysis partner that surfaces what's usually thin in a plan of this shape, then hands you the judgment instead of faking an oracle.
- **council** — five advisors trained to disagree (Contrarian, First Principles, Expansionist, Outsider, Executor), peer-review, then a chairman synthesis with a dissent log. For decisions, not lookups.
- **stress-test** — the post-design gate: five questions ending with "the best reason this doesn't deliver," looped until it holds. Includes the pass@k reliability gate for LLM-shaped designs.
- **steal-ladder** — adopt other people's mechanisms without becoming a tool hoarder: see → record → evaluate → lift the piece → adapt → attribute.
- **spec** — scaffold a durable on-disk feature spec that starts with the end: end-state and success criteria written before a single task.

### Writing

- **bluf** — bottom line up front. The answer in the first sentence, before context, reasoning, or caveats. Includes the test: delete everything after sentence one — does the reader still know what to do?
- **writing-style** — voice, mechanics, and structure canon (Minto, Hemingway, Made to Stick). Shipped as a template: the mechanics transfer, the voice section you must rewrite as your own.
- **human-proofing** — detects the AI tells in writing (em-dash rash, parallelism addiction, the missing mess) and coaches you to add human texture instead of fixing it for you.

### Thinking lenses

Each is a working synthesis of a field's best books — the rules, not the books. Every one ends with the reading list.

- **engineering** — manage complexity, design data systems, ship fast and stable, pragmatic craft.
- **product** — discovery over delivery, outcomes over output, the four product risks.
- **strategy** — strategy as an integrated set of choices, plus the mechanisms that force it into execution.
- **operations** — flow, variation, standardization, checklists, root cause.
- **data-fluency** — frame the question, analyse honestly, pick the metric, communicate the insight.
- **customer-experience** — reduce effort, design the journey, build loyalty.
- **systems-thinking** — stop fixing symptoms; find the structure producing them.
- **negotiation** — tactical empathy: mirroring, labeling, calibrated questions, getting to a real "no."
- **learning** — learn a hard skill fast and crack a hard problem cleanly.

### Method and research

- **deep-research** — fan-out searches, fetch real sources, adversarially try to kill every claim, ship only what survived — cited.
- **book-distill** — turn a book you own into a grounded on-demand skill: extract, synthesize chapter by chapter, build the index. Folds by domain, never one skill per book.
- **defuddle** — strip a web page to clean markdown before reading it, instead of paying tokens for navigation and cookie banners.
- **legal-plain** — plain-English read of a contract: what you're agreeing to, the three riskiest clauses, what's missing, what to ask before signing. Comprehension, not advice.
- **capture-lesson** — after every bug or incident, one append-only numbered lesson in the repo. The cheapest compound interest in this kit.

### Rituals and continuity

- **session-ladder** — park / resume / wrap-up as a pattern: stamp where you are, pick up the freshest stamp, rebase the docs when done. Plain files, no tooling.
- **morning** — reads yesterday's and today's daily notes, proposes a Top 3 with reasoning, surfaces the decisions the day actually needs.
- **nightly** — the evening transform: what happened on top, the morning plan demoted to reference, every pushed task gets a "why," tomorrow gets seeded tonight.
- **triage-inbox** — drains your capture inbox ten files at a time, one human decision per file. Matuschak: inboxes only work if you trust how they're drained.

## The hooks

A skill is a rule the model may follow. A hook is a rule it cannot route around — the harness runs the script, reads the exit code, and blocks on 2. Six of them ship here.

Install with `./install.sh --hooks`. The installer copies the files and **prints** the `settings.json` wiring for you to paste. It does not edit your settings — a hook that installs itself into your config without asking is precisely the behaviour these hooks exist to stop.

| Hook | Event | What it does |
|---|---|---|
| `claim-vgate.sh` | Stop | Blocks the turn if you claimed something is deployed, verified, works, or exists in the data and the session transcript contains no evidence for it. Four claim categories, each with its own evidence pattern. |
| `dep-gate.sh` | PreToolUse (Write/Edit) | Blocks an edit that adds a line to a dependency manifest until you reply `dep-ok`. Rung 5 of the YAGNI ladder can't be taken on autopilot. |
| `config-protection.sh` | PreToolUse (Write/Edit) | Blocks edits to linter, formatter, and typecheck config — the "make the check pass by weakening the check" move. Bypass with `config-ok`. |
| `careful-gate.sh` | PreToolUse (Bash) | Opt-in mode. Pauses genuinely irreversible commands (`rm -rf`, force-push, `reset --hard`, `DROP`, `dd`) for a confirmation. Inert until you create the flag. |
| `freeze-gate.sh` | PreToolUse | Opt-in mode. Hard read-only: every Write/Edit blocked, mutating Bash blocked, read-only Bash allowed. For investigating without touching. |
| `breadcrumb.sh` | PostToolUse | Appends one line per tool call to a session log. Stop hooks only fire on a graceful exit; a crash loses everything. This survives it. |

The two modes stay invisible until you turn them on:

```sh
touch ~/.claude/state/careful.flag     # pause irreversible ops
touch ~/.claude/state/freeze.flag      # hard read-only
rm    ~/.claude/state/freeze.flag      # off again
```

Every gate has an escape hatch, by design — an unsilenceable warning is a warning people learn to route around. `careful-gate` and `freeze-gate` take a literal `# careful: ignore` / `# freeze: ignore` in the command; `dep-gate` and `config-protection` take a `dep-ok` / `config-ok` in your next message.

Two honest limits. `claim-vgate` counts quoted output in your own message as evidence, so a claim that recites its own proof text can satisfy it — it raises the cost of an unbacked claim, it does not make one impossible. And `dep-gate`'s block message lists every dependency it can see in the manifest, not only the added one; the block is correct, the list is noisy.

## Make them yours

The kit is a starting rig, not a finished one. Three expected moves:

1. **Rewrite the voice.** `writing-style`'s Voice section is one author's stance in four lines. Replace it or the skill will make you sound like someone else.
2. **Edit the rituals to your day.** `morning`/`nightly`/`triage-inbox` assume a plain daily-notes folder; point them at your actual structure, cut sections you won't use. A ritual you resent is a ritual you'll drop.
3. **Delete what you don't run.** A skills directory full of unused skills is the tool-hoarding this kit's own `steal-ladder` warns about. Two skills used daily beat twenty-seven installed.

You'll notice two formatting styles across the skills (plain markdown vs XML-tagged sections) — both work; skills are just markdown, pick either for your own.

Skills are just markdown — open them, argue with them, commit your fork.

## Attributions

Several mechanisms here were adapted from public work; see [ATTRIBUTIONS.md](ATTRIBUTIONS.md) for the full ledger, including tools worth installing from their own upstreams (auteur, taste-skill, wayfinder, book-to-skill) rather than vendored here.

## What's deliberately not here

Honesty about the gaps, since the kit preaches it:

- **The books themselves.** Nine skills here — the seven lenses plus `negotiation` and `learning` — grew out of chapter-by-chapter distillations of copyrighted books. Those distillations are fine as private notes and improper to republish, so they are not in this repo. What ships is each skill's own working synthesis, and at the bottom of every one, the list of books it came from. Buy them. If you want the depth layer, `book-distill` builds it for you from a copy you own.
- **Employer material.** Brand skills, colleague-specific tooling, anything with a coworker's name or a company account in it stays out. Not sanitizable — structurally about specific people.
- **Rig-dependent automation.** The private versions of these skills lean on a local model router, a personal knowledge index, scheduled launchd jobs, and cross-machine probes. None of that ships because none of it would run on your machine. Where automation genuinely helps, the skill says "optional: automate this with your OS scheduler" and works fine without it.
- **Third-party skills.** Tools adopted from public repos (auteur, taste-skill, wayfinder) are linked in ATTRIBUTIONS.md, not republished — install them from the source and credit flows where it should.

What remains is the part that transfers: the disciplines. Those were always the point.

## License

MIT — see [LICENSE](LICENSE).
