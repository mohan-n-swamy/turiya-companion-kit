# turiya-companion-kit

Working Claude Code skills from the book — the actual files, not screenshots of them.

## What this is

The companion kit to the book's chapters 8 and 10. Chapter 8 shows two of these skills being built; chapter 10 tells you to stop reading and install them. This repo is the install: thirteen skills, sanitized from the author's daily rig, that turn Claude Code from a code generator into a working partner with opinions, rituals, and memory.

These are not demos. Every skill here ran (and runs) in the author's setup daily. What you get is the generic version — the machinery without the author's vault paths, employer references, and home-grown automation glued to it.

## Prereqs

- [Claude Code](https://claude.com/claude-code) installed and working (`claude` on your PATH)
- A terminal. That's it — no plugins, no MCP servers, no note-taking app required. The daily-ritual skills assume only "a folder of markdown notes, one per day."

## Install

```sh
git clone https://github.com/mohan-n-swamy/turiya-companion-kit.git
cd turiya-companion-kit
./install.sh
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
5. Ignore the other ten skills until these three are habits.

## The Core Kit, skill by skill

One honest line each:

- **brutal-honesty** — the coworker pact: verified evidence over plausible guesses, bad news first, no "should work." The skill the newsletter readers asked for most.
- **antifragile-advisor** — always-on analysis partner that surfaces what's usually thin in a plan of this shape, then hands you the judgment instead of faking an oracle.
- **council** — five advisors trained to disagree (Contrarian, First Principles, Expansionist, Outsider, Executor), peer-review, then a chairman synthesis with a dissent log. For decisions, not lookups.
- **stress-test** — the post-design gate: five questions ending with "the best reason this doesn't deliver," looped until it holds. Includes the pass@k reliability gate for LLM-shaped designs.
- **deep-research** — fan-out searches, fetch real sources, adversarially try to kill every claim, ship only what survived — cited.
- **writing-style** — voice, mechanics, and structure canon (Minto, Hemingway, Made to Stick). Shipped as a template: the mechanics transfer, the voice section you must rewrite as your own.
- **human-proofing** — detects the AI tells in writing (em-dash rash, parallelism addiction, the missing mess) and coaches you to add human texture instead of fixing it for you.
- **capture-lesson** — after every bug or incident, one append-only numbered lesson in the repo. The cheapest compound interest in this kit.
- **session-ladder** — park / resume / wrap-up as a pattern: stamp where you are, pick up the freshest stamp, rebase the docs when done. Plain files, no tooling.
- **morning** — reads yesterday's and today's daily notes, proposes a Top 3 with reasoning, surfaces the decisions the day actually needs.
- **nightly** — the evening transform: what happened on top, the morning plan demoted to reference, every pushed task gets a "why," tomorrow gets seeded tonight.
- **triage-inbox** — drains your capture inbox ten files at a time, one human decision per file. Matuschak: inboxes only work if you trust how they're drained.
- **steal-ladder** — adopt other people's mechanisms without becoming a tool hoarder: see → record → evaluate → lift the piece → adapt → attribute.

## Make them yours

The kit is a starting rig, not a finished one. Three expected moves:

1. **Rewrite the voice.** `writing-style`'s Voice section is one author's stance in four lines. Replace it or the skill will make you sound like someone else.
2. **Edit the rituals to your day.** `morning`/`nightly`/`triage-inbox` assume a plain daily-notes folder; point them at your actual structure, cut sections you won't use. A ritual you resent is a ritual you'll drop.
3. **Delete what you don't run.** A skills directory full of unused skills is the tool-hoarding this kit's own `steal-ladder` warns about. Two skills used daily beat thirteen installed.

You'll notice two formatting styles across the skills (plain markdown vs XML-tagged sections) — both work; skills are just markdown, pick either for your own.

Skills are just markdown — open them, argue with them, commit your fork.

## Attributions

Several mechanisms here were adapted from public work; see [ATTRIBUTIONS.md](ATTRIBUTIONS.md) for the full ledger, including tools worth installing from their own upstreams (auteur, taste-skill, wayfinder, book-to-skill) rather than vendored here.

## What's deliberately not here

Honesty about the gaps, since the kit preaches it:

- **The book-distillation skills.** The author's rig has skills distilled chapter-by-chapter from copyrighted books (engineering, strategy, leadership lenses, and the full Pyramid Principle / Pressfield reference layers inside writing-style). Fine as private notes; improper to republish. You get the working rules and the reading list — buy the books, run `book-to-skill` yourself.
- **Employer material.** Brand skills, colleague-specific tooling, anything with a coworker's name or a company account in it stays out. Not sanitizable — structurally about specific people.
- **Rig-dependent automation.** The private versions of these skills lean on a local model router, a personal knowledge index, scheduled launchd jobs, and cross-machine probes. None of that ships because none of it would run on your machine. Where automation genuinely helps, the skill says "optional: automate this with your OS scheduler" and works fine without it.
- **Third-party skills.** Tools adopted from public repos (auteur, taste-skill, wayfinder) are linked in ATTRIBUTIONS.md, not republished — install them from the source and credit flows where it should.

What remains is the part that transfers: the disciplines. Those were always the point.

## License

MIT — see [LICENSE](LICENSE).
