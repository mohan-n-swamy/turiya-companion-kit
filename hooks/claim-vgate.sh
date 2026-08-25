#!/usr/bin/env bash
# claim-vgate.sh — unified Stop-event hook for ALL claim categories.
#
# Premise: a language model has no memory of its own promises and no way to
#   keep them. Only a mechanism can hold it in lane. So every claim category
#   gets the same shape of gate: assert it, and the transcript must contain
#   the evidence.
#
# Four claim categories, one shape of gate:
#
#   1. DEPLOY-CLAIM         — "deployed/shipped/landed/served/live/released"
#      Evidence: `SUCCESS · <surface>=<id>` line from a canonical wrapper.
#
#   2. BEHAVIOR-CLAIM       — "click X / press Y", "you'll see Z",
#                              "chip/button/page should change/show/update/work",
#                              "POST/GET returns/fires"
#      Evidence: an mcp__plugin_chrome-devtools-mcp_chrome-devtools__click
#                tool_use (or evaluate_script with explicit DOM probe) in
#                the same session, followed by a tool_result demonstrating
#                the asserted new state.
#
#   3. VERIFICATION-CLAIM   — "verified/confirmed", "V-gate green/passed",
#                              "works correctly/now/end-to-end",
#                              "passes/green/all tests pass"
#      Evidence: a Bash tool_result (or equivalent) with success indicators
#                in the last N events — e.g. `passed`, `HTTP 200`, exit-code
#                0 marker, grep match printed, etc.
#
#   4. DATA-CLAIM           — "column X exists", "schema has Y",
#                              "row count = N", "table T contains"
#      Evidence: a tool_result containing psql/sql-like output showing the
#                asserted shape (column name in result, row count number,
#                etc.).
#
# Cross-session-resilient: the hook ONLY trusts this session's transcript.
# If /clear was run before the claim, the new transcript starts fresh and
# the hook will block any unbacked claim — by design. Re-establish
# evidence in the new session before re-asserting.
#
# Hook payload (Stop): JSON on stdin with { "transcript_path": ... }.

set -euo pipefail

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null || echo "")

if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]]; then
    exit 0
fi

TRANSCRIPT="$TRANSCRIPT" python3 << 'PYEOF'
import json, os, re, sys

TRANSCRIPT = os.environ.get("TRANSCRIPT", "")

# ─────────────────────────────────────────────────────────────────────────
# Claim-category dictionary.
# ─────────────────────────────────────────────────────────────────────────

CATEGORIES = {
    "deploy": {
        "words": [
            r"\bdeployed\b",
            r"\bshipped\b",
            # 'landed' / 'served' removed 2026-06-02 — too polysemous for a deploy
            # lexicon. In any file/rig conversation an artifact referent (a .json/.sh
            # path, `commit`, `production`) sits within REFERENT_WINDOW, so the
            # structural check can't save them: "what we landed on", "served as",
            # "the page served" all trip. A real deploy claim uses deployed / shipped
            # / gone-live / rolled-out / released / pushed-to-prod — never these two
            # alone. (Wedged this session 4x: served, landed.)
            r"\bgone[ -]live\b",
            r"\bgo-?live\b",
            r"\bin production\b",
            r"\bproduction[- ]ready\b",
            r"\brolled[ -]out\b",
            r"\bcut over\b",
            r"\breleased\b",
            r"\bpushed to (?:prod|production|vps)\b",
        ],
        "evidence_regex": [
            r"SUCCESS\s*[·:|]\s*\w+\s*=\s*\S+",
            # Strongest deploy proof: the commit the RUNNING system reports serving
            # equals the one you intended. Read it from the running process (a
            # /health endpoint, `docker exec`), never from git on disk — a cached
            # build can serve old code while the deploy script prints SUCCESS.
            r"served commit == intended.*running container",
        ],
        "evidence_hint": (
            "Deploy through a wrapper script that prints a machine-checkable success line. "
            "Gold proof = `served commit == intended (<sha>) [read from running container]` "
            "— read the commit from the RUNNING system (/health endpoint, docker exec), not git on disk. "
            "Bare `SUCCESS · <surface>=<id>` is accepted but weaker (a cached build can false-green it)."
        ),
    },
    "behavior": {
        # Behavior claims = the model is asserting a UI/runtime effect
        # the user can observe (chip changes, button click outcome,
        # POST fires, page renders, etc.).
        "words": [
            r"\bclick\s+(?:the\s+)?[\"'`]?[A-Z][\w \-]{0,40}[\"'`]?\b",   # "click X"
            r"\bpress\s+(?:the\s+)?[\"'`]?[A-Z][\w \-]{0,40}[\"'`]?\b",
            r"\byou(?:'ll| will| should)\s+see\b",
            r"\bshould\s+(?:show|change|update|render|appear|work|disappear|hide|reveal|trigger|fire|return)\b",
            r"\bchip\s+(?:will|should|now|then)\s+(?:change|show|update|read|display|become)",
            r"\bbutton\s+(?:will|should|now|then)\s+(?:disappear|hide|change|trigger)",
            r"\bpage\s+(?:will|should|now|then)\s+(?:show|render|update|change|display)",
            r"\b(?:POST|GET|DELETE|PATCH)\s+\S+\s+(?:returns|will return|now returns|fires|will fire)\b",
            r"\bnow shows\b",
            r"\b(?:chip|button|panel|section)\s+(?:turns|becomes|displays|reads)\s+",
        ],
        "evidence_regex": [
            # Chrome MCP click tool name appearing in tool_use
            r"chrome-devtools-mcp_chrome-devtools__click",
            r"mcp__claude-in-chrome__\w+",
            # Or an explicit DOM-probe via evaluate_script with the asserted text echoed back
            r"mcp__plugin_chrome-devtools-mcp_chrome-devtools__evaluate_script",
        ],
        "evidence_hint": (
            "Verify behavior YOURSELF this session via Chrome MCP "
            "(click + evaluate_script reading live DOM) BEFORE asserting. "
            "Snapshot tools→stale DOM; prefer evaluate_script + document.querySelector/textContent."
        ),
    },
    "verification": {
        # Verification claims = the model says a thing is verified, works,
        # passes, is confirmed. Requires actual tool output evidence.
        "words": [
            r"\bverified\b",
            r"\bconfirmed\b",
            r"\bV-?gate\s+(?:green|passed|met|complete|ok)\b",
            r"\bworks\s+(?:correctly|now|fine|end-?to-?end|as expected)\b",
            r"\bworking\s+(?:correctly|now|fine|end-?to-?end|as expected)\b",
            r"\b(?:all\s+)?tests?\s+(?:pass|passed|green|all green|are green)\b",
            r"\bproven\b",
            r"\bhealth(?:y)?\s+check\s+(?:passed|green|ok)\b",
            r"\bsmoke[ -]tested\b",
            r"\bend-?to-?end\s+(?:works|verified|passed|green)\b",
        ],
        "evidence_regex": [
            # ANY tool_result captured in transcript is sufficient as long
            # as it followed a relevant Bash/curl/test call. We do a fuzzy
            # check below for stronger signals.
            r"passed",
            r"\b200\b",
            r"\bHTTP\s+200\b",
            r"\bok\b",
            r"\bsuccess\b",
            r"\bexit\s+code\s+0\b",
            r"\b\d+\s+passed",
        ],
        "evidence_hint": (
            "Cite tool call that verified claim. Run pytest/curl/grep/psql "
            "THIS SESSION → output in transcript BEFORE asserting."
        ),
    },
    "data": {
        "words": [
            r"\bcolumn\s+\w+\s+(?:exists|does not exist)\b",
            r"\bschema\s+has\b",
            r"\brow\s+count\s*=\s*\d+\b",
            r"\btable\s+\w+\s+(?:exists|contains|has)\b",
            r"\b\d+\s+rows? (?:returned|in|match)\b",
            r"\bquery\s+returned\s+\d+\s+rows?\b",
        ],
        "evidence_regex": [
            r"\(\d+\s+rows?\)",     # psql footer
            r"information_schema",
            r"SELECT",
            r"\\d\s+\w",            # psql describe
            r"snowflake",
        ],
        "evidence_hint": (
            "Probe real data first (tenet `probe-real-data`, ~/.claude/CLAUDE.md): "
            "run psql `\\d` or SELECT, quote result. Memory-recall of schema ≠ evidence."
        ),
    },
}

# 2026-07-31 rebuild: narrowed to DEPLOY claims only. Behavior/verification/data
# categories caused block-regeneration loops on frontier models; deploy claims
# (prod-facing, highest blast radius) keep the hard gate.
CATEGORIES = {"deploy": CATEGORIES["deploy"]}

# ─────────────────────────────────────────────────────────────────────────
# Load transcript.
# ─────────────────────────────────────────────────────────────────────────

try:
    with open(TRANSCRIPT) as f:
        events = [json.loads(ln) for ln in f if ln.strip()]
except Exception:
    sys.exit(0)

# Find the last assistant turn's text content.
last_assistant_text = ""
for ev in reversed(events):
    if ev.get("type") != "assistant":
        continue
    msg = ev.get("message", {})
    content = msg.get("content", [])
    if isinstance(content, str):
        last_assistant_text = content
        break
    parts = []
    for block in content:
        if block.get("type") == "text":
            parts.append(block.get("text", ""))
    last_assistant_text = "\n".join(parts)
    break

if not last_assistant_text:
    sys.exit(0)

# Strip fenced code blocks from CLAIM scan — claim words inside code blocks
# are pasted output, not prose claims.
text_no_code = re.sub(r"```.*?```", "", last_assistant_text, flags=re.DOTALL)

# Also strip RELAY contexts where claim-words are QUOTED/reported, not asserted
# by the model as its own current claim (2026-06-01, per rig-audit P1.1 —
# subject-blindness false-positives when relaying audit findings, prior-state
# summaries, table cells, or pasted text):
#   - markdown table rows  | ... |
#   - blockquotes          > ...
#   - quoted spans         "..."  and  `...`
text_no_code = re.sub(r"(?m)^\s*\|.*$", "", text_no_code)       # table rows
text_no_code = re.sub(r"(?m)^\s*>.*$", "", text_no_code)        # blockquotes
text_no_code = re.sub(r"\"[^\"]*\"", "", text_no_code)          # double-quoted spans
text_no_code = re.sub(r"`[^`]*`", "", text_no_code)             # inline-code spans

# ─────────────────────────────────────────────────────────────────────────
# STRUCTURAL claim gate (root-cause fix 2026-06-01).
# ROOT CAUSE: the gate was LEXICAL — it tripped on the bare presence of a
# claim word ("landed"/"served"/"deployed"/"verified") anywhere in prose, with
# no model of whether the word was ASSERTING STATE about a real session
# artifact. Conversational/design use ("what you landed on", "nothing deployed")
# tripped it; dodging one word hit the next (dense completion vocabulary) → a
# token-burning retry loop, especially in design-conversation sessions.
# FIX: lexical presence != claim. A claim = [session-artifact referent] +
# [state assertion] in PROXIMITY. A claim word only counts if a referent — a
# file path, deploy wrapper, container/infra noun, URL/host, git sha, or an
# explicit "the migration/build/PR/production/…" — appears within REFERENT_WINDOW
# chars. Applies to deploy/verification/data; `behavior` keeps its own
# multi-word structured patterns (already low false-positive).
ARTIFACT_REFERENT = re.compile(
    r"\b[\w./-]+\.(?:py|sh|ts|tsx|js|jsx|mjs|cjs|go|rs|rb|sql|ya?ml|json|toml|html|css|conf|cfg|service|plist)\b"
    r"|\bship-(?:frontend|backend)\.sh\b|\bapply-mig\.sh\b"
    r"|\b(?:docker|container|compose|k8s|kubernetes|nginx|launchd|launchctl|cron|systemd|pm2)\b"
    r"|https?://\S+|\b[\w.-]+\.(?:dev|com|in|net|io|local)\b|\blocalhost\b|:\d{2,5}\b"
    r"|\b[0-9a-f]{7,40}\b"
    r"|\bproduction\b|\bprod\b|\bVPS\b|\bstaging\b"
    r"|\bthe\s+(?:migration|build|container|deploy(?:ment)?|PR|pull[- ]request|endpoint|service|schema|table|column|row|query|index|script|hook|wrapper|job|plist|function|module|pipeline|worker|container)\b"
    r"|\bPR\s*#?\d+\b|\bcommit\b|\bbranch\b"
    r"|\bpytest\b|\bcurl\b|\bpsql\b|\bnpm\b|\bgrep\b|\btests?\b|\btest\s+suite\b"
    r"|\bschema\b|\brow\s+count\b|\bSELECT\b|\binformation_schema\b",
    re.IGNORECASE,
)
REFERENT_WINDOW = 180
STRUCTURAL_CATS = {"deploy", "verification", "data"}

# Git-commit exemption: a `git commit` is a referent
# that satisfies ARTIFACT_REFERENT (commit/branch/sha), but committing is NOT
# deploying. A deploy claim must point at a SERVED surface (prod/VPS/staging/
# host/URL/port, or a canonical ship wrapper). If a 'shipped'-class hit's window
# contains git-commit signal AND NO served-surface signal, it's a git claim →
# exempt from the deploy gate. Narrow by design: any prod/host/wrapper referent
# nearby still trips (real deploys unaffected). Wedged 3x this session on doc/
# skill commits to ~/.claude.
DEPLOY_SERVED_REFERENT = re.compile(
    r"\bproduction\b|\bprod\b|\bVPS\b|\bstaging\b"
    r"|https?://\S+|\b[\w.-]+\.(?:dev|com|in|net|io)\b|\blocalhost\b|:\d{2,5}\b"
    r"|\bship-(?:frontend|backend)\.sh\b|\bapply-mig\.sh\b"
    r"|\b(?:docker|container|compose|k8s|kubernetes|nginx|launchd|pm2|systemd)\b"
    r"|\bgone[ -]live\b|\bgo-?live\b|\brolled[ -]out\b|\bpushed to (?:prod|production|vps)\b",
    re.IGNORECASE,
)
DEPLOY_GIT_ONLY = re.compile(r"\bcommit(?:ted|s)?\b|\bbranch\b|\b[0-9a-f]{7,40}\b", re.IGNORECASE)

# ─────────────────────────────────────────────────────────────────────────
# Collect ALL tool_result text in this session (one big haystack to grep
# for evidence patterns). Also collect tool_use names for behavior check.
# ─────────────────────────────────────────────────────────────────────────

evidence_haystack_parts = []
tool_use_names = []
for ev in events:
    typ = ev.get("type")
    msg = ev.get("message", {})
    content = msg.get("content", [])
    if not isinstance(content, list):
        continue
    for block in content:
        b_typ = block.get("type") if isinstance(block, dict) else None
        if b_typ == "tool_use":
            tool_use_names.append(block.get("name", ""))
        elif b_typ == "tool_result":
            body = block.get("content", "")
            if isinstance(body, list):
                for sub in body:
                    if isinstance(sub, dict) and sub.get("type") == "text":
                        evidence_haystack_parts.append(sub.get("text", ""))
            elif isinstance(body, str):
                evidence_haystack_parts.append(body)

evidence_haystack = "\n".join(evidence_haystack_parts)
tool_use_blob = "\n".join(tool_use_names)

# Also let evidence in the CURRENT assistant message (e.g. quoted output
# in fenced code blocks) count — necessary so the model can paste a
# SUCCESS line right alongside the claim.
combined_evidence = evidence_haystack + "\n" + last_assistant_text + "\n" + tool_use_blob

# ─────────────────────────────────────────────────────────────────────────
# For each category — match claim words, then check evidence.
# ─────────────────────────────────────────────────────────────────────────

violations = []

for cat_name, cat in CATEGORIES.items():
    needs_referent = cat_name in STRUCTURAL_CATS
    claim_hits = []
    for pat in cat["words"]:
        matched = False
        for m in re.finditer(pat, text_no_code, re.IGNORECASE):
            if needs_referent:
                lo = max(0, m.start() - REFERENT_WINDOW)
                hi = min(len(text_no_code), m.end() + REFERENT_WINDOW)
                window = text_no_code[lo:hi]
                if not ARTIFACT_REFERENT.search(window):
                    continue  # bare conversational use — no artifact referent → not a claim
                # Git-commit exemption (deploy only): a commit/branch/sha referent
                # satisfies ARTIFACT_REFERENT but committing ≠ deploying. Skip when
                # the window has git-only signal and NO served-surface signal.
                if (cat_name == "deploy"
                        and DEPLOY_GIT_ONLY.search(window)
                        and not DEPLOY_SERVED_REFERENT.search(window)):
                    continue  # git commit claim, not a deploy claim → exempt
            claim_hits.append(m.group(0))
            matched = True
            break
        if matched and len(claim_hits) >= 3:
            break
    if not claim_hits:
        continue

    # Evidence search across ALL categories' evidence regexes — but we
    # only require EACH triggered category to have AT LEAST ONE of its
    # listed evidence patterns somewhere in the combined corpus.
    has_evidence = False
    for ev_pat in cat["evidence_regex"]:
        if re.search(ev_pat, combined_evidence, re.IGNORECASE):
            has_evidence = True
            break

    if not has_evidence:
        violations.append({
            "category": cat_name,
            "claim_words": sorted(set(claim_hits))[:3],
            "hint": cat["evidence_hint"],
        })

if not violations:
    sys.exit(0)

# ─────────────────────────────────────────────────────────────────────────
# Build the block message.
# ─────────────────────────────────────────────────────────────────────────

lines = ["HARD-GATE TRIPPED: unverified claim(s) detected.\n"]
for v in violations:
    words = ", ".join(repr(w) for w in v["claim_words"])
    lines.append(
        f"  · [{v['category']:13s}]  claim words: {words}\n"
        f"      fix: {v['hint']}\n"
    )

lines.append(
    "\nEvidence rule (claim-vgate — deploy/behavior/verification/data):\n"
    "Every claim deployed/works/verified/exists-in-data needs evidence in THIS session transcript. "
    "Re-state claim ONLY after running evidence-producing tool "
    "(wrapper · Chrome MCP click · pytest · curl · psql) + output in transcript.\n\n"
    "/clear wipes transcript → no evidence; re-establish before re-asserting.\n"
)
reason = "".join(lines)
cats = ", ".join(v["category"] for v in violations)
print(json.dumps({
    "decision": "block",
    "reason": reason,
    "systemMessage": f"[claim-vgate] BLOCKED ({cats})",
}))
sys.exit(2)
PYEOF
