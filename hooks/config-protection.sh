#!/usr/bin/env bash
# config-protection.sh — PreToolUse hook on Edit|Write.
#
# Premise: a known agent failure mode is "make the check pass by weakening the
# check" — disable an eslint rule, loosen tsconfig strictness, add an ignore to
# ruff/mypy, drop a stylelint rule — instead of fixing the code. This is the
# inverse of the quality bar. The model can rationalize it ("the rule was too
# strict"); a hook does not.
#
# This hook BLOCKS edits/writes to linter / formatter / typecheck CONFIG files
# and steers toward fixing the code. Tightening a rule is legitimate — so the
# block is soft, with an explicit `config-ok` bypass.
#
# Adapted from the `config-protection` hook in affaan-m/ECC, re-implemented as
# a clean named shell hook (ECC ships it as an inlined node blob; this does not).
#
# Scope is precise — only files that ARE quality gates. Ambiguous shared files
# (pyproject.toml, setup.cfg, package.json) are NOT gated: they carry far more
# than lint config and would false-positive constantly.
#
# Bypass: USER message containing the literal `config-ok` (use when the change
# TIGHTENS a rule, or the config edit is genuinely the right fix).
#
# Hook payload (PreToolUse): { "tool_input": { "file_path": ... }, "transcript_path": ... }
# Exit codes: 0 = allow, 2 = block.

set -euo pipefail

INPUT=$(cat)

INPUT="$INPUT" python3 << 'PYEOF'
import json, os, re, sys

data = json.loads(os.environ.get("INPUT", "{}"))
tool_input = data.get("tool_input", {}) or {}
target = tool_input.get("file_path", "") or ""
transcript = data.get("transcript_path", "")

if not target:
    sys.exit(0)

base = os.path.basename(target).lower()

# Exact filenames that are unambiguously quality-gate configs.
CONFIG_EXACT = {
    "tsconfig.json", "jsconfig.json",
    "biome.json", "biome.jsonc", ".biomerc", ".biomerc.json",
    ".flake8", ".pylintrc", "pylintrc",
    "ruff.toml", ".ruff.toml",
    "mypy.ini", ".mypy.ini",
    ".golangci.yml", ".golangci.yaml", ".golangci.toml",
    "rustfmt.toml", ".rustfmt.toml", "clippy.toml", ".clippy.toml",
    ".editorconfig",
    "tslint.json",
}

# Prefix/regex families (eslint/prettier/stylelint variants).
CONFIG_PATTERNS = [
    r"^\.eslintrc(\..+)?$",          # .eslintrc, .eslintrc.json, .eslintrc.js, ...
    r"^eslint\.config\.(js|cjs|mjs|ts)$",
    r"^\.prettierrc(\..+)?$",
    r"^prettier\.config\.(js|cjs|mjs|ts)$",
    r"^\.stylelintrc(\..+)?$",
    r"^stylelint\.config\.(js|cjs|mjs|ts)$",
    r"^\.eslintignore$",
    r"^\.prettierignore$",
]

is_config = base in CONFIG_EXACT or any(re.match(p, base) for p in CONFIG_PATTERNS)
if not is_config:
    sys.exit(0)

# Bypass token in any user message.
user_text_parts = []
if transcript and os.path.isfile(transcript):
    try:
        with open(transcript) as f:
            for ln in f:
                if not ln.strip():
                    continue
                ev = json.loads(ln)
                if ev.get("type") != "user":
                    continue
                content = (ev.get("message", {}) or {}).get("content", [])
                if isinstance(content, str):
                    user_text_parts.append(content)
                elif isinstance(content, list):
                    for b in content:
                        if isinstance(b, dict) and b.get("type") == "text":
                            user_text_parts.append(b.get("text", ""))
    except Exception:
        pass

user_blob = "\n".join(user_text_parts).lower()
if re.search(r"(?m)^\s*(?:[-*]\s*)?config[-_ ]?ok\b", user_blob) or "config-ok" in user_blob:
    sys.exit(0)

reason = (
    f"CONFIG-PROTECTION BLOCK: edit targets quality-gate config "
    f"'{os.path.basename(target)}'.\n\n"
    f"Editing linter/formatter/typecheck config = 'make check pass by weakening check' "
    f"anti-pattern — disabling a rule instead of fixing flagged code. Lint/type error sent you here → fix CODE.\n\n"
    f"Legit edit (TIGHTENING rule, adding gate, or config genuinely right fix) → reply literal `config-ok` "
    f"+ retry. State in one line WHY config — not code — is correct surface.\n"
)

print(json.dumps({
    "decision": "block",
    "reason": reason,
    "systemMessage": "[config-protection] BLOCKED (quality-gate config edit — fix code or say config-ok)",
}))
sys.exit(2)
PYEOF
