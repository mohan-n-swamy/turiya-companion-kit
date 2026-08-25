#!/usr/bin/env bash
# freeze-gate.sh — PreToolUse(Write|Edit|MultiEdit|NotebookEdit|Bash).
# HARD read-only mode. Inert unless ~/.claude/state/freeze.flag exists.
#
# Toggle ON:  touch ~/.claude/state/freeze.flag
# Toggle OFF: rm    ~/.claude/state/freeze.flag
#
# When frozen:
#   - ALL Edit / Write / MultiEdit / NotebookEdit  → blocked.
#   - Mutating Bash (write-redirect, rm, mv, cp, sed -i, tee, mkdir, touch,
#     git commit/push/reset/checkout/merge/rebase, dd, install) → blocked.
#   - Read-only Bash (ls, cat, grep, git status/log/diff, wc…) → allowed.
#
# Escape (one-off Bash): add literal `# freeze: ignore` to the command.
# To actually edit: rm the flag. Freeze is "investigate without touching."
set -uo pipefail
trap 'exit 0' ERR

FLAG="${HOME}/.claude/state/freeze.flag"
[ -f "$FLAG" ] || exit 0   # fast path: mode off → invisible

INPUT=$(cat)
TOOL=$(printf '%s' "$INPUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());print(d.get('tool_name',''))" 2>/dev/null || echo "")

block() {
  local why="$1" sys="$2"
  python3 - "$why" "$sys" <<'PYEOF'
import json,sys
print(json.dumps({"decision":"block","reason":sys.argv[1],"systemMessage":sys.argv[2]}))
PYEOF
  exit 2
}

case "$TOOL" in
  Write|Edit|MultiEdit|NotebookEdit)
    block "🧊 FREEZE MODE — read-only. ${TOOL} blocked.

Freeze mode is on (~/.claude/state/freeze.flag): investigate without mutating. No files are written while frozen.
Disable to edit: rm ~/.claude/state/freeze.flag" \
      "[freeze-gate] read-only — ${TOOL} blocked (rm the freeze flag to edit)"
    ;;
  Bash)
    CMD=$(printf '%s' "$INPUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());print((d.get('tool_input',{}) or {}).get('command',''))" 2>/dev/null || echo "")
    [ -z "$CMD" ] && exit 0
    echo "$CMD" | grep -qE '#[[:space:]]*freeze:[[:space:]]*ignore' && exit 0
    MUT='(^|[;&|[:space:]])(rm|mv|cp|mkdir|rmdir|touch|tee|install|ln)[[:space:]]|[^>]>[^>]|>>|sed[[:space:]]+-i|\bdd[[:space:]]+if=|git[[:space:]]+(commit|push|reset|checkout|merge|rebase|rm|clean|stash[[:space:]]+drop|tag[[:space:]]+-d)|\b(truncate|chmod|chown)[[:space:]]'
    echo "$CMD" | grep -qE "$MUT" || exit 0
    block "🧊 FREEZE MODE — mutating Bash blocked.

Command (truncated):
    ${CMD:0:200}

\`freeze\` mode is on (read-only). This command writes/mutates. Either:
  1. It's truly read-only and mis-flagged → append '# freeze: ignore', OR
  2. Disable freeze: rm ~/.claude/state/freeze.flag" \
      "[freeze-gate] read-only — mutating Bash blocked (rm the freeze flag)"
    ;;
  *) exit 0 ;;
esac
exit 0
