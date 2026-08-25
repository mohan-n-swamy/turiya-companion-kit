#!/usr/bin/env bash
# dep-gate.sh — PreToolUse on Edit|Write.
#
# Enforces the expensive rung of the YAGNI ladder:
#   1. YAGNI  2. stdlib  3. native platform  4. already-installed dep
#   5. only then, a new dependency
# Rung 5 is the costliest and least reversible, so it must pass through a
# conscious gate, never an autopilot edit. (See the `steal-ladder` skill for the
# same discipline applied to whole tools.)
#
# Fires ONLY when the target is a dependency manifest AND the edit ADDS a
# dependency line that wasn't there before:
#   package.json (dependencies / devDependencies), requirements.txt, pyproject.toml
#   ([project.dependencies] / poetry deps), Gemfile, go.mod (require), Cargo.toml.
#
# Blocks the write unless a USER message in the session contains `dep-ok`
# (optionally `dep-ok <name>` to scope to one package). You physically cannot
# add a dependency on autopilot — you must consciously confirm rungs 1-4
# (stdlib / native / installed-dep / one-line) didn't already deliver.
#
# Premise: mechanism, not good intentions. The
# ladder prose is honor-system; this hook is the mechanism for its one
# mechanizable rung. Rungs 1-4 stay judgment — a hook cannot grade "is this
# line necessary", and one that claimed to would be a fake gate.
#
# Bypass: any USER message containing the literal `dep-ok` (assistant text never
# scanned). Edits that only remove/reorder deps are allowed (removal = good).
#
# Exit codes: 0 = allow, 2 = block. Fails OPEN on any parse error (never wedge).

set -euo pipefail

INPUT=$(cat)

INPUT="$INPUT" python3 << 'PYEOF'
import json, os, re, sys

data = json.loads(os.environ.get("INPUT", "{}"))
tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {}) or {}
file_path = tool_input.get("file_path", "")
transcript = data.get("transcript_path", "")

if tool_name not in ("Edit", "Write"):
    sys.exit(0)
if not file_path:
    sys.exit(0)

base = os.path.basename(file_path)
MANIFESTS = {
    "package.json", "requirements.txt", "pyproject.toml",
    "Gemfile", "go.mod", "Cargo.toml",
}
if base not in MANIFESTS:
    sys.exit(0)

# ---- bypass scan (user-only) ------------------------------------------------
def user_blob():
    if not transcript or not os.path.isfile(transcript):
        return ""
    try:
        with open(transcript) as f:
            events = [json.loads(ln) for ln in f if ln.strip()]
    except Exception:
        return ""
    parts = []
    for ev in events:
        if ev.get("type") != "user":
            continue
        content = ev.get("message", {}).get("content", [])
        if isinstance(content, str):
            parts.append(content)
        elif isinstance(content, list):
            for b in content:
                if isinstance(b, dict) and b.get("type") == "text":
                    parts.append(b.get("text", ""))
                elif isinstance(b, str):
                    parts.append(b)
    return "\n".join(parts).lower()

blob = user_blob()
if re.search(r"(?m)^\s*(?:[-*]\s*)?dep[-_ ]?ok\b", blob):
    sys.exit(0)

# ---- detect ADDED dependency lines ------------------------------------------
# A "dependency-ish" added line: package-name + version/spec on a manifest line.
# Heuristics per manifest; conservative — when unsure, do NOT block (fail open).

def added_lines():
    """Lines this edit introduces. For Edit: new_string minus old_string.
    For Write: whole content (can't diff vs disk reliably here)."""
    if tool_name == "Edit":
        new = tool_input.get("new_string", "") or ""
        old = tool_input.get("old_string", "") or ""
        old_set = set(l.strip() for l in old.splitlines())
        return [l for l in new.splitlines() if l.strip() and l.strip() not in old_set]
    # Write: scan whole content, but only flag if file did NOT exist before
    # (a fresh manifest with deps) — overwriting an existing manifest is too
    # ambiguous to diff here, so fail open on overwrite.
    abs_path = os.path.realpath(file_path)
    if os.path.exists(abs_path):
        return []  # overwrite of existing manifest -> fail open
    return (tool_input.get("content", "") or "").splitlines()

# Per-manifest "is this line a new dependency declaration" matcher.
def dep_lines(lines):
    hits = []
    for ln in lines:
        s = ln.strip()
        if base == "package.json":
            # "name": "^1.2.3"  inside a deps block (we can't see the block from a
            # single line, so match the shape and exclude obvious non-deps).
            m = re.match(r'^"([\w@./-]+)"\s*:\s*"([^"]*)"\s*,?$', s)
            if m and not m.group(1) in (
                "name", "version", "description", "main", "type", "license",
                "author", "homepage", "private", "module", "types",
            ) and re.search(r'[\d*x~^>=<]|workspace:|file:|git', m.group(2)):
                hits.append(m.group(1))
        elif base == "requirements.txt":
            if re.match(r'^[A-Za-z][\w.\-\[\]]*\s*([=<>!~]=|@|$)', s) and not s.startswith("#"):
                hits.append(s.split()[0])
        elif base == "Gemfile":
            m = re.match(r"^gem\s+['\"]([\w.\-]+)['\"]", s)
            if m:
                hits.append(m.group(1))
        elif base == "go.mod":
            m = re.match(r'^([\w.\-/]+)\s+v\d', s)
            if m and not s.startswith(("module ", "go ", "require (", ")")):
                hits.append(m.group(1))
        elif base in ("pyproject.toml", "Cargo.toml"):
            m = re.match(r'^([\w.\-]+)\s*=\s*[\["{\d\'"]', s)
            if m and m.group(1) not in (
                "name", "version", "description", "authors", "edition",
                "license", "readme", "homepage", "repository", "requires-python",
            ):
                hits.append(m.group(1))
    return hits

try:
    added = dep_lines(added_lines())
except Exception:
    sys.exit(0)  # parse trouble -> fail open

if not added:
    sys.exit(0)

names = ", ".join(sorted(set(added))[:6])
rel = os.path.realpath(file_path).replace(os.environ.get("HOME", ""), "~")
print(json.dumps({
    "decision": "block",
    "reason": (
        f"DEP-GATE BLOCK: adding dependency [{names}] to {base}.\n\n"
        f"Rung 5 of the YAGNI ladder is the costliest, "
        f"least-reversible rung. Confirm rungs 1-4 first:\n"
        f"  1. YAGNI — is the feature even needed?\n"
        f"  2. stdlib — does the language already do it?\n"
        f"  3. native platform — does the runtime/browser/OS/DB already do it?\n"
        f"  4. already-installed dep — is it ALREADY in this manifest?\n"
        f"If 1-4 genuinely don't deliver, reply `dep-ok` (or `dep-ok {names.split(',')[0].strip()}`) "
        f"and re-run. Mark the rung in code: `// floor: added <dep> because <rung 1-4 failed reason>`.\n"
    ),
    "systemMessage": f"[dep-gate] BLOCKED new dependency in {rel} — confirm YAGNI rungs 1-4, reply `dep-ok`",
}))
sys.exit(2)
PYEOF
