#!/usr/bin/env bash
# breadcrumb.sh — PostToolUse hook: append 1-line per-turn breadcrumb.
#
# WHY: Stop hooks only fire on GRACEFUL session end. A crash/kill/OOM
# dies mid-turn -> Stop never runs -> "what was I doing" is lost. This writes
# DURING the turn (after each tool call), so the last line is always the last
# thing done, even after a hard crash. No LLM, no git, fail-open, bounded.
#
# OUTPUT: ~/.claude/state/breadcrumbs/<session_id>.log  (one line per tool call)
#   FORMAT: ISO8601 | tool_name | target
# READ IT: tail ~/.claude/state/breadcrumbs/<session_id>.log
#
# DISABLE: touch ~/.claude/state/breadcrumbs/.off

set -uo pipefail

DIR="$HOME/.claude/state/breadcrumbs"
[[ -f "$DIR/.off" ]] && exit 0
mkdir -p "$DIR" 2>/dev/null || exit 0

INPUT="$(cat 2>/dev/null)" || exit 0
[[ -z "$INPUT" ]] && exit 0

INPUT="$INPUT" DIR="$DIR" python3 - <<'PY' 2>/dev/null || exit 0
import json, os, datetime

d = json.loads(os.environ.get("INPUT", "{}"))
sid = (d.get("session_id") or "unknown").replace("/", "_")[:64]
tool = d.get("tool_name") or "?"
ti = d.get("tool_input") or {}

# Best-effort single target per tool type — no LLM, just field-pick.
target = ""
if isinstance(ti, dict):
    if "command" in ti:            # Bash
        target = str(ti["command"])[:160]
    elif "file_path" in ti:        # Read/Write/Edit
        target = str(ti["file_path"])
    elif "path" in ti:
        target = str(ti["path"])
    elif "pattern" in ti:          # Grep/Glob
        target = str(ti["pattern"])[:120]
    elif "query" in ti:            # search tools
        target = str(ti["query"])[:120]
    elif "prompt" in ti:           # Agent/Task
        target = str(ti["prompt"])[:120]
    elif "url" in ti:
        target = str(ti["url"])
target = target.replace("\n", " ").replace("\r", " ").strip()

ts = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
line = f"{ts} | {tool} | {target}\n"

log = os.path.join(os.environ["DIR"], f"claude-{sid}.log")
with open(log, "a") as f:
    f.write(line)

# Ring-buffer cap: keep last 500 lines (crash-proof, bounded ~50KB).
try:
    with open(log) as f:
        lines = f.readlines()
    if len(lines) > 500:
        with open(log, "w") as f:
            f.writelines(lines[-500:])
except Exception:
    pass
PY

exit 0
