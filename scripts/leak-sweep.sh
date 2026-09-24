#!/usr/bin/env bash
# leak-sweep.sh — the one list of things this public kit must never ship.
#
#   scripts/leak-sweep.sh [paths...]   scan for private/rig references (default: whole kit)
#   scripts/leak-sweep.sh --refs       every kit path a skill/hook/workflow names must exist
#   scripts/leak-sweep.sh --counts     README counts must equal the filesystem
#   scripts/leak-sweep.sh --explained  every shipped component is named in README
#
# Exit 0 clean, 1 on any hit. Scans real files only (the kit is vendored
# with cp -RL; a symlink here is itself a failure — grep skips them).
set -uo pipefail
KIT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$KIT"

# Author credit is allowed in these files only.
CREDIT_OK='^(README\.md|LICENSE|ATTRIBUTIONS\.md)$'

# Case-insensitive, extended regex. One line per class so a hit names its class.
PATTERNS=(
  'author-name|mohan|narayanaswamy|natarajan'
  'email|[a-z0-9._%+-]+@(gmail|orangehealth|anthropic)\.[a-z.]+'
  'home-path|/Users/|/home/[a-z]'
  'employer|orange ?health|orangehealth|\bOH\b|\bVoC\b|emedic|gurukul|phlebo|kamakshi|people desk|voc[- ]?(waves|control|dashboard)'
  'design-kit-id|8afb6df4|7cbced05'
  'rig-path|~/\.agents|\.agents/|golden-rules|EVIDENCE-DOCTRINE|communication-doctrine|RIGOR-ALGORITHM|discovery-cascade'
  'rig-service|open ?brain|openbrain|search_chunks|\brtk\b|atuin|statusbar|kimi|\bglm\b|grok|deepseek|brain-delegate'
  'secret|(sk-ant-|sk-[A-Za-z0-9]{20}|ghp_[A-Za-z0-9]{20}|AKIA[0-9A-Z]{16}|xox[baprs]-)'
)

scan() {
  local hits=0 f cls re rel
  while IFS= read -r f; do
    rel=${f#./}
    if [ -L "$f" ]; then echo "SYMLINK  $rel"; hits=1; continue; fi
    for p in "${PATTERNS[@]}"; do
      cls=${p%%|*}; re=${p#*|}
      if [ "$cls" = author-name ] && [[ $rel =~ $CREDIT_OK ]]; then continue; fi
      # The public GitHub handle in repo URLs is fine; the name elsewhere is not.
      if out=$(sed 's/mohan-n-swamy//g' "$f" | grep -n -i -E "$re" 2>/dev/null); then
        while IFS= read -r l; do echo "$cls  $rel:$l"; done <<<"$out" | head -5
        hits=1
      fi
    done
  done < <(find "${@:-.}" \( -path ./.git -o -path '*/scripts/leak-sweep.sh' -o -name .rigor.md \) -prune -o \( -type f -o -type l \) -print)
  return $hits
}

refs() {
  # Paths of the form skills/<x>, hooks/<x>.sh, workflows/<x>.js mentioned in shipped text must exist.
  local miss=0 ref
  while IFS= read -r ref; do
    [ -e "$ref" ] || [ -e "skills/core/${ref#skills/}" ] || { echo "MISSING  $ref"; miss=1; }
  done < <(grep -rhoE '\b(hooks/[A-Za-z0-9_./-]+\.sh|workflows/[A-Za-z0-9_./-]+\.(js|mjs))\b' \
             skills hooks workflows install.sh README.md 2>/dev/null | sort -u)
  return $miss
}

counts() {
  local s h w bad=0
  s=$(find skills/core -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  h=$(find hooks -maxdepth 1 -name '*.sh' -type f | wc -l | tr -d ' ')
  w=$(find workflows -maxdepth 1 -name '*.js' -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "filesystem: skills=$s hooks=$h workflows=$w"
  grep -q "$s skills" README.md || { echo "README does not state '$s skills'"; bad=1; }
  grep -q "$h hooks" README.md  || { echo "README does not state '$h hooks'"; bad=1; }
  return $bad
}

explained() {
  # Every shipped skill, hook and workflow must be named in README, so a stranger can find what it is for.
  local bad=0 n
  for n in $(ls skills/core) $(cd hooks && ls *.sh) $(cd workflows 2>/dev/null && ls *.js); do
    grep -q -- "$n" README.md || { echo "UNEXPLAINED  $n (not named in README)"; bad=1; }
  done
  return $bad
}

case "${1:-}" in
  --refs)   refs ;;
  --explained) explained ;;
  --counts) counts ;;
  *)        scan "$@" ;;
esac
