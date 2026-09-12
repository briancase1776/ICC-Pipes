#!/bin/bash
# tests/run.sh
# Prove the pipe: create it, push bytes down every lane, see them arrive,
# remove it.
# Copyright (c) 2026 Brian Case. All rights reserved.
# AI contributor: Claude (Anthropic)
#
# MIT License text omitted for brevity, See LICENCE.TXT
set -eu
cd "$(dirname "$0")/../.claude/skills/icc-pipes"
! scripts/create 3 2>/dev/null
d=$(scripts/create 4)
trap 'scripts/remove "$d" 2>/dev/null || :' EXIT
scripts/list | grep -qx "$d up"
for l in 0 1 2 3; do printf '%s\n' "lane $l" > "$d/$l"; done
for l in 0 1 2 3; do [ "$(timeout 1 cat "$d/$l")" = "lane $l" ]; done
scripts/remove "$d"
[ ! -d "$d" ]
trap - EXIT
echo ok
