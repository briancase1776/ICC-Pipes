#!/bin/sh
# Prove the pipe: create it, push bytes each way, see them arrive, remove it.
set -eu
cd "$(dirname "$0")/.."
n=test-$$
trap 'scripts/remove "$n" 2>/dev/null || :' EXIT
d=$(scripts/create "$n")
scripts/list | grep -qx "$n up"
printf 'one\n' > "$d/0"
printf 'two\n' > "$d/1"
[ "$(timeout 1 cat "$d/1")" = two ]
[ "$(timeout 1 cat "$d/0")" = one ]
scripts/remove "$n"
[ ! -d "$d" ]
trap - EXIT
echo ok
