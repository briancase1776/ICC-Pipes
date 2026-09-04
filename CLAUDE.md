# ICC-Pipes

A Claude Code skill that creates pipes between Claude instances. That is the
whole project.

## What this is

- A **pipe**: a named, bidirectional channel one Claude can open and another
  Claude can attach to.
- The skill covers creating, listing, attaching to, and removing pipes.
  Nothing else.

## What this is not

Out of scope. Do not build, stub, or "leave room for" any of these:

- Message formats, protocols, schemas, or envelopes for what goes through a pipe.
- How a Claude decides what to write or how it interprets what it reads.
- Routing, brokers, discovery services, registries, or hubs.
- Persistence, replay, history, or logging of pipe contents.
- Auth, encryption, permissions, or multi-user anything.
- Retries, backpressure, queues, or delivery guarantees beyond what the
  underlying OS primitive already gives.
- Config files, plugins, or extension points.

If a request touches any of the above, stop and say it is out of scope. Do
not add it.

## Testing

A test harness is allowed **only to prove the pipe works**: open it, attach to
it, push bytes one way, see them arrive the other way, close it. The harness
must not grow into a client, protocol, or example app. If a test needs more
than a few lines of setup, the pipe is too complicated, not the test.

## Rules

- **KISS.** One way to do each thing. Prefer the OS primitive over a library.
  Prefer a shell script over a program. Prefer no dependency over one.
- **Small.** If a file is getting long, you are adding scope, not features.
- **No speculative work.** Build what is asked, not what might be asked later.
- **No abstraction until there are two real callers.**
- Before adding anything, ask: is this the pipe, or something that uses the
  pipe? Only the pipe belongs here.

## Layout

```
SKILL.md      the skill definition Claude Code loads
scripts/      the pipe operations, one small script each
tests/        the minimal harness described above
```

Do not add directories without a reason that fits the scope above.
