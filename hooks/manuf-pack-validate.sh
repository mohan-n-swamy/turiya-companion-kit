#!/usr/bin/env bash
# manuf-pack-validate.sh — structural gate for a manuf-product-design pack.
#
# WHAT IT IS FOR
#   /manuf-product-design writes a "pack" (specs/NNN-feature/): PRD, design,
#   and one spec per component. /manufacture assemble then hands those specs to
#   a cheaper model to type in. That only works if every component spec leaves
#   the executor ZERO decisions — "Haiku-proof". This hook checks the pack's
#   shape before any build starts, so a vague spec fails here, not in your code.
#
# A pack is only safe to hand a weak executor when every component has ZERO
# degrees of freedom. This validator enforces that MECHANICALLY (not honor-system):
# it rejects a pack whose components miss any of the 7 Haiku-proof fields, whose
# risks lack mitigation/detection, whose manifest.json DAG is malformed, or whose
# UI screens lack a vendored design.
#
# Usage (CLI):
#   manuf-pack-validate.sh <specs/NNN-feature dir>
#   Exit: 0 = VALID · 1 = INVALID · 2 = usage/structural error
#
# Usage (PreToolUse Bash hook):
#   stdin = Claude-shaped JSON; no pack arg.
#   Fires only when command looks like manufacture assemble; extracts pack path,
#   re-invokes CLI mode; maps INVALID (1) → exit 2 (block). Non-assemble → allow.
#   Fail-open on empty/malformed JSON.
#
# Called by /manufacture assemble (step 0a); optionally wired on PreToolUse Bash.
# jq required for full manifest validation; without jq, DAG checks fail-closed.

set -uo pipefail

SELF="${BASH_SOURCE[0]:-$0}"

# ── PreToolUse / harness mode (no pack arg) ───────────────────────────────────
if [[ -z "${1:-}" ]]; then
  # Interactive CLI with no pack → usage (do not hang on cat)
  if [[ -t 0 ]]; then
    echo "usage: manuf-pack-validate.sh <specs/NNN-feature dir>" >&2
    exit 2
  fi
  INPUT=$(cat || true)
  if [[ -z "${INPUT//[[:space:]]/}" ]]; then
    echo "usage: manuf-pack-validate.sh <specs/NNN-feature dir>" >&2
    exit 2
  fi
  export MANUF_PACK_VALIDATE_SELF="$SELF"
  INPUT="$INPUT" python3 - <<'PYEOF'
import json, os, re, subprocess, sys

def allow():
    sys.exit(0)

def block(msg: str):
    # Claude PreToolUse: exit 2 + message on stderr
    sys.stderr.write(msg.rstrip() + "\n")
    print(json.dumps({
        "decision": "block",
        "reason": msg.strip()[:1200],
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": msg.strip()[:1200],
        },
    }))
    sys.exit(2)

raw = os.environ.get("INPUT", "") or ""
try:
    data = json.loads(raw) if raw.strip() else {}
    if not isinstance(data, dict):
        allow()
except Exception:
    allow()

tool = str(data.get("tool_name") or "")
ti = data.get("tool_input") or {}
if not isinstance(ti, dict):
    ti = {}
cmd = str(ti.get("command") or ti.get("cmd") or "")
cwd = str(data.get("cwd") or os.getcwd())

# Only gate Bash-like tools
if tool and tool not in {
    "Bash", "bash", "run_terminal_command", "shell", "Shell", ""
}:
    allow()
if not cmd.strip():
    allow()

# Strip quoted strings so echo/tests embedding the phrase do not false-trigger.
stripped = re.sub(
    r"(\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'|\$'(?:\\.|[^'\\])*')",
    " ",
    cmd,
)

# Agent invoking the validator CLI directly → allow (CLI handles exit codes).
# Do NOT treat path mentions (git add …/manuf-pack-validate.sh) as assemble.
if re.search(r"(?:^|[\n;|&])\s*(?:bash\s+)?(?:\S*/)?manuf-pack-validate\.sh\b", stripped, re.I):
    allow()

# Real assemble / pack-dispatch only (token-boundary, not substring in docs)
ASSEMBLE_RE = re.compile(
    r"(?:^|[\n;|&])\s*(?:\S*/)?manufacture\s+assemble\b|"
    r"(?:^|[\n;|&])\s*(?:\S*/)?manufacture\.js\b|"
    r"\bargs\.mode\s*=\s*[\"']?assemble\b",
    re.I,
)
if not ASSEMBLE_RE.search(stripped):
    allow()

# Bypass: say "manuf-pack-ok" in the conversation
transcript = str(data.get("transcript_path") or "")
if transcript and os.path.isfile(transcript):
    try:
        with open(transcript, "rb") as f:
            f.seek(0, 2)
            size = f.tell()
            f.seek(max(0, size - 200_000))
            tail = f.read().decode("utf-8", "ignore").lower()
        if re.search(r"\bmanuf[-_ ]?pack[-_ ]?ok\b", tail):
            allow()
    except OSError:
        pass

PACK_RE = re.compile(
    r"(?:^|[\s`\"'=])("
    r"(?:/[^/\s`\"']+)*/specs/[A-Za-z0-9._-]+|"
    r"(?:\.?/)?specs/[A-Za-z0-9._-]+"
    r")",
    re.I,
)
packs = []
for m in PACK_RE.finditer(stripped):
    p = m.group(1).rstrip("/'\"`,.")
    if p not in packs:
        packs.append(p)
# flags only — never bare "pack =" (matches prose like "pack extraction")
for m in re.finditer(r"(?:--pack|--pack-dir)\s*[= ]\s*([^\s\"']+)", stripped, re.I):
    p = m.group(1).rstrip("/'\"`,.")
    if p not in packs:
        packs.append(p)

if not packs:
    block(
        "MANUF-PACK GATE: assemble detected but no pack path "
        "(specs/NNN-feature) found in the command. Pass the pack dir or say manuf-pack-ok to bypass."
    )

self_path = os.environ.get("MANUF_PACK_VALIDATE_SELF") or os.path.expanduser(
    "~/.claude/hooks/manuf-pack-validate.sh"
)
for pack in packs:
    path = pack if os.path.isabs(pack) else os.path.join(cwd, pack)
    proc = subprocess.run(
        ["bash", self_path, path],
        text=True,
        capture_output=True,
        check=False,
    )
    out = ((proc.stdout or "") + (proc.stderr or "")).strip()
    if proc.returncode == 0:
        if out:
            sys.stderr.write(out + "\n")
        continue
    msg = out or f"manuf-pack-validate failed on {path} (exit {proc.returncode})"
    block("MANUF-PACK GATE (assemble blocked):\n" + msg)

allow()
PYEOF
  exit $?
fi

PACK="${1:-}"
[ -z "$PACK" ] && { echo "usage: manuf-pack-validate.sh <specs/NNN-feature dir>"; exit 2; }
[ -d "$PACK" ] || { echo "INVALID: pack dir not found: $PACK"; exit 1; }

fail=0
err() { echo "INVALID: $*"; fail=1; }

# ── 1. Required top-level files exist ─────────────────────────────────────────
for f in spec.md manifest.json execution-plan.md risks.md verification.md; do
  [ -f "$PACK/$f" ] || err "missing required file: $f"
done

# ── 2. spec.md carries End-State + Success Criteria ───────────────────────────
if [ -f "$PACK/spec.md" ]; then
  grep -qE '^##[[:space:]]+End-State' "$PACK/spec.md" || err "spec.md has no ## End-State"
  grep -qE '^##[[:space:]]+Success Criteria' "$PACK/spec.md" || err "spec.md has no ## Success Criteria"
fi

# ── 2b. Phase 0 product artifacts are present AND user-locked ──────────────────
# No design half without a PRD + PR-FAQ the user has locked.
# Stamp grammar: 'Locked: YYYY-MM-DD by <user>' (bold-tolerant). HONEST LIMIT:
# bash proves the stamp EXISTS, not that a human typed LOCKED — that residual
# risk is guarded by reviewing the pack PR.
LOCK_RE='^[[:space:]]*(\*\*)?Locked(\*\*)?:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+by[[:space:]]+.+'
for pf in prd.md pr-faq.md; do
  if [ ! -f "$PACK/$pf" ]; then
    err "missing Phase 0 artifact: $pf (write it and have the user lock it before the design half)"
  elif ! grep -qE "$LOCK_RE" "$PACK/$pf"; then
    err "$pf has no 'Locked: YYYY-MM-DD by <user>' stamp — Phase 0 gate #1 not passed (never self-stamp)"
  fi
done

# ── 3. Every component/*.md has all 7 Haiku-proof fields ──────────────────────
# Each field must appear as a STRUCTURED LABEL — a line that begins with the
# field name (optionally as a markdown heading or bold), followed by ':' or a
# heading. This rejects the "keyword buried in prose" false-pass : `CODE logic in the narrative` no longer satisfies the CODE field;
# a real `## CODE`, `**CODE**:`, `CODE:` label does.
# HONEST LIMIT: bash proves the field is STRUCTURALLY PRESENT, not that its body
# holds real verbatim code / a real file:line. That semantic grade is the
# planner's job + the assemble-time BEFORE fit-check (which reads the real slot).
FIELDS=(PLACEMENT CODE COMMANDS EXPECTED PRECONDITIONS POSTCONDITIONS STOP)
compdir="$PACK/components"
if [ ! -d "$compdir" ] || [ -z "$(ls -A "$compdir" 2>/dev/null | grep -E '\.md$' || true)" ]; then
  err "components/ dir missing or has no *.md — a pack with no components is not buildable"
else
  for cf in "$compdir"/*.md; do
    [ -e "$cf" ] || continue
    for field in "${FIELDS[@]}"; do
      # line-anchored label: optional #/##/### or ** or -, then FIELD, then : or ** or end/heading
      grep -qiE "^[[:space:]]*(#{1,6}[[:space:]]*|\*\*|-[[:space:]]+)?${field}([[:space:]]*\**[[:space:]]*:|[[:space:]]*\**[[:space:]]*$)" "$cf" \
        || err "$(basename "$cf"): missing structured Haiku-proof field label '${field}' (must be a heading or 'LABEL:' line, not prose)"
    done
  done
fi

# ── 4. risks.md names mitigation AND detection (no undetected failure mode) ────
# Negation-aware: 'unmitigated' / 'no mitigation' must NOT satisfy the mitigation
# check. Require a positive mitigation/detection label line.
if [ -f "$PACK/risks.md" ]; then
  grep -qiE '^[[:space:]]*(#{1,6}[[:space:]]*|\*\*|-[[:space:]]+|\|)?[[:space:]]*mitigat(e|ion)' "$PACK/risks.md" \
    || err "risks.md names no mitigation (need a 'mitigation:' label, not the word buried/negated in prose)"
  grep -qiE '^[[:space:]]*(#{1,6}[[:space:]]*|\*\*|-[[:space:]]+|\|)?[[:space:]]*(detection|guard|monitor)' "$PACK/risks.md" \
    || err "risks.md names no detection/guard (a failure mode with no detector is a future patch)"
fi

# ── 5. manifest.json — machine contract, DAG soundness (needs jq) ──────────────
MAN="$PACK/manifest.json"
if [ -f "$MAN" ]; then
  if command -v jq >/dev/null 2>&1; then
    jq empty "$MAN" 2>/dev/null || err "manifest.json is not valid JSON"
    if jq empty "$MAN" 2>/dev/null; then
      # 5a. components non-empty, each has id/spec/tier/order
      [ "$(jq '.components | length' "$MAN")" -gt 0 ] || err "manifest components[] is empty"
      jq -e 'all(.components[]; has("id") and has("spec") and has("tier") and has("order"))' "$MAN" >/dev/null \
        || err "a manifest component is missing id/spec/tier/order"
      # 5b. tier is a known executor tier
      jq -e 'all(.components[]; .tier | IN("cheap","code","adversarial","native"))' "$MAN" >/dev/null \
        || err "a component tier is not one of cheap|code|adversarial|native"
      # 5c. every referenced spec file exists
      while IFS= read -r spec; do
        [ -f "$PACK/$spec" ] || err "manifest references missing spec file: $spec"
      done < <(jq -r '.components[].spec' "$MAN")
      # 5d. DAG: every dep resolves to a real component id, and no dep points to a later order (topological)
      jq -e '
        (.components | map(.id)) as $ids
        | all(.components[]; (.deps // []) | all(. as $d | $ids | index($d) != null))
      ' "$MAN" >/dev/null || err "a component dep references an unknown component id"
      jq -e '
        (reduce .components[] as $c ({}; .[$c.id] = $c.order)) as $ord
        | all(.components[]; . as $c | (.deps // []) | all($ord[.] < $c.order))
      ' "$MAN" >/dev/null || err "manifest DAG is not topologically ordered (a dep has an order >= its dependent)"
      # 5e. every UI screen has id/name + a mock
      # A design that never landed in the pack is not a design — require design/ files on disk.
      jq -e '(.ui_screens // []) | all(has("id") and has("name") and (.mock // "" | length > 0))' "$MAN" >/dev/null \
        || err "a ui_screen is missing id, name or mock"
      # 5e-i-strict: mock paths must live under design/
      while IFS= read -r mf; do
        [ -z "$mf" ] && continue
        case "$mf" in
          design/*) ;;
          *) err "ui_screen.mock must be under design/ (got: $mf) — export the design into the pack" ;;
        esac
      done < <(jq -r '(.ui_screens // [])[] | (.mock // empty)' "$MAN")
      # 5e-ii. every referenced mock / data_contract file exists
      while IFS= read -r mf; do
        [ -z "$mf" ] || [ -f "$PACK/$mf" ] || err "ui_screen references missing file: $mf — the design was never exported into the pack"
      done < <(jq -r '(.ui_screens // [])[] | (.mock // empty), (.data_contract // empty)' "$MAN")
      # 5e-iii. ui_screens => design/ + locked ui-flow + data_contract + taste brief
      if [ "$(jq '(.ui_screens // []) | length' "$MAN")" -gt 0 ]; then
        { [ -d "$PACK/design" ] && [ -n "$(ls -A "$PACK/design" 2>/dev/null)" ]; } \
          || err "manifest declares ui_screens but design/ is missing or empty — mocks must be vendored at Phase 0 (gate #2); do not hand-roll UI in HLD"
        { [ -f "$PACK/ui-flow.md" ] && grep -qE "$LOCK_RE" "$PACK/ui-flow.md"; } \
          || err "ui_screens declared but ui-flow.md is missing its 'Locked:' stamp — mock gate #2 not passed"
        jq -e '(.ui_screens // []) | all((.data_contract // "" | length) > 0)' "$MAN" >/dev/null \
          || err "every ui_screen needs data_contract under design/* (real SoT field shapes; ban silent dummy prod values)"
        if [ ! -f "$PACK/design/TASTE-BRIEF.md" ] && [ ! -f "$PACK/design/taste-brief.md" ]; then
          err "design/TASTE-BRIEF.md missing — write the taste brief before designing (see manuf-product-design)"
        fi
      fi
      # 5e-iv. components must not ship dummy production tokens without STOP/NEEDS_LIVE_WIRE
      if [ -d "$PACK/components" ]; then
        # Matching raw lines flagged the components' OWN guards: a verification
        # command `grep -RInE "...|sampleData|..." src/` contains the token, and a
        # prohibition "No production path may contain `sampleData`" does too. Both are
        # the pack enforcing the rule, not breaking it. So strip inline code spans and
        # fenced code blocks first — a token inside a code span is a command or a
        # forbidden-words list, never a production value — then apply the prohibition
        # filter to what is left. (An earlier version fired 18 times on a pack with
        # zero real uses. A gate the work has to learn to dodge is worth less than no gate.)
        if python3 - "$PACK/components" <<'PYEOF' >/dev/null; then
import os, re, sys
TOK = re.compile(r'\b(dummyData|sampleData|fakeUser|lorem ipsum|TODO: wire later|hardcoded demo)\b')
SPAN = re.compile(r'`[^`]*`')
OK = re.compile(r'NEEDS_LIVE_WIRE|STOP|forbid|ban\b|must not|may not|never|no production|'
                r'not a|rather than|instead of|halt|refus|reject|red check|would require', re.I)
hits = []
for dp, dn, fs in os.walk(sys.argv[1]):
    for fn in fs:
        if not fn.endswith('.md'):
            continue
        fenced = False
        for i, line in enumerate(open(os.path.join(dp, fn), encoding='utf-8', errors='replace'), 1):
            if line.lstrip().startswith('```'):
                fenced = not fenced
                continue
            if fenced or OK.search(line):
                continue
            if TOK.search(SPAN.sub('', line)):
                hits.append(f"{os.path.join(dp, fn)}:{i}")
sys.exit(0 if hits else 1)
PYEOF
          err "components/ contain dummy/placeholder production tokens without NEEDS_LIVE_WIRE+STOP — wire real SoT or halt the component"
        fi
      fi
    fi
  else
    # FAIL-CLOSED: a skipped structural check must
    # NOT pass. Without jq the DAG/tier/dep-existence checks cannot run, so a
    # malformed manifest would sail through to a weak executor. Reject instead.
    err "jq not found — cannot validate manifest.json DAG/tier/dep integrity. Install jq (brew install jq) or fix the environment; a pack whose machine contract is unverifiable is NOT Haiku-proof."
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "VALID: $PACK is Haiku-proof (Phase 0 locked · all components have 7 fields · risks mitigated+detected · manifest DAG sound)."
  exit 0
fi
echo "---"
echo "Pack is NOT Haiku-proof. Fix the fields above and re-validate. Do NOT bypass — a missing field is exactly what lets a weak executor err."
exit 1
