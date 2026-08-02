#!/bin/sh
# turiya-companion-kit installer
# Copies (not symlinks) skills/core/* into ~/.claude/skills/.
# Refuses to overwrite an existing skill directory of the same name.
# Usage: ./install.sh [--advanced]

set -eu

KIT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC_DIR="$KIT_DIR/skills/core"
DEST_DIR="$HOME/.claude/skills"

if [ "${1:-}" = "--advanced" ]; then
    echo "--advanced: coming soon (advanced kit not yet published)."
    exit 0
fi

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
echo "Done: $installed installed, $skipped skipped."
echo "Start a new Claude Code session to pick up the skills."
