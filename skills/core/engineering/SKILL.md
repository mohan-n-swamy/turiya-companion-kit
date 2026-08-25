---
name: engineering
description: |
  Software engineering excellence — manage complexity, design data systems, ship fast & stable, pragmatic craft (Philosophy of SW Design, DDIA, Accelerate/DORA, Pragmatic Programmer). SKIP: product discovery (product); non-software ops (operations). Triggers: "/engineering", "software design", "complexity", "deep modules", "DDIA", "replication", "DORA metrics", "DRY", "technical debt", "architecture".

---

# Engineering — complexity · data systems · delivery · craft

Manage complexity, design for scale, ship fast-and-stable. Answer from the spine.

## Fast-reference frameworks (the spine)
- **Philosophy of Software Design (Ousterhout)**: complexity = the enemy (**dependencies + obscurity**). **Deep modules** (simple interface, powerful implementation) > shallow; **information hiding**; **pull complexity downward** (into the module, away from users); **define errors out of existence**; **design it twice**; comments capture the *why*; strategic > tactical programming.
- **DDIA (Kleppmann)**: build for **reliability · scalability · maintainability**. Data models & storage (LSM vs B-trees); **replication** (leader/multi-leader/leaderless); **partitioning/sharding**; **transactions & isolation levels**; the **trouble with distributed systems** (faults, clocks); **consistency & consensus** (linearizability, quorums); batch vs **stream processing**.
- **Accelerate (DORA)**: speed AND stability are not a tradeoff. The **4 key metrics**: deployment frequency · lead time for changes · MTTR · change-fail rate. Driven by CI/CD, trunk-based dev, loosely-coupled architecture, and a **Westrum generative culture**.
- **Pragmatic Programmer**: **DRY**; orthogonality; **tracer bullets**; fix **broken windows**; good-enough software; design by contract; decoupling; care about your craft; provide options, not excuses.

## Read the originals

The rules above are this skill's own working synthesis. The books they come from are not reproduced here and are not the author's to give away — buy them.

- *A Philosophy of Software Design* — John Ousterhout
- *Designing Data-Intensive Applications* — Martin Kleppmann
- *Accelerate* — Nicole Forsgren, Jez Humble, Gene Kim
- *The Pragmatic Programmer* — Andrew Hunt, David Thomas
