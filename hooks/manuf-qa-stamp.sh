#!/usr/bin/env bash
# manuf-qa-stamp.sh — write or check the QA grade stamp for a spec pack.
#
# WHAT IT IS FOR
#   The two QA skills grade a pack in prose. Prose cannot open or close a gate,
#   so each QA run ends by writing a small JSON stamp; the manufacture workflow
#   (and you, before a merge) read the stamp, not the chat. No stamp, no pass.
#
#     /manuf-design-qa  → specs/NNN-feature/.qa/design-qa.json  (plan is complete; assemble may start)
#     /manuf-qa         → specs/NNN-feature/.qa/manuf-qa.json   (build matches plan; may merge)
#
# USAGE
#   manuf-qa-stamp.sh write <design-qa|manuf-qa> <pack> <GRADE> [--env=local|staging|prod] [--notes='...']
#   manuf-qa-stamp.sh check <design-qa|manuf-qa> <pack> --min=<GRADE> [--env=prod]
#   GRADE: F < C < B < A < A+++
#   Exit: 0 pass/written · 1 below floor or missing · 2 usage error
set -uo pipefail

usage() { sed -n '14,18p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
rank() { case "$1" in F) echo 0;; C) echo 1;; B) echo 2;; A) echo 3;; 'A+++') echo 4;; *) echo -1;; esac; }

[ $# -ge 3 ] || usage
cmd=$1 kind=$2 pack=$3; shift 3
case "$kind" in design-qa|manuf-qa) ;; *) usage;; esac
stamp="$pack/.qa/$kind.json"

env=local notes='' min='' grade=''
if [ "$cmd" = write ]; then grade=${1:-}; shift || true; fi
for a in "$@"; do
  case "$a" in
    --env=*)   env=${a#--env=} ;;
    --notes=*) notes=${a#--notes=} ;;
    --min=*)   min=${a#--min=} ;;
    *) usage ;;
  esac
done

case "$cmd" in
  write)
    [ "$(rank "$grade")" -ge 0 ] || { echo "bad grade '$grade' (F|C|B|A|A+++)" >&2; exit 2; }
    [ -d "$pack" ] || { echo "pack not found: $pack" >&2; exit 2; }
    mkdir -p "$pack/.qa"
    python3 - "$stamp" "$kind" "$grade" "$env" "$notes" <<'PY'
import json, sys, datetime
p, kind, grade, env, notes = sys.argv[1:]
json.dump({"kind": kind, "grade": grade, "env": env, "notes": notes,
           "at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")},
          open(p, "w"), indent=2)
PY
    echo "STAMPED $stamp grade=$grade env=$env"
    ;;
  check)
    [ -n "$min" ] && [ "$(rank "$min")" -ge 0 ] || usage
    [ -f "$stamp" ] || { echo "FAIL: no stamp at $stamp — run /$( [ "$kind" = design-qa ] && echo manuf-design-qa || echo manuf-qa ) first"; exit 1; }
    read -r got genv < <(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["grade"], d["env"])' "$stamp") \
      || { echo "FAIL: unreadable stamp $stamp"; exit 1; }
    if [ "$(rank "$got")" -lt "$(rank "$min")" ]; then
      echo "FAIL: $kind grade $got < $min"; exit 1
    fi
    if [ "$env" = prod ] && [ "$genv" != prod ]; then
      echo "FAIL: stamp is env=$genv, prod needs a stamp written with --env=prod"; exit 1
    fi
    echo "PASS: $kind grade $got >= $min (env=$genv)"
    ;;
  *) usage ;;
esac
