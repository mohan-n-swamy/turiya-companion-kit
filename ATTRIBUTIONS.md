# Attributions

The kit's own `steal-ladder` skill ends with: *attribute, or don't ship.* This is that ledger — both for mechanisms adapted into these skills and for tools you should install from their own upstreams instead of expecting them here.

## Adapted concepts (credit lines inside the kit)

- **stress-test Q6 (pass@k reliability gate)** — concept from **affaan-m/ECC** (`eval-harness` skill: eval-driven development, pass@k / pass^k). Concept credit, not code; this kit's version is conditional (non-deterministic objectives only) and folded into the stress-test loop. License: not verified — verify before relying on the upstream itself.
- **stress-test Q7 (unattended-loop budget + entropy)** — concept from Elvis Sun's loss-function-development essay (wall-clock cap queryable mid-run; forced entropy per cycle).
- **capture-lesson GP-NN format** — append-only numbered-lesson convention adapted from the raw-to-knowledge-playbook project's CONTRIBUTING.md. Credit retained; no public URL found as of 2026-08-02.
- **triage-inbox** — built on Andy Matuschak's [writing-inbox notes](https://notes.andymatuschak.org/A_writing_inbox_for_transient_and_incomplete_notes) ("inboxes only work if you trust how they're drained").
- **config-protection hook** — adapted from the `config-protection` hook in **affaan-m/ECC**. Re-implemented here as a clean named shell hook (ECC ships it as an inlined node blob; this does not). License: not verified — verify before relying on the upstream itself.
- **book-distill conventions** — the fold-by-domain rule, the cost gate, parallel synthesis with centralized writes, and the verification gate are this kit's; the extraction step and the book→skill idea come from [book-to-skill](https://github.com/virgiliojr94/book-to-skill) (MIT).
- **writing-style / human-proofing frameworks** — summarize published craft books: *The Pyramid Principle* (Barbara Minto), *Made to Stick* (Chip & Dan Heath), Hemingway's iceberg theory, *Nobody Wants to Read Your Sh\*t* (Steven Pressfield). The kit ships working rules, not the books' text — read the originals.

## Books the lens skills are built on

Nine skills here are a working synthesis of a field's literature. The books are **not** reproduced in this repo — each skill ends with its own reading list, repeated here as one ledger. Buy them; they are the source, and they are not this kit's to give away.

- **negotiation** — *Never Split the Difference* (Chris Voss with Tahl Raz) · *How to Win Friends and Influence People* (Dale Carnegie) · *The 48 Laws of Power* (Robert Greene) · *Influence: Science and Practice* (Robert Cialdini) · *Just Listen* (Mark Goulston) · *Exactly What to Say* (Phil M. Jones)
- **learning** — *Ultralearning* (Scott H. Young) · *How to Solve It* (George Pólya)
- **engineering** — *A Philosophy of Software Design* (John Ousterhout) · *Designing Data-Intensive Applications* (Martin Kleppmann) · *Accelerate* (Nicole Forsgren, Jez Humble, Gene Kim) · *The Pragmatic Programmer* (Andrew Hunt, David Thomas)
- **product** — *Inspired* (Marty Cagan) · *Continuous Discovery Habits* (Teresa Torres) · *The Mom Test* (Rob Fitzpatrick) · *Escaping the Build Trap* (Melissa Perri)
- **strategy** — *Playing to Win* (A.G. Lafley, Roger L. Martin) · *Working Backwards* (Colin Bryar, Bill Carr) · *The Long Game* (Dorie Clark)
- **operations** — *The Toyota Way* (Jeffrey Liker) · *Out of the Crisis* (W. Edwards Deming) · *The Checklist Manifesto* (Atul Gawande)
- **data-fluency** — *Thinking with Data* (Max Shron) · *The Art of Statistics* (David Spiegelhalter) · *Lean Analytics* (Alistair Croll, Benjamin Yoskovitz) · *Storytelling with Data* (Cole Nussbaumer Knaflic) · *Statistics Done Wrong* (Alex Reinhart) · *Information Dashboard Design* (Stephen Few)
- **customer-experience** — *The Effortless Experience* (Matthew Dixon, Nick Toman, Rick DeLisi) · *How to Wow* (Adrian Swinscoe) · *The Best Service Is No Service* (Bill Price, David Jaffe) · *This Is Service Design Doing* (Marc Stickdorn, Markus Hormess, Adam Lawrence, Jakob Schneider)
- **systems-thinking** — *Thinking in Systems* (Donella Meadows) · *The Art of Thinking in Systems* (Steven Schuster)

## Install from upstream (linked, deliberately not vendored)

These are third-party or third-party-derived skills the book discusses. They ship from their authors, not from this kit — install there, credit flows where it should:

- **auteur** — [pejmanjohn/auteur](https://github.com/pejmanjohn/auteur) (npm package; bundles its own Claude skill). The book's "auteur as a skill" chapter teaches the install command. License: check the repo before relying.
- **taste-skill (frontend-taste upstream)** — [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill), MIT. The author's private adaptation stays private; the upstream is the thing to install.
- **wayfinder** — [mattpocock/skills](https://github.com/mattpocock/skills). License: not verified — verify before relying.
- **book-to-skill** — [virgiliojr94/book-to-skill](https://github.com/virgiliojr94/book-to-skill), MIT. The extraction engine behind book distillation. The kit's `book-distill` skill is a convention layer that calls its `extract.py`; the engine itself is not vendored — install it from the repo and run it on books you own.

## Unverified-license rule

Where a license is marked "not verified": the link and credit are provided, but do not republish or redistribute that upstream's content until you've checked its license yourself.
