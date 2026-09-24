#!/usr/bin/env bash
# selftest.sh — proves every shipped hook still has teeth, and the kit is clean.
#
#   bash tests/selftest.sh
#
# Each hook is fed a fixture that MUST be blocked, one that MUST pass, and its
# bypass. A gate is only trusted once it has been seen to deny. Everything runs
# under a throwaway HOME, so your real ~/.claude is never read or written.
# Exit 0 = every assertion passed.
set -uo pipefail
KIT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
H="$KIT/hooks"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME/.claude/state"

pass=0; fail=0
ok()  { pass=$((pass+1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail+1)); printf 'FAIL  %s\n' "$1"; }
# expect <name> <want-exit> <hook> <json>
expect() {
  local name=$1 want=$2 hook=$3 json=$4 got
  printf '%s' "$json" | bash "$H/$hook" >/dev/null 2>&1; got=$?
  [ "$got" = "$want" ] && ok "$name" || bad "$name (want $want, got $got)"
}
# transcript <file> <role> <text> — append one message
transcript() { python3 -c 'import json,sys; print(json.dumps({"type":sys.argv[1],"message":{"role":sys.argv[1],"content":[{"type":"text","text":sys.argv[2]}]}}))' "$2" "$3" >> "$1"; }
bash_in()  { python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2],"transcript_path":sys.argv[3] if len(sys.argv)>3 else ""}))' "$@"; }
write_in() { python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]},"transcript_path":sys.argv[3] if len(sys.argv)>3 else ""}))' "$@"; }

echo "== shell syntax"
for f in "$H"/*.sh "$KIT/install.sh" "$KIT/scripts/"*.sh "$KIT/tests/"*.sh; do
  bash -n "$f" && ok "bash -n $(basename "$f")" || bad "bash -n $(basename "$f")"
done

echo "== careful-gate (opt-in: pauses irreversible commands)"
expect "careful: off → rm -rf passes"          0 careful-gate.sh "$(bash_in 'rm -rf build' /tmp)"
touch "$HOME/.claude/state/careful.flag"
expect "careful: on → rm -rf blocked"          2 careful-gate.sh "$(bash_in 'rm -rf build' /tmp)"
expect "careful: on → ls passes"               0 careful-gate.sh "$(bash_in 'ls -la' /tmp)"
expect "careful: bypass comment passes"        0 careful-gate.sh "$(bash_in 'rm -rf build # careful: ignore' /tmp)"
rm -f "$HOME/.claude/state/careful.flag"

echo "== freeze-gate (opt-in: hard read-only)"
expect "freeze: off → write passes"            0 freeze-gate.sh "$(write_in /tmp/x.txt hi)"
touch "$HOME/.claude/state/freeze.flag"
expect "freeze: on → write blocked"            2 freeze-gate.sh "$(write_in /tmp/x.txt hi)"
expect "freeze: on → rm blocked"               2 freeze-gate.sh "$(bash_in 'rm notes.txt' /tmp)"
expect "freeze: on → git status passes"        0 freeze-gate.sh "$(bash_in 'git status' /tmp)"
rm -f "$HOME/.claude/state/freeze.flag"

echo "== dep-gate (new dependency needs a dep-ok)"
TR="$T/dep.jsonl"; transcript "$TR" user "add a date picker"
REQ="$T/proj/requirements.txt"; mkdir -p "$T/proj"
expect "dep: new requirements.txt with a dep blocked" 2 dep-gate.sh "$(write_in "$REQ" 'requests==2.31.0' "$TR")"
expect "dep: non-manifest file passes"               0 dep-gate.sh "$(write_in "$T/proj/app.py" 'import requests' "$TR")"
transcript "$TR" user "dep-ok"
expect "dep: user dep-ok passes"                     0 dep-gate.sh "$(write_in "$REQ" 'requests==2.31.0' "$TR")"

echo "== config-protection (lint/format config edits need a config-ok)"
TR="$T/cfg.jsonl"; transcript "$TR" user "fix the lint errors"
expect "config: .eslintrc.json edit blocked"   2 config-protection.sh "$(write_in "$T/proj/.eslintrc.json" '{}' "$TR")"
expect "config: source file passes"            0 config-protection.sh "$(write_in "$T/proj/index.js" 'x' "$TR")"
transcript "$TR" user "config-ok"
expect "config: user config-ok passes"         0 config-protection.sh "$(write_in "$T/proj/.eslintrc.json" '{}' "$TR")"

echo "== breadcrumb (appends one line per tool call)"
printf '%s' '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"ls"}}' | bash "$H/breadcrumb.sh" >/dev/null 2>&1
[ -s "$HOME/.claude/state/breadcrumbs/claude-s1.log" ] && ok "breadcrumb: log written" || bad "breadcrumb: log written"

echo "== claim-vgate (Stop: a deploy claim needs evidence in the transcript)"
TR="$T/claim.jsonl"; transcript "$TR" user "ship it"; transcript "$TR" assistant "Deployed to production, it is live now."
expect "claim: unevidenced deploy claim blocked" 2 claim-vgate.sh "{\"transcript_path\":\"$TR\"}"
TR="$T/claim2.jsonl"; transcript "$TR" user "thoughts?"; transcript "$TR" assistant "I think the second option reads better."
expect "claim: no claim passes"                0 claim-vgate.sh "{\"transcript_path\":\"$TR\"}"

echo "== design-source-gate (big UI write needs a design/ folder)"
R="$T/app"; mkdir -p "$R/.git" "$R/src"
UI='export default function Page() {
  return (
    <main className="p-8">
      <section className="grid gap-4">
        <div className="card">One</div>
        <div className="card">Two</div>
      </section>
    </main>
  )
}'
expect "design: new UI with no design/ blocked" 2 design-source-gate.sh "$(write_in "$R/src/Page.tsx" "$UI")"
expect "design: bypass comment passes"          0 design-source-gate.sh "$(write_in "$R/src/Page.tsx" "// design-gate: ignore
$UI")"
expect "design: logic file passes"              0 design-source-gate.sh "$(write_in "$R/src/util.ts" "$UI")"
mkdir -p "$R/design" && echo mock > "$R/design/page.html"
expect "design: with design/ passes"            0 design-source-gate.sh "$(write_in "$R/src/Page.tsx" "$UI")"

echo "== manuf-pack-validate (a pack must leave the executor zero decisions)"
P="$T/specs/001-demo"; mkdir -p "$P/components"
for f in spec.md prd.md pr-faq.md execution-plan.md verification.md; do echo "# $f" > "$P/$f"; done
printf '## End-State\nx\n## Success Criteria\nx\n' > "$P/spec.md"
printf 'Locked: 2026-01-01 by tester\n' | tee -a "$P/prd.md" >> "$P/pr-faq.md"
printf -- '- mitigation: x\n- detection: y\n' > "$P/risks.md"
printf '## PLACEMENT\na:1\n## CODE\nx\n## COMMANDS\nx\n## EXPECTED\nx\n## PRECONDITIONS\nx\n## POSTCONDITIONS\nx\n## STOP\nx\n' > "$P/components/C1.md"
echo '{"components":[{"id":"C1","spec":"components/C1.md","tier":"code","order":1}],"ui_screens":[]}' > "$P/manifest.json"
bash "$H/manuf-pack-validate.sh" "$P" >/dev/null 2>&1 && ok "pack: complete pack VALID" || bad "pack: complete pack VALID"
sed -i.bak '/## STOP/,$d' "$P/components/C1.md"
bash "$H/manuf-pack-validate.sh" "$P" >/dev/null 2>&1; [ $? = 1 ] && ok "pack: missing STOP INVALID" || bad "pack: missing STOP INVALID"
expect "pack hook: assemble without a pack blocked" 2 manuf-pack-validate.sh "$(bash_in 'manufacture assemble' /tmp)"
expect "pack hook: unrelated command passes"        0 manuf-pack-validate.sh "$(bash_in 'npm test' /tmp)"

echo "== manuf-qa-stamp (grades open gates only when stamped)"
S="$H/manuf-qa-stamp.sh"
bash "$S" check design-qa "$P" --min=A >/dev/null 2>&1; [ $? = 1 ] && ok "stamp: none → fail" || bad "stamp: none → fail"
bash "$S" write design-qa "$P" B >/dev/null; bash "$S" check design-qa "$P" --min=A >/dev/null 2>&1; [ $? = 1 ] && ok "stamp: B < A → fail" || bad "stamp: B < A → fail"
bash "$S" write design-qa "$P" A >/dev/null; bash "$S" check design-qa "$P" --min=A >/dev/null 2>&1 && ok "stamp: A → pass" || bad "stamp: A → pass"
bash "$S" check design-qa "$P" --min=A --env=prod >/dev/null 2>&1; [ $? = 1 ] && ok "stamp: prod needs env=prod" || bad "stamp: prod needs env=prod"

echo "== workflows"
( cd "$KIT/workflows" && node ./manufacture.test.mjs >/dev/null ) && ok "manufacture.js gates" || bad "manufacture.js gates"
( cd "$KIT/workflows/lib" && node ./delegate-first.test.mjs >/dev/null ) && ok "delegate-first tiers" || bad "delegate-first tiers"

echo "== installer (fresh HOME, twice: second run must skip everything)"
IH="$T/installhome"; mkdir -p "$IH"
HOME="$IH" "$KIT/install.sh" --harness > "$T/i1" 2>&1 && ok "install --harness runs" || bad "install --harness runs"
HOME="$IH" "$KIT/install.sh" --harness > "$T/i2" 2>&1
grep -q "Skills: 0 installed" "$T/i2" && grep -q "Hooks: 0 installed" "$T/i2" && grep -q "Workflows: 0 installed" "$T/i2" \
  && ok "second install overwrites nothing" || bad "second install overwrites nothing"
[ ! -e "$IH/.claude/settings.json" ] && ok "installer never writes settings.json" || bad "installer never writes settings.json"

echo "== kit hygiene"
"$KIT/scripts/leak-sweep.sh" >/dev/null && ok "no private references" || bad "no private references (run scripts/leak-sweep.sh)"
"$KIT/scripts/leak-sweep.sh" --refs >/dev/null && ok "every referenced kit path exists" || bad "every referenced kit path exists (run scripts/leak-sweep.sh --refs)"
"$KIT/scripts/leak-sweep.sh" --counts >/dev/null && ok "README counts match" || bad "README counts match (run scripts/leak-sweep.sh --counts)"
"$KIT/scripts/leak-sweep.sh" --explained >/dev/null && ok "every component explained in README" || bad "every component explained in README (run scripts/leak-sweep.sh --explained)"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
