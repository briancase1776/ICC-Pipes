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
    /tmp/icc-pipes-XXXXXXXX/pid    the hold's process id, not a lane

`pid` is the only thing in there that is not a FIFO. list reads it to say
up or down, and remove reads it to know what to kill, so a glob of the
directory catches it and writing over it breaks both.

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

## Moving bulk with dd

dd reads stdin and writes stdout unless told otherwise, so `if=` and
`of=` are overrides, not requirements:

    printf '%s' "$bytes" | dd of="$d/0" bs=4096
    timeout 1 dd if="$d/1" bs=4096
    dd if="$a/0" of="$b/0" bs=4096

Stdin into a lane, a lane to stdout, and one pipe into another.

Write in blocks that divide the page. A lane fills its 16 pages only if
the write size divides one; anything else strands what is left of each
page, sixteen times over.

- A short write before page-sized ones costs the rest of its page. One
  byte first, then bs=4096, and the lane holds 61441.
- dd's count is not what is in the lane. A write that blocks is never
  counted, so at bs=131072 dd reported 0 bytes with a full 65536 sitting
  in the lane. Read the lane if you want to know what is in it.
- A bounded read keeps everything it got, partial last block included,
  and spends its whole bound, because no lane ever reaches EOF.
- More than a lane holds needs a reader already draining the far end,
  or the writer wedges partway in.
- dd between two pipes carries one block and nothing else, so a chain
  of N pipes holds 16N + (N - 1) pages: 65536, 135168, 204800 and
  274432 for N of 1 to 4, at bs=4096. Each pipe brings its 16 pages,
  and each joint brings the one page that a block has to be.
- cat in that same place carries whatever it happens to hold when the
  chain wedges, measured from 12288 to 65536 over four runs of one
  setup. It moves the bytes correctly and its share cannot be stated,
  so a chain built on cat has no capacity you can name.

## Holding a lane open

A redirect opens the lane, writes, and closes it, once per command. To
write many times without reopening, hold it on a file descriptor:

    exec 3<>"$d/0"
    printf '%s' "$bytes" >&3
    exec 3>&-

`<>` is the open that never blocks, which is why it is the one here.
What holding an fd does and does not do:

- It opens both ways, so you are also a reader of the lane you write.
- Closing it signals nothing. The hold keeps a writer open, so no reader
  sees EOF, and an idiom that waits for one waits forever.
- The fd dies with the shell. In Claude Code that is one Bash call, so
  an fd never spans two of them. The hold is a process for this reason.

## Facts about the pipe

These are properties of a FIFO. The skill adds nothing to them. Where
Linux and POSIX differ, both are given; this skill is Linux.

- A write of at most PIPE_BUF bytes lands whole. Larger writes can
  interleave with another writer's. PIPE_BUF is 4096 on Linux; POSIX
  promises only 512. `getconf PIPE_BUF /tmp` says.
- Each lane is 16 pages on Linux, not a flat 64K; POSIX promises only
  PIPE_BUF. A write past the buffer blocks until someone reads. Lanes
  fill and drain independently, so N lanes is N times the bytes in
  flight. More lanes is more bandwidth, nothing else.
- The 64K is only there for write sizes that divide the page. A write
  that will not fit in what is left of the current page starts a new one
  and strands the rest, once per page, sixteen times over: the lane
  holds 16 x floor(page / size) x size. On a 4096 page, 2048 fills the
  lane and 2049 holds 32784, so one byte of write size blocks the writer
  32752 bytes early. Nothing written is lost, only the room to write it.
  The page is 4096 on x86-64 and larger elsewhere, which is where the
  64K comes from; PIPE_BUF is a separate 4096 that only looks like the
  same number here. `getconf PAGESIZE` and `getconf PIPE_BUF /tmp` say.
- A read on an empty lane blocks, and never sees EOF while the pipe is
  up, because the hold keeps a writer open. Bound every read (timeout,
  nonblocking) or the call hangs.
- A bounded read spends its whole bound. With no EOF the reader is still
  waiting when the bound runs out, so `timeout 1 cat` prints what it got
  and exits 124. That status is the bound, not a failure, and the read
  costs the bound every time.
- Bytes read are gone. Nothing is kept.
- `>` on a lane does not truncate. Bytes leave when someone reads
  them and at no other time.
- Order holds within one lane and nowhere else.
- The hold opens every lane O_RDWR. On Linux that open never blocks.
  POSIX leaves it undefined.
- Because a lane is open both ways, nothing stops a side reading the
  lane it writes. A side that does takes its own bytes off the wire:
  no error here, and nothing at the peer's end to show they were taken.
  Which side writes which lane is agreed outside this skill, and nothing
  here checks it.
- The scripts are bash, not sh. dash cannot redirect a two-digit fd, so
  under sh create holds no lane past 6.
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
