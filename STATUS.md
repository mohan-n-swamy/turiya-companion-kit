# turiya-companion-kit — STATUS

**Updated:** 2026-09-24
**Release:** v0.3.x — 32 skills, 9 hooks, the manufacture workflow. Homebrew: `mohan-n-swamy/tap/turiya-skills`.

## Current goal

Ship the build-pipeline harness (manuf-product-design → manuf-design-qa → manufacture assemble → manuf-qa, plus delegate and the design/pack gates) as a public, install-and-run kit.

## Latest verified evidence

```sh
bash tests/selftest.sh                         # every hook denies, passes and bypasses; install; leak/refs/counts sweeps
(cd workflows && node ./manufacture.test.mjs)  # runs the real workflow script with stubbed agents
brew test mohan-n-swamy/tap/turiya-skills      # the published formula
```

## Known limits

- QA stamps are written by the QA pass itself: an audit record, not a proof (README, "What the gates can and cannot do").
- The pack validator's Bash-hook mode only sees shell-started assembles; the workflow runs the same check as its first step.

## Blocker

_none_

## Next action

- [ ] Fold in findings from the cross-provider release review, if any.
