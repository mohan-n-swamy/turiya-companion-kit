#!/usr/bin/env bash
# design-source-gate.sh — PreToolUse hook on Write|Edit.
#
# WHAT IT IS FOR
#   Asked for a screen, a model reaches straight for markup: a plausible
#   dashboard or form in Tailwind that looks fine alone and is generic,
#   templated UI. "Design first, then implement the design" is easy to write in
#   a CLAUDE.md and easy for the model to skip. This hook makes it mechanical:
#   a big block of new UI code cannot be written until a design exists on disk
#   in a design/ folder (exported from a design tool — e.g. claude.ai/design via
#   the auteur CLI, Figma, or hand-drawn and committed). manuf-product-design
#   vendors that folder into every spec pack, so the pipeline passes it free.
#
# WHAT IT BLOCKS
#   Write of a new UI file, or an Edit adding more than THRESHOLD net lines,
#   when the added text actually carries design (JSX/markup/CSS rules) and no
#   design provenance exists for the repo.
#
# WHAT PASSES FREE (deliberately — this must not fire on maintenance)
#   - copy tweaks, prop renames, bugfixes, small edits (<= THRESHOLD net lines)
#   - logic-only files with a UI extension (hooks, utils, types, tests)
#   - anything under design/ , specs/*/design/ (that IS the exported design)
#   - generated / vendored trees (node_modules, dist, build, .next, ...)
#
# HOW IT PASSES LEGITIMATELY
#   A non-empty `design/` directory up-tree from the target file, inside the
#   repo, or in a spec pack at <repo>/specs/*/design/ — the exported design the
#   code implements. A design that only lives in
#   a browser tab is not a design the code can be checked against.
#
# ESCAPE HATCH
#   Put the literal `design-gate: ignore` in the content being written (a
#   comment is fine). Intentionally explicit so the bypass is visible in the
#   transcript rather than silent.
#
# Hook payload (PreToolUse): { "tool_name", "tool_input", "cwd" }
# Exit codes: 0 = allow, 2 = block.

set -euo pipefail

INPUT=$(cat)

INPUT="$INPUT" python3 << 'PYEOF'
import json, os, re, sys

THRESHOLD_LINES   = 15   # net added lines above which an Edit counts as "designing"
NEW_FILE_MIN      = 5    # a new UI file smaller than this is a stub, not a design

data       = json.loads(os.environ.get("INPUT", "{}"))
tool       = data.get("tool_name", "") or ""
tool_input = data.get("tool_input", {}) or {}
target     = tool_input.get("file_path", "") or ""

if not target or tool not in ("Write", "Edit", "MultiEdit"):
    sys.exit(0)

# realpath, not abspath: on macOS /tmp is a symlink to /private/tmp, and the
# repo-root walk must key identically no matter which form the caller passed.
target = os.path.realpath(target)
ext    = os.path.splitext(target)[1].lower()

UI_EXT = {".tsx", ".jsx", ".vue", ".svelte", ".html", ".htm", ".css", ".scss", ".sass", ".less", ".astro"}
if ext not in UI_EXT:
    sys.exit(0)

parts = set(target.split(os.sep))

# --- exemptions: generated trees, vendored code, the design pack itself -------
EXEMPT_DIRS = {
    "node_modules", "dist", "build", ".next", ".nuxt", "out", "vendor",
    "coverage", "__snapshots__", ".venv", "venv", "site-packages",
    "design", "storybook-static", ".storybook", "scratchpad",
}
if parts & EXEMPT_DIRS:
    sys.exit(0)

# Test fixtures and stories are not product design surfaces.
if re.search(r"\.(test|spec|stories)\.[jt]sx?$", os.path.basename(target)):
    sys.exit(0)

# --- what text is being introduced -------------------------------------------
if tool == "Write":
    added   = tool_input.get("content", "") or ""
    existed = os.path.exists(target)
elif tool == "Edit":
    old     = tool_input.get("old_string", "") or ""
    new     = tool_input.get("new_string", "") or ""
    added   = new
    existed = True
    net     = new.count("\n") - old.count("\n")
else:  # MultiEdit
    edits   = tool_input.get("edits", []) or []
    added   = "\n".join((e.get("new_string", "") or "") for e in edits)
    existed = True
    net     = sum((e.get("new_string", "") or "").count("\n") - (e.get("old_string", "") or "").count("\n")
                  for e in edits)

# --- escape hatch -------------------------------------------------------------
if "design-gate: ignore" in added:
    sys.exit(0)

# --- volume test: is this designing, or maintenance? --------------------------
added_lines = added.count("\n") + 1
if tool == "Write":
    if existed:
        # full rewrite of an existing file — same bar as a bulk edit
        if added_lines <= THRESHOLD_LINES:
            sys.exit(0)
    else:
        if added_lines < NEW_FILE_MIN:
            sys.exit(0)
else:
    if net <= THRESHOLD_LINES:
        sys.exit(0)

# --- signal test: does the added text actually carry design? ------------------
def carries_design(text, ext):
    if ext in (".css", ".scss", ".sass", ".less"):
        # a rule block with at least one declaration
        return bool(re.search(r"\{[^}]*:[^}]*\}", text, re.S)) or bool(re.search(r"^\s*[.#@&][\w-]", text, re.M))
    if ext in (".html", ".htm"):
        return bool(re.search(r"<(div|section|main|header|nav|form|table|button|ul|article|body)\b", text, re.I))
    # tsx / jsx / vue / svelte / astro
    if re.search(r"className=|class=|<(div|section|main|header|nav|form|table|button|ul|article)\b", text):
        return True
    if re.search(r"styled\.|css`|tw`|<style\b|@apply\b", text):
        return True
    return False

if not carries_design(added, ext):
    sys.exit(0)

# --- provenance: is there an exported design for this code? -----------------
def repo_root(path):
    d = os.path.dirname(path)
    while d and d != "/":
        if os.path.isdir(os.path.join(d, ".git")):
            return d
        d = os.path.dirname(d)
    return os.path.dirname(path)

root = repo_root(target)

def has_design_pack(path, root):
    """A non-empty design/ dir between the file and the repo root, or in any
    spec pack at <repo>/specs/*/design/ (where manuf-product-design exports it)."""
    d = os.path.dirname(path)
    while True:
        cand = os.path.join(d, "design")
        if os.path.isdir(cand) and os.listdir(cand):
            return cand
        if d == root or d == "/" or not d:
            break
        d = os.path.dirname(d)
    specs = os.path.join(root, "specs")
    if os.path.isdir(specs):
        for name in sorted(os.listdir(specs)):
            cand = os.path.join(specs, name, "design")
            if os.path.isdir(cand) and os.listdir(cand):
                return cand
    return None

if has_design_pack(target, root):
    sys.exit(0)

# --- block --------------------------------------------------------------------
# Failure-receipt shape (code / subject / evidence / supportedFixes) adapted
# from tt-a1i/archify (MIT): the repair contract binds the model to the listed
# fixes instead of improvising.
rel = os.path.relpath(target, root) if target.startswith(root) else target


reason = f"""HARD-GATE TRIPPED: hand-rolled design.

diagnostic:
  code: design-source/no-provenance
  subject: {{file: {rel}, repo: {root}}}
  evidence:
    added: ~{added_lines} lines carrying markup/CSS
    design_pack: none up-tree from file to repo root, none in specs/*/design/

Rule: UI is implemented FROM a design, never invented in the editor.
Writing this file directly skips the design step and produces template UI.

supportedFixes (apply EXACTLY ONE, nothing else):
  1. route-design — produce the design first (claude.ai/design via the auteur
     CLI, Figma, any design tool), export it into a design/ folder next to the
     code (e.g. specs/<feature>/design/), then implement FROM design/,
     faithfully.
  2. mark-not-design — only when this genuinely is not design work (a logic
     file that happens to contain a tag, a throwaway harness, an emergency
     fix): include the literal comment `design-gate: ignore` in the content.
     It shows in the transcript.
  3. report-blocked — if the design tool fails or is unavailable: STOP and
     report. Do not invent a replacement UI; that is the exact failure this
     gate exists to prevent.

REPAIR CONTRACT: choose from supportedFixes only — do not improvise other
repairs (no substitute CSS, no shrinking the edit to duck under the line
threshold). If the gate still blocks after one honest fix, stop and report
this diagnostic verbatim instead of retrying variants."""

print(json.dumps({
    "decision": "block",
    "reason": reason,
    "systemMessage": f"[design-source-gate] BLOCKED {rel} — design it first, vendor it into design/",
}))
sys.exit(2)
PYEOF
