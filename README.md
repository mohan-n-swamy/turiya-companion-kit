# turiya-companion-kit

Working Claude Code skills and hooks from the book — the actual files, not screenshots of them.

## The book

**Same Starting Line: How a Non-Technical Operator Put AI to Work, and How You Can.** — Mohan Narayanaswamy Natarajan. Kindle, ASIN `B0HGF7P5FG`.

[India](https://amzn.in/d/09HbKqNi) · [everywhere else](https://www.amazon.com/dp/B0HGF7P5FG) — free on Kindle Unlimited.

You do not need the book to use this repo; the skills stand on their own. The book is where the reasoning behind them lives — why each one exists, what it replaced, and what it cost to get wrong first.

## What this is

The companion kit to the book. Chapter 8 shows two of these skills being built, chapter 25 tells you to stop reading and install them, and Appendix B is the install itself. This repo is the install: **32 skills, 9 hooks and a build workflow**, sanitized from the author's daily rig, that turn Claude Code from a code generator into a working partner with opinions, rituals, memory — and a build pipeline with gates it cannot talk its way past.

These are not demos. Every skill here ran (and runs) in the author's setup daily. What you get is the generic version — the machinery without the author's vault paths, employer references, and home-grown automation glued to it.

The skills are advice the model chooses to follow. The hooks are not: they are shell scripts the harness runs, and they block. That difference is the whole reason the hooks are in this repo.

## Prereqs

- [Claude Code](https://claude.com/claude-code) installed and working (`claude` on your PATH)
- A terminal. No plugins, no MCP servers, no note-taking app required. The daily-ritual skills assume only "a folder of markdown notes, one per day."
- For the hooks: `python3` (most hooks are a few lines of shell around Python). For the build pipeline also `jq` (the pack validator refuses to pass a pack it cannot parse) and `node` if you want to run the workflow tests. The Homebrew formula installs `jq` for you; from source, `brew install jq` (or your package manager) if missing.

## Install

**With Homebrew (macOS / Linux) — recommended:**

```sh
brew install mohan-n-swamy/tap/turiya-skills
turiya-skills              # skills only
turiya-skills --hooks      # skills and hooks
turiya-skills --harness    # skills, hooks and workflows — the full build pipeline
```

The five build-pipeline skills (`manuf-*`, `manufacture`) call the pack validator and the stamp script in `~/.claude/hooks/`, so install them with `--harness` (or `--hooks`). A skills-only install leaves those two scripts missing. `--hooks-only` installs just the hooks.

The formula also installs [rigor](https://github.com/mohan-n-swamy/rigor), the protocol the hooks serve (run `rigor install` once to wire it). `brew upgrade turiya-skills` gets new releases.

**From source:**

```sh
git clone https://github.com/mohan-n-swamy/turiya-companion-kit.git
cd turiya-companion-kit
./install.sh              # skills only
./install.sh --hooks      # skills and hooks
./install.sh --harness    # skills, hooks and workflows
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
5. Ignore the other twenty-nine skills until these three are habits.

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

### Building software — the harness

Five skills that together take a feature from idea to merged code, with a gate at every hand-off. The next section shows how they chain.

- **manuf-product-design** — the planning half. Writes a PRD and PR-FAQ with you until you say LOCKED, then real screen designs you lock, then a "pack" in `specs/NNN-feature/`: architecture, interfaces and one spec per component so exact a small model can build it without deciding anything.
- **manufacture** — the build half. `assemble` builds a pack component by component, halting on the first red check; `single`/`loop` runs the same protocol on a change without a pack. Ends with adversarial reviewers trying to break it before anyone may call it shipped.
- **manuf-design-qa** — grades the *plan* before building: journeys with no screen, components that invent UI, verification holes. Assemble will not start below grade A.
- **manuf-qa** — grades the *build* after assembling: does it match the design, is the data real, did every component land. Merge needs A; production needs A+++ with a live check.
- **delegate** — sends worker-shaped jobs (read, extract, review, classify) to the cheapest capable model instead of the expensive one you are talking to. Works out of the box with Claude Code subagents; uses a model router if you have one.

### Rituals and continuity

- **session-ladder** — park / resume / wrap-up as a pattern: stamp where you are, pick up the freshest stamp, rebase the docs when done. Plain files, no tooling.
- **morning** — reads yesterday's and today's daily notes, proposes a Top 3 with reasoning, surfaces the decisions the day actually needs.
- **nightly** — the evening transform: what happened on top, the morning plan demoted to reference, every pushed task gets a "why," tomorrow gets seeded tonight.
- **triage-inbox** — drains your capture inbox ten files at a time, one human decision per file. Matuschak: inboxes only work if you trust how they're drained.

## The harness — how the build pipeline fits together

Asked to "build X", a model will plan, design and code in one breath, then tell you it works. Each of those steps fails quietly: the plan was never agreed, the screens were invented while coding, the tests passed against mocks, and "it works" was never checked. The harness splits the job at each of those seams and puts a gate there — a hook or a stamp that blocks, not a sentence the model may ignore.

```
 you + the strongest model                       cheaper models do the typing
 ─────────────────────────                       ────────────────────────────
 /manuf-product-design ──► specs/NNN-feature/ ──► /manuf-design-qa ──► /manufacture assemble ──► /manuf-qa ──► merge
   PRD, PR-FAQ (LOCK #1)    the "pack"             grades the plan      builds each component      grades the build
   designs     (LOCK #2)                           stamp ≥ A or stop    by tier, halts on red      stamp ≥ A or stop
                    │                                   │                   │   ▲                        │
                    ▼                                   ▼                   ▼   │                        ▼
        manuf-pack-validate.sh              manuf-qa-stamp.sh      design-source-gate.sh      claim-vgate.sh
        (pack is zero-decision?)            (writes/reads grades)  (no UI without design/)    (no "deployed" without proof)
```

| Component | Kind | What it is for | When it runs | Connects to |
|---|---|---|---|---|
| `manuf-product-design` | skill | Moves every decision to the front, where it is cheap: product brief, screen designs, and a zero-decision spec per component | Start of any non-trivial feature | writes the pack; calls `manuf-pack-validate.sh` and `/manuf-design-qa` |
| `manuf-design-qa` | skill | Finds holes in the plan before code exists | After the pack is written; again at assemble start | writes the `design-qa` stamp |
| `manufacture` | skill | Builds the pack (or a smaller change) and makes adversaries try to break it before it may ship | After design-qa ≥ A | runs `workflows/manufacture.js`; calls both QA skills |
| `manuf-qa` | skill | Checks the build matches the plan, with real data | After assemble; before merge; before production | writes the `manuf-qa` stamp |
| `delegate` | skill | Keeps volume work (reading, extracting, reviewing) off the expensive model | Whenever work is self-contained | used by `manufacture` for executors and reviewers; `workflows/lib/delegate-first.js` is the Workflow form |
| `manufacture.js` | workflow | The manufacture protocol as a script, so the gates run in a fixed order and a red result stops the run | Invoked by `/manufacture` or by asking for the workflow | has an agent check the stamps; dispatches components by tier |
| `delegate-first.js` | workflow lib | `smart()` / `read()` helpers that pick the cheapest tier for a Workflow stage (worker → Sonnet, reader → Haiku) | Pasted into your own Workflow scripts | `manufacture.js` carries its own tier-keyed variant (cheap / code / adversarial) of the same idea |
| `manuf-pack-validate.sh` | hook + CLI | Rejects a pack whose component specs leave the executor any decision | By the planner; as step 1 of the workflow; as a Bash hook when assemble is started from the shell | gate 0a of assemble |
| `manuf-qa-stamp.sh` | CLI | Turns a QA grade into a file a gate can read — chat grades open nothing | End of each QA skill; start/end of assemble | `pack/.qa/*.json` |
| `design-source-gate.sh` | hook | Blocks writing a large block of UI when no exported design exists | Every Write/Edit to a UI file | the `design/` folder the planner exports |

The Workflow scripts need Claude Code's Workflow tool. Without it, the skills still work: `/manufacture` walks the same steps by hand.

**What the gates can and cannot do.** Hooks are enforced by Claude Code itself: a blocked write does not happen. The workflow fixes the order of the steps and stops on a red result. The QA stamps are different: they are written by the QA pass, so they are a record you can audit (`specs/NNN/.qa/*.json`), not a proof — a model that skipped the QA and wrote the stamp anyway would get through. That is why the grade, the evidence and the date sit in the stamp file, and why a human reads the pack PR.

## The hooks

A skill is a rule the model may follow. A hook is a rule it cannot route around — the harness runs the script, reads the exit code, and blocks on 2. 9 hooks ship here.

Install with `turiya-skills --hooks` (or `./install.sh --hooks`). The installer copies the files and **prints** the `settings.json` wiring for you to paste. It does not edit your settings — a hook that installs itself into your config without asking is precisely the behaviour these hooks exist to stop.

| Hook | Event | What it does |
|---|---|---|
| `claim-vgate.sh` | Stop | Blocks the turn if you claimed something is deployed, verified, works, or exists in the data and the session transcript contains no evidence for it. Four claim categories, each with its own evidence pattern. |
| `dep-gate.sh` | PreToolUse (Write/Edit) | Blocks an edit that adds a line to a dependency manifest until you reply `dep-ok`. Rung 5 of the YAGNI ladder can't be taken on autopilot. |
| `config-protection.sh` | PreToolUse (Write/Edit) | Blocks edits to linter, formatter, and typecheck config — the "make the check pass by weakening the check" move. Bypass with `config-ok`. |
| `careful-gate.sh` | PreToolUse (Bash) | Opt-in mode. Pauses genuinely irreversible commands (`rm -rf`, force-push, `reset --hard`, `DROP`, `dd`) for a confirmation. Inert until you create the flag. |
| `freeze-gate.sh` | PreToolUse | Opt-in mode. Hard read-only: every Write/Edit blocked, mutating Bash blocked, read-only Bash allowed. For investigating without touching. |
| `breadcrumb.sh` | PostToolUse | Appends one line per tool call to a session log. Stop hooks only fire on a graceful exit; a crash loses everything. This survives it. |
| `design-source-gate.sh` | PreToolUse (Write/Edit/MultiEdit) | Blocks a large block of new UI code (markup, JSX, CSS) when no `design/` folder exists up-tree — design first, then implement it. Small edits and logic files pass. Bypass: `design-gate: ignore` in the content. |
| `manuf-pack-validate.sh` | PreToolUse (Bash) + CLI | Blocks a shell-started `manufacture assemble` on a pack that is not zero-decision (the workflow runs the same check as its first step): a component missing one of its 7 fields, an unlocked PRD, a design never exported. Run it by hand too: `manuf-pack-validate.sh specs/NNN-feature`. Bypass: say `manuf-pack-ok`. |
| `manuf-qa-stamp.sh` | CLI (not wired to an event) | Writes and checks the grade stamps the QA skills produce: `write design-qa <pack> A` · `check manuf-qa <pack> --min=A`. The manufacture workflow reads them. |

The two modes stay invisible until you turn them on:

```sh
touch ~/.claude/state/careful.flag     # pause irreversible ops
touch ~/.claude/state/freeze.flag      # hard read-only
rm    ~/.claude/state/freeze.flag      # off again
```

Every gate has an escape hatch, by design — an unsilenceable warning is a warning people learn to route around. `careful-gate` and `freeze-gate` take a literal `# careful: ignore` / `# freeze: ignore` in the command; `dep-gate` and `config-protection` take a `dep-ok` / `config-ok` in your next message.

Two honest limits. `claim-vgate` counts quoted output in your own message as evidence, so a claim that recites its own proof text can satisfy it — it raises the cost of an unbacked claim, it does not make one impossible. And `dep-gate`'s block message lists every dependency it can see in the manifest, not only the added one; the block is correct, the list is noisy.

## Rigor — the protocol behind the hooks

The kit's hooks are individual rules. The Rigor protocol is the method they serve: six answers written before the work, evidence before the word "done", and ponytail as the counterweight that keeps the answers small. It ships as its own package so it stays one source:

```bash
brew install mohan-n-swamy/tap/rigor && rigor install
```

or from source: https://github.com/mohan-n-swamy/rigor. `rigor install` wires a pre-work gate (blocks the third ungoverned file), a done-gate (refuses an unevidenced claim) and the `/rigor` skill; `rigor uninstall` removes exactly that. It coexists with this kit's hooks.

## Make them yours

The kit is a starting rig, not a finished one. Three expected moves:

1. **Rewrite the voice.** `writing-style`'s Voice section is one author's stance in four lines. Replace it or the skill will make you sound like someone else.
2. **Edit the rituals to your day.** `morning`/`nightly`/`triage-inbox` assume a plain daily-notes folder; point them at your actual structure, cut sections you won't use. A ritual you resent is a ritual you'll drop.
3. **Delete what you don't run.** A skills directory full of unused skills is the tool-hoarding this kit's own `steal-ladder` warns about. Two skills used daily beat thirty-two installed.

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

The code in this repo is MIT. The book it accompanies is not — *Same Starting Line* is sold, and the reading lists inside these skills point at other people's books that are also sold. Take the mechanisms freely; buy the writing.
