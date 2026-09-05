---
name: icc-pipes
description: >-
  Create, list, and remove named pipes between Claude instances in one
  container. Transport only. A pipe is an even number of lanes, each a FIFO
  going one way, held open so nothing blocks on open. What goes through it,
  and what it means, is the caller's business.
---

# icc-pipes

A pipe is a fresh directory holding N lanes, N even, each lane a FIFO
going one way, all kept open by one background process:

    /tmp/icc-pipes-XXXXXXXX/0
    /tmp/icc-pipes-XXXXXXXX/1
    ...
    /tmp/icc-pipes-XXXXXXXX/N-1

One side writes the even lanes and reads the odd ones. The other side
writes the odd lanes and reads the even ones. Lanes 0 and 1 are a pair,
2 and 3 are a pair, and so on; every pair is the same link over again.
Which side you are, and what any pair is for, is agreed outside this
skill, like which end of a cable you are holding. Whoever ran create
laid the cable; it need not hold either end.

## Operations

    scripts/create [N]     make a fresh pipe of N lanes (default 2), hold
                           every lane open, print its directory
    scripts/list           one line per pipe: DIR up|down
    scripts/remove DIR     drop the hold, delete the pipe

To attach, open the path. There is nothing else to do.

## Bytes on, bytes off

A lane is a file. Write it with >. Read it with <, bounded.

    printf '%s' "$bytes" > "$d/0"
    timeout 1 cat "$d/1"

## Facts about the pipe

These are properties of a FIFO. The skill adds nothing to them. Where
Linux and POSIX differ, both are given; this skill is Linux.

- A write of at most PIPE_BUF bytes lands whole. Larger writes can
  interleave with another writer's. PIPE_BUF is 4096 on Linux; POSIX
  promises only 512. `getconf PIPE_BUF /tmp` says.
- Each lane buffers 64K on Linux; POSIX promises only PIPE_BUF. A write
  past the buffer blocks until someone reads. Lanes fill and drain
  independently, so N lanes is N times the bytes in flight. More lanes
  is more bandwidth, nothing else.
- A read on an empty lane blocks, and never sees EOF while the pipe is
  up, because the hold keeps a writer open. Bound every read (timeout,
  nonblocking) or the call hangs.
- Bytes read are gone. Nothing is kept.
- Order holds within one lane and nowhere else.
- The hold opens every lane O_RDWR. On Linux that open never blocks.
  POSIX leaves it undefined.
- The holder is `sleep infinity`. The pipe's path is in its open file
  descriptors, not its argv, so `pkill -f` on the path finds nothing
  but the shell that expanded it. Find a holder under /proc/PID/fd,
  as list does.
- If the hold dies (list says down), opens and writes can block.
  remove it and create it again.

## In Claude Code

Every Bash call is a fresh shell. The hold is its own process, so the
pipe outlives calls. A foreground read that does not return hangs the
tool call until the harness times it out.

Seats in one session share the container, so they share
/tmp. Sessions do not share a container; no pipe crosses
that line.
