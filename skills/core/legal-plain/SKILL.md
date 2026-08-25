---
name: legal-plain
description: |
  Plain-English read of a legal or contractual document — what you're agreeing to, what they're committing to, the three riskiest clauses, what's non-standard, what's missing, and the questions to ask before signing. Comprehension only, not legal advice. Triggers: "/legal-plain", "explain this contract", "read this NDA", "what am I signing", "is this clause normal", "what's missing from this agreement".
---

# legal-plain — read it before you sign it

Turn a contract into something the signer actually understands. The output is comprehension,
never advice: it tells them what the document says and what to ask a lawyer, not what to do.

**Open and close every response with the disclaimer.** Not decoration — it is the boundary that
makes the rest safe to give.

## Input

Paste, file path, or URL. For a URL, extract the text first (`defuddle` handles this) rather
than reading through a page's navigation and cookie banners.

If the document type isn't obvious from the first page, **ask** — contract · lease · NDA ·
employment · MSA/vendor · terms of service · privacy policy. The "non-standard" and "what's
missing" checks are both measured against a baseline, and the wrong baseline makes both useless.

## Output — these six sections, in this order

**1. What you're agreeing to.** Your obligations, in plain sentences. Money, deadlines,
exclusivity, things you promise not to do, things you're on the hook for if they go wrong.

**2. What they're committing to.** The same, from the other side. If this section is much
shorter than the first, say so — that asymmetry is the finding.

**3. The three riskiest clauses.** For each: the verbatim quote, then the risk in one plain
sentence. Rank by what it would actually cost the signer, not by how alarming the language
sounds. Boilerplate indemnity is usually less dangerous than a quiet auto-renewal.

**4. Non-standard or surprising.** What departs from the baseline for this document type, in
either direction. Note the ones that favour the signer too — they're negotiating leverage and
they're often the first thing the other side tries to remove.

**5. What's missing.** The clauses this document type normally has and this one doesn't.
Absence is harder to spot than presence and is where most of the real exposure lives:
termination rights, liability caps, IP assignment, data handling, dispute venue, survival.

**6. About five questions to ask before signing.** Specific and answerable, aimed at a
counterparty or a lawyer. "What happens to my data after termination?" — not "is this fair?"

## Rules

- **Quote before you characterise.** Every risk claim carries the clause text it came from.
- **Plain words.** If a term of art is unavoidable, define it on first use in six words.
- **Don't hedge everything into mush.** "This clause lets them terminate without cause on 7
  days' notice" is a fact about the text. Say it plainly. Reserve uncertainty for real
  ambiguity, and name what makes it ambiguous.
- **Flag what you couldn't read.** Exhibits, schedules, and incorporated-by-reference documents
  are part of the agreement. If they weren't provided, say which ones and that the read is
  incomplete without them.
- **Never predict an outcome.** No "this would probably hold up." That's the line between
  comprehension and advice.

## The disclaimer

> This is a plain-English reading to help you understand the document. It is not legal advice,
> and I am not your lawyer. For anything with real money or real risk attached, take this
> reading — and your questions — to one.
