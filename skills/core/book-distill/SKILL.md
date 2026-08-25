---
name: book-distill
description: |
  Turn a book, PDF, or long document you own into a grounded, on-demand skill: extract the text, synthesize it chapter by chapter into structured reference files, build a glossary/patterns/cheatsheet, and wire an index into a SKILL.md. Folds by domain — one skill per subject, not one per book. Triggers: "/book-distill", "turn this book into a skill", "distill this PDF", "make a skill from this document".
---

# book-distill — book → grounded skill

Turn a document you own into a skill the agent can load on demand. The output is a
*reference layer*: structured, named-framework-preserving files the agent reads when it needs
depth, sitting behind a short front-door SKILL.md it reads every time.

Arguments: one or more paths (PDF/EPUB/DOCX/TXT/MD/HTML/RTF/MOBI), and optionally a target
skill slug — an existing skill to fold into, or a new one.

**Ownership.** Distil books you own, for your own use. The output is a derivative of a
copyrighted work; keep it local. Do not publish it, and do not ship it inside a repo you
distribute — this kit deliberately ships working rules and points at the originals instead.

## Three rules that make the output worth having

- **Fold by domain, not one skill per book.** One `distributed-systems` skill absorbs DDIA plus
  three papers. Fifty thin one-book skills is a worse index than none. Before creating a new
  skill, look for an existing one to fold into.
- **Source → claim.** Every chapter file is synthesized from the extracted text, never from the
  model's recall of the book. Recall produces confident, subtly wrong summaries.
- **Structure, not summary.** Preserve the author's exact framework names and their
  when-to-use. A summary tells you what the book said; a reference layer lets you act.

## Step 1 — Extract

Classify first: **technical** (code, tables, formulas — needs a layout-aware parser) or
**text-heavy** (prose — a plain text dump is fine and instant).

Extraction is the one part worth borrowing rather than writing. The
[`book-to-skill`](https://github.com/virgiliojr94/book-to-skill) project (MIT) ships an
`extract.py` that handles both modes and installs its own dependencies:

```bash
python3 <path-to>/book-to-skill/scripts/extract.py <paths...> --mode <technical|text> --install-missing yes
```

Output: a `full_text.txt` plus a `metadata.json` with pages, words, token estimate, and detected
chapters. Read the metadata, not the text.

## Step 2 — Cost gate

Before generating anything, state the budget out loud:

```
[COST: ~N source tokens · ~M output tokens · ~K agents]
```

Above ~50k source tokens, never read `full_text.txt` whole. Slice it with `grep`/`sed` so the
cost stays proportional to what you produce, not to what you parsed.

## Step 3 — Map chapter offsets

```bash
FT=<work-dir>/full_text.txt
sed -n '1,160p' "$FT"                                          # table of contents
grep -niE "^\s*(chapter|part|introduction|conclusion)" "$FT"   # structural markers
```

Locate each chapter title in the *body*, skipping the ToC region, to get real line ranges. A
range that starts in the ToC produces an empty chapter file — check the ranges before spending
tokens on them.

## Step 4 — Decide the target

- Slug given and the skill exists → **fold**: add `chapters/`, merge the glossary/patterns/
  cheatsheet, append to the index.
- No slug → propose an existing domain skill to fold into; only create a new
  `author-concept` slug when nothing fits. **Default to folding.**

## Step 5 — Chapter synthesis, in parallel

One agent per chapter, run concurrently. Each is given a line range and returns markdown — it
does not write files. The orchestrator writes. Keeping writes in one place means one set of
paths to get right, and subagents that cannot scribble outside the target directory.

Per chapter, the instruction is:

> Read lines `<start>`–`<end>` of `<full_text.txt>` via `sed -n '<start>,<end>p' <file>`.
> Synthesize a dense reference file for Chapter N, "`<Title>`", of "`<Book>`" by `<Author>`.
> Extract STRUCTURE, not summary. Preserve the author's EXACT framework names. 800–1200 tokens.
> Practitioner voice ("Use X when Y").
> Sections: `# Chapter N: Title` / `## Core Idea` / `## Frameworks Introduced` (name +
> when-to-use + how) / `## Key Concepts` / `## Mental Models` / `## Anti-patterns` /
> (`## Code Examples` and `## Reference Tables` only if technical) / `## Key Takeaways` /
> `## Connects To`.

Use the cheapest model that holds the whole range in context — this is bounded extraction, not
reasoning. If you have a second provider with its own quota, chapter synthesis is the ideal
thing to send there: it is the expensive half and the least judgment-dependent.

## Step 6 — Supporting files

From the chapter files (not the source text again):

- `glossary.md` — every term, alphabetical, `**Term** — definition (Ch N)`. ≤1500 tokens.
- `patterns.md` — techniques with when / how / trade-off. ≤2000 tokens.
- `cheatsheet.md` — decision tables and quick rules. ≤1000 tokens.

## Step 7 — Wire the index

Add a **Reference Layer** section to the target `SKILL.md`: a chapter index table linking into
`chapters/`, a topic index mapping term → chapter, and links to the three supporting files.

If you folded into an existing applied-lens skill, the lens stays the front door — the book
layer is on-demand depth underneath it. Keep the SKILL.md body under ~4000 tokens and front-load
it; context compaction truncates from the end.

## Step 8 — Verify

A gate, not a glance:

```bash
ls chapters/*.md | wc -l     # equals the chapter count
find chapters -size -1k      # no empty files
```

Then confirm every link in SKILL.md resolves. Report: files written, framework count, and the
fold-or-new decision with its reason.

## What this is not

- **Not one skill per book.** Fold by domain.
- **Not a summary generator.** Extract structure and named frameworks.
- **Not RAG.** This is compile-time reasoning structure, not query-time chunk retrieval. For
  search across fifty books, use a retrieval tool; for depth on one, use this.

## Credit

The extraction step and the book→skill idea come from
[`book-to-skill`](https://github.com/virgiliojr94/book-to-skill) (MIT). This skill is a
convention layer on top: fold-by-domain, the cost gate, parallel synthesis with centralized
writes, and the verification gate.
