#!/bin/sh
# turiya-companion-kit installer
#
# Skills (default):  copies skills/core/* into ~/.claude/skills/
# Hooks (--hooks):   copies hooks/* into ~/.claude/hooks/ and PRINTS the
#                    settings.json wiring for you to paste. It never edits
#                    settings.json — a hook that installs itself into your
#                    config without asking is exactly the thing these hooks
#                    exist to prevent.
#
# Neither mode ever overwrites a file that already exists.
#
# Usage:
#   ./install.sh              # skills only
#   ./install.sh --hooks      # skills + hooks
#   ./install.sh --hooks-only # hooks only
#   ./install.sh --help

set -eu

KIT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC_DIR="$KIT_DIR/skills/core"
HOOK_SRC="$KIT_DIR/hooks"
DEST_DIR="$HOME/.claude/skills"
HOOK_DEST="$HOME/.claude/hooks"

DO_SKILLS=1
DO_HOOKS=0

for arg in "$@"; do
    case "$arg" in
        --hooks)      DO_HOOKS=1 ;;
        --hooks-only) DO_HOOKS=1; DO_SKILLS=0 ;;
        --help|-h)
            sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *)
            echo "error: unknown option '$arg' (try --help)" >&2
            exit 1 ;;
    esac
done

# ── skills ────────────────────────────────────────────────────────────────
if [ "$DO_SKILLS" -eq 1 ]; then
    if [ ! -d "$SRC_DIR" ]; then
        echo "error: $SRC_DIR not found. Run from the cloned repo." >&2
        exit 1
    fi

    mkdir -p "$DEST_DIR"
    installed=0
    skipped=0

    for skill_path in "$SRC_DIR"/*/; do
        [ -d "$skill_path" ] || continue
        name=$(basename "$skill_path")
        target="$DEST_DIR/$name"
        if [ -e "$target" ]; then
            echo "SKIP  $name — $target already exists (delete it first to take the kit's version)"
            skipped=$((skipped + 1))
        else
            cp -R "$skill_path" "$target"
            echo "OK    $name -> $target"
            installed=$((installed + 1))
        fi
    done

    echo ""
    echo "Skills: $installed installed, $skipped skipped."
fi

# ── hooks ─────────────────────────────────────────────────────────────────
if [ "$DO_HOOKS" -eq 1 ]; then
    if [ ! -d "$HOOK_SRC" ]; then
        echo "error: $HOOK_SRC not found." >&2
        exit 1
    fi

    mkdir -p "$HOOK_DEST"
    h_installed=0
    h_skipped=0

    for hook_path in "$HOOK_SRC"/*.sh; do
        [ -f "$hook_path" ] || continue
        name=$(basename "$hook_path")
        target="$HOOK_DEST/$name"
        if [ -e "$target" ]; then
            echo "SKIP  $name — $target already exists"
            h_skipped=$((h_skipped + 1))
        else
            cp "$hook_path" "$target"
            chmod +x "$target"
            echo "OK    $name -> $target"
            h_installed=$((h_installed + 1))
        fi
    done

    echo ""
    echo "Hooks: $h_installed installed, $h_skipped skipped."
    echo ""
    echo "The files are in place but INERT until you wire them. Paste this into"
    echo "the \"hooks\" object of ~/.claude/settings.json (merge, don't replace):"
    cat <<'JSON'

  "PreToolUse": [
    { "matcher": "Bash",
      "hooks": [ { "type": "command", "command": "bash ~/.claude/hooks/careful-gate.sh" } ] },
    { "matcher": "Write|Edit|MultiEdit|NotebookEdit|Bash",
      "hooks": [ { "type": "command", "command": "bash ~/.claude/hooks/freeze-gate.sh" } ] },
    { "matcher": "Write|Edit",
      "hooks": [ { "type": "command", "command": "bash ~/.claude/hooks/dep-gate.sh" },
                 { "type": "command", "command": "bash ~/.claude/hooks/config-protection.sh" } ] }
  ],
  "PostToolUse": [
    { "matcher": "*",
      "hooks": [ { "type": "command", "command": "bash ~/.claude/hooks/breadcrumb.sh" } ] }
  ],
  "Stop": [
    { "matcher": "",
      "hooks": [ { "type": "command", "command": "bash ~/.claude/hooks/claim-vgate.sh" } ] }
  ]

JSON
    echo "careful-gate and freeze-gate stay invisible until you turn them on:"
    echo "    touch ~/.claude/state/careful.flag     # pause irreversible ops"
    echo "    touch ~/.claude/state/freeze.flag      # hard read-only"
    echo "    rm    ~/.claude/state/<name>.flag      # off again"
fi

echo ""
echo "Start a new Claude Code session to pick up the changes."
