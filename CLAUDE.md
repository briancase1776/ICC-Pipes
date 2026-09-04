# ICC-Pipes

A Claude Code skill that creates pipes between Claude instances. That is the
whole project.

Think of a cat-5 cable. It carries bytes between two ends and has no idea
what is plugged into either one. This skill is the cable. Nothing more.

## What this is

- A **pipe**: a bidirectional channel at a path. Whoever has the path can
  attach to either end. Whoever created it need not hold an end.
- The skill covers creating, listing, and removing pipes. Attaching is
  opening the path. Nothing else.

## What this is not

Out of scope. Do not build, stub, or "leave room for" any of these:

- Message formats, protocols, schemas, framing, or envelopes for what goes
  through a pipe. Not even a line convention or a timestamp.
- How a Claude decides what to write or how it interprets what it reads.
- Routing, brokers, discovery services, registries, hubs, or topology.
- Persistence, replay, history, ledgers, or logging of pipe contents.
- Liveness, heartbeats, peer-death detection, or EOF markers.
- Auth, encryption, permissions, or multi-user anything.
- Retries, backpressure, queues, or delivery guarantees beyond what the
  underlying OS primitive already gives.
- Other transports (git, maildirs, platform messaging) or bridges to them.
- Config files, plugins, options, or extension points.

If a request touches any of the above, stop and say it is out of scope. Do
not add it. Before adding anything, ask: is this the cable, or something
that plugs into the cable? Only the cable belongs here.

## Testing

A test harness is allowed **only to prove the pipe works**: create it, push
bytes one way, see them arrive the other way, both directions, remove it.
The harness must not grow into a client, protocol, or example app. If a
test needs more than a few lines of setup, the pipe is too complicated,
not the test.

## Rules

- **KISS.** One way to do each thing. Prefer the OS primitive over a library.
  Prefer a shell script over a program. Prefer no dependency over one.
- **Small.** If a file is getting long, you are adding scope, not features.
- **No speculative work.** Build what is asked, not what might be asked later.
- **No abstraction until there are two real callers.**
- **Facts, not recipes.** SKILL.md states what the OS primitive does. It does
  not tell the caller how to read, write, wait, or poll.

## Layout

```
.claude/skills/icc-pipes/SKILL.md     the skill definition Claude Code loads
.claude/skills/icc-pipes/scripts/     create, list, remove. One small script each.
tests/                                the minimal harness described above
```

Do not add directories without a reason that fits the scope above.
