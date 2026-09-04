---
name: icc-pipes
description: Create, list, and remove named pipes between Claude instances in one container. Transport only. A pipe is two FIFOs, one each way, held open so nothing blocks on open. What goes through it, and what it means, is the caller's business.
---

# icc-pipes

A pipe is a name. Under it, two FIFOs, held open by one background process:

    /tmp/icc-pipes/NAME/0
    /tmp/icc-pipes/NAME/1

One side writes 0 and reads 1. The other side writes 1 and reads 0.
Which side you are is agreed outside this skill, like which end of a
cable you are holding.

## Operations

    scripts/create NAME    make the pipe, hold it open, print its directory
    scripts/list           one line per pipe: NAME up|down
    scripts/remove NAME    drop the hold, delete the pipe

To attach, open the path. There is nothing else to do. A wider link is
another pipe with another name.

## Facts about the pipe

These are properties of a Linux FIFO. The skill adds nothing to them.

- A write of at most 4096 bytes (PIPE_BUF) lands whole. Larger writes
  can interleave with another writer's.
- Each FIFO buffers 64K. A write past that blocks until someone reads.
- A read on an empty FIFO blocks, and never sees EOF while the pipe is
  up, because the hold keeps a writer open. Bound every read (timeout,
  nonblocking) or the call hangs.
- Bytes read are gone. Nothing is kept.
- Order holds within one FIFO and nowhere else.
- If the hold dies (list says down), opens and writes can block.
  remove it and create it again.

## In Claude Code

Every Bash call is a fresh shell. The hold is its own process, so the
pipe outlives calls. A foreground read that does not return hangs the
tool call until the harness times it out.

Seats in one session share the container, so they share
/tmp/icc-pipes. Sessions do not share a container; no pipe crosses
that line.
