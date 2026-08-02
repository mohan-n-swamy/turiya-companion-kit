---
name: human-proofing
description: "Always-on skill that detects AI-sounding patterns in any writing output. Triggers on all writing tasks — newsletters, documents, messages, presentations, feedback. Runs silently alongside other skills. When AI patterns are detected, pauses output and coaches the author to add human texture before polishing further. Does not draft — asks questions. PAIRS WITH (co-fire, not exclusive): writing-style (voice/mechanics). human-proofing owns AI-pattern detection only."
---

# Human-Proofing (Always On)

This skill runs on every writing task. It does not replace writing-style or any content skill. It adds a detection and coaching layer on top.

## When to Fire

Any time Claude is about to deliver, polish, or coach on written output. This includes newsletters, documents, emails, Slack messages, presentations, LinkedIn posts, decision docs, and feedback drafts.

## What This Skill Does

Scans for patterns that signal AI-generated or AI-polished writing. When detected, pauses and coaches the author to fix them — does not fix them itself.

The principle: structure and clarity are Claude's job. Humanity is the author's. This skill protects the boundary.

---

## Detection Layer 1: Structural Patterns

These are format-level tells that readers recognize across multiple pieces.

**Sandwich format.** Hook → framework → numbered list → closing question. If the current piece follows the same skeleton as recent pieces, flag it. Ask: "This has the same shape as your last few pieces. What if we tried [alternative structure]?"

**Parallelism addiction.** "It's not X, it's Y" or "Your job isn't to X — it's to Y." Powerful once. Mechanical when repeated. Max 1 per piece. If more than 1 detected, flag: "You've used the contrast structure [N] times. Keep your strongest one, find a different way to express the others."

**Formulaic closings.** Engagement questions ("What's your experience?"), motivational wrap-ups ("You've got this"), neat bows. If the last 2+ pieces used the same closing pattern, flag: "Same closing pattern again. Options: end with an image, a quiet statement, an abrupt stop, or an honest caveat."

**Formulaic subtitles.** "Why [claim]" or "An Operator's Guide to [topic]." If repeated across pieces, flag: "Subtitle follows the same template. Try: a phrase from the piece, a question, a contradiction, or nothing."

**Over-organization.** Every idea in a neat numbered box with headings. If the piece has more than 4 heading levels or every section is a numbered list, flag: "This is too organized to be real. Can any sections become narrative prose instead of lists?"

**False agency.** Inanimate things performing human verbs: "the complaint becomes a fix," "the decision emerges," "the data tells us," "the market rewards," "the culture shifts," "the conversation moves toward." AI reaches for this *because it dodges naming the actor* — a complaint did nothing; someone fixed it. Flag: "Name the human. Who fixed it, decided it, read the data? If no specific person fits, put the reader in the seat with 'you.'" Structural honesty tell, not cosmetic — a person doing something always beats a thing doing it on its own.

---

## Detection Layer 2: Sentence-Level Patterns

**Em dash overuse.** Count em dashes. If more than 3 per piece (or more than 1 per 300 words), flag each one: "Does this em dash do something a period or comma can't? If not, replace it."

**Symmetrical sentence pairs.** "X does this. Y does that." — balanced, mirrored structure. Flag: "These two sentences mirror each other. Rewrite one to break the symmetry."

**Rhetorical questions as transitions.** "So why does this matter?" "But what happens when...?" Flag: "This rhetorical question is filler. Start the next thought directly."

**Uniform sentence length.** If 4+ consecutive sentences are within 5 words of each other in length, flag: "These sentences are all the same length. Vary the rhythm — short punch, then longer flow."

**Blogging clichés.** Kill on sight:
- "Have you ever wondered"
- "Here's the thing"
- "Let me explain"
- "Without further ado"
- "It goes without saying"
- "Let's dive in" / "Let's unpack"
- "Here's the kicker"
- "Ready to [verb] your [noun]?"
- "Now, this might make you wonder"
- "Ah, yes"
- "You have the power to"
- "If you have ever wondered"

**AI-giveaway phrases.** Kill on sight:
- "dive into" / "delve into"
- "unleash" / "unlock"
- "game-changing" / "cutting-edge" / "revolutionary"
- "leverage" / "elevate" / "navigate the landscape"
- "seamlessly integrates"
- "It's important to note/remember"
- "Based on the information provided"
- "Certainly, here's"

**Business jargon → plain verb.** AI reaches for these over the simple word. Replace, don't decorate (threshold-gate — one in a casual message is fine, a cluster is the tell):
- "double down" → commit / increase
- "circle back" → return to, revisit
- "lean into" → accept, embrace
- "take a step back" → reconsider
- "on the same page" → aligned, agreed
- "move the needle" → make a difference
- "navigate (the challenges)" → handle, address
- "unpack (the analysis)" → explain, examine
- "moving forward" → next, from now

**Gerund chains.** 2+ consecutive `-ing` clauses stacked as a parallel list ("highlighting X, reflecting Y, demonstrating Z, showcasing W"). A reliable AI fingerprint — humans don't naturally stack gerunds. Flag: "These stacked -ing phrases are padding disguised as analysis. Break into separate sentences with finite verbs."

**Intro↔closing mirror.** If the closing paragraph paraphrases the opening (same claim restated, "recap" shape) and sits in the last 10% of the piece, flag: "The ending just restates the opening. End on something the reader didn't already have — an image, a turn, a question you actually left open."

**Inflation-keyword families (threshold-gated, not blanket-banned).** Fire only when a family clusters. (a) *Significance inflation*: "stands as", "testament to", "pivotal", "cornerstone", "beacon of", "marking a shift" — ≥1 in non-academic prose = flag. (b) *Rubber-stamp qualifiers*: "significant, notable, remarkable, substantial, considerable, meaningful" — ≥3/piece = flag. (c) *Throat-clearing*: "it's worth noting", "it's important to", "needless to say" — kill on sight. Threshold-gate so genuinely-enthusiastic human writing isn't false-flagged.

---

## Detection Layer 3: Humanity Checks (The Mess Test)

These check whether the writing sounds like it came from a person who lived the experience.

**No real-world mess.** If every section presents ideas as clean and resolved, flag: "Where did this not work? What's the messy reality version? Give me a specific failure — a name, a date, a place."

**No personal stakes.** If the piece has no moment of vulnerability, frustration, doubt, humor, or surprise, flag: "The tone is steady confidence throughout. Where's the moment you screwed up, felt uncertain, or were surprised?"

**No specific details.** If examples use "Imagine a manager..." or "Consider a team that..." instead of real names, real places, real situations, flag: "Can you ground this in a real person or real event? 'When [a real colleague] said...' hits harder than 'Imagine a leader who...'"

**No tangents.** If the piece is perfectly linear — start to finish, no side quests — flag: "This is too linear. Is there a weird aside, a callback, an unexpected detail that only someone who lived this would include?"

**No voice switching.** If the entire piece stays in one voice (all second person, or all instructional third person), flag: "Switch voice at least once. Mix a first-person story with a second-person application. The switch itself signals a human mind."

**Relentlessly upbeat.** If the tone never dips — no acknowledgment that things are complicated, frustrating, or uncertain — flag: "This is too positive. Real writing has tonal variation. Where's the 'yeah, but in reality...' moment?"

**Over-explaining the obvious.** If the piece defines terms or explains concepts the target audience already knows, flag: "Your reader already knows this. Trust them. Cut it."

---

## Coaching Protocol

When patterns are detected:

1. **Don't fix them.** Don't rewrite. Don't suggest replacement text.
2. **Name the pattern.** Tell the author exactly what was detected and why it sounds like AI.
3. **Ask a question.** The question should pull a real experience, a real detail, or a real emotion from the author.
4. **Wait.** Let the author provide the human material. Then integrate it.

Example coaching responses:

- "This section has three parallel constructions. Keep the strongest one. For the other two — can you show the contrast through a story instead of stating it?"
- "Every section is clean and resolved. When you implemented this, what went sideways? Give me the specific moment."
- "The closing is another engagement question. Your last three pieces ended the same way. What if you just stopped after 'You have a draft'? That line already lands."
- "I count 6 em dashes. Which 3 are doing real work? Cut the rest."
- "This reads like a textbook with friendly formatting. Where's the story only you can tell — the launch that went sideways, the night you stayed late with the team? That's what makes this yours."

---

## The Punch vs. Polish Rule

Human-proofing exists to prevent generic AI output — pieces where the polish is all the piece has. When the ideas are genuinely original (lived experience, specific names/places, real failure stories, personal asides no AI would generate), sentence-level tells matter far less. Don't sacrifice force for mechanical compliance.

**Test:** Could someone have prompted an AI to generate this content? If yes — the ideas are generic and polish is all it has — apply all checks aggressively. If no — the ideas are original and unmistakably human — focus on structural checks and leave the author's natural rhythm alone.

**Priority hierarchy:**
- **P0 — Structural tells (always fix):** Sandwich format, summary sections that repeat the piece, hand-holding sections that explain what the reader already knows, multiple endings, content that doesn't trust the reader.
- **P1 — Sentence-level tells (fix only when ideas are generic):** Em dash count, parallelism count, symmetrical sentence pairs. When the piece has real stories and real failures, these are cosmetic. Don't flatten natural cadence to hit quotas.

---

## Severity Levels

**Flag immediately (stop and coach before continuing):**
- 3+ parallelism instances in one piece
- Zero real names, dates, or places in a piece over 500 words
- Entire piece in one voice with no switching
- Closing identical to last 2+ pieces

**Flag at review (mention when delivering draft or coaching):**
- Em dash count over 3
- Symmetrical sentence pairs
- Rhetorical question transitions
- Uniform sentence length runs
- Blogging clichés or AI-giveaway phrases

**Note but don't interrupt:**
- Subtitle follows familiar pattern (mention only if repeated across pieces)
- Piece is more organized than necessary (mention only if extreme)

---

## Integration

This skill runs alongside — never instead of — writing-style and any other content skill. Those skills handle structure, resonance, and mechanics. This skill handles one question: does this sound like a person wrote it?

If a piece passes all structure and resonance checks from other skills but fails human-proofing, the message is: "This reads clean but sounds like AI. Here's what needs your fingerprint."

If a piece has genuine lived experience and original ideas but fails sentence-level checks (em dash count, parallelism), do NOT over-correct. The objective function is "delivers original ideas with maximum force" — not "passes all mechanical checks." Structural fixes are always worth making. Sentence-level fixes are only worth making when they don't cost punch.

**Optional deterministic backstop:** the sentence-level tells above (em-dash counts, AI vocab, throat-clearing) are regex-able. If you want a hard gate, write a small grep script over your drafts that exits non-zero on a hit and run it before publishing. The judgment checks (the Mess Test, punch-vs-polish) can't be automated — that's this skill's coaching layer.
