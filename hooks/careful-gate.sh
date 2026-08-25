#!/usr/bin/env bash
# careful-gate.sh — PreToolUse(Bash). Speed-bump for IRREVERSIBLE ops while
# `careful` mode is on. Inert unless ~/.claude/state/careful.flag exists.
#
# Toggle ON:  touch ~/.claude/state/careful.flag
# Toggle OFF: rm    ~/.claude/state/careful.flag
#
# Blocks only genuinely irreversible / destructive bash:
#   rm -rf · rm -fr · git push --force/-f · git reset --hard · git clean -fd
#   DROP TABLE/DATABASE · TRUNCATE · dd · mkfs · sudo rm
# Reversible edits and normal git are allowed (that's what `freeze` is for).
#
# Escape (one-off): add literal `# careful: ignore` to the command.
# Hard path: a deny entry in settings.json already blocks rm -rf / etc — this
# gate adds a forcing PAUSE+reason during a self-declared careful window.
set -uo pipefail
trap 'exit 0' ERR

FLAG="${HOME}/.claude/state/careful.flag"
[ -f "$FLAG" ] || exit 0   # fast path: mode off → invisible

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c "
import json,sys
try:
    d=json.loads(sys.stdin.read()); print((d.get('tool_input',{}) or {}).get('command',''))
except Exception:
    print('')
")
[ -z "$CMD" ] && exit 0

# escape hatch
echo "$CMD" | grep -qE '#[[:space:]]*careful:[[:space:]]*ignore' && exit 0

DANGER='rm[[:space:]]+-[rf]*[rf]|git[[:space:]]+push[[:space:]]+.*(--force|-f\b)|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+clean[[:space:]]+-[a-z]*f|DROP[[:space:]]+(TABLE|DATABASE)|TRUNCATE[[:space:]]+TABLE|\bdd[[:space:]]+if=|\bmkfs|sudo[[:space:]]+rm'
echo "$CMD" | grep -qiE "$DANGER" || exit 0

reason="🔒 CAREFUL MODE — irreversible op paused.

Command (truncated):
    ${CMD:0:200}

Careful mode is on (~/.claude/state/careful.flag). This command is destructive/irreversible.
Confirm it is intended and necessary. Then either:
  1. Re-run with literal '# careful: ignore' appended, OR
  2. Disable the mode: rm ~/.claude/state/careful.flag"

python3 - <<PYEOF
import json
print(json.dumps({
  "decision":"block",
  "reason":"""$reason""",
  "systemMessage":"[careful-gate] irreversible op paused — confirm or rm the careful flag"
}))
PYEOF
exit 2
