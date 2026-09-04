#!/bin/sh
# Prove the pipe: create it, push bytes each way, see them arrive, remove it.
set -eu
cd "$(dirname "$0")/../.claude/skills/icc-pipes"
d=$(scripts/create)
trap 'scripts/remove "$d" 2>/dev/null || :' EXIT
scripts/list | grep -qx "$d up"
printf 'one\n' > "$d/0"
printf 'two\n' > "$d/1"
[ "$(timeout 1 cat "$d/1")" = two ]
[ "$(timeout 1 cat "$d/0")" = one ]
scripts/remove "$d"
[ ! -d "$d" ]
trap - EXIT
echo ok
