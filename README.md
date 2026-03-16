# claudart_cli

A Dart CLI that bootstraps and manages the suggest/debug agent workflow for Flutter development with Claude Code.

Designed for use with [dc-flutter](https://github.com/liitx) — a Flutter monorepo for automotive IVI/IC — but generic enough to adapt to any project.

---

## What it does

Claude Code works best when the exploration agent and the fix agent are kept separate. This CLI manages the handoff between them via a shared markdown file (`handoff.md`) that acts as the source of truth for each session.

```
ivi setup   →  /suggest (explore, build KT)  →  writes handoff.md
                                                        ↓
ivi teardown  ←  /debug (scoped fix)         ←  reads handoff.md
     ↓
updates skills.md with generic patterns for future sessions
```

The skills file grows smarter over time — hot paths, root cause patterns, and anti-patterns accumulate so each new session starts with better context.

---

## Install

Requires Dart SDK `^3.0.0`.

```bash
git clone https://github.com/liitx/claudart_cli ~/dev/dev_tools/claude
cd ~/dev/dev_tools/claude
dart pub get
dart pub global activate --source path ~/dev/dev_tools/claude
```

---

## Usage

Run from inside your project directory so git branch detection works.

```bash
ivi setup      # start a new session
ivi status     # check current session state
ivi teardown   # close session after bug is resolved
```

### setup

Detects your current git branch, reads accumulated skills, then prompts:

1. What is the bug? (actual behavior)
2. What should be happening? (expected behavior)
3. Any files already in mind? *(optional)*
4. Any BLoC events, provider names, or API calls involved? *(optional)*

Writes a structured `handoff.md` ready for `/suggest` or `/debug`.

### status

Prints current session state — status, bug summary, unresolved question — and tells you which agent to run next.

### teardown

Confirms the bug is resolved, prompts you to categorize the session, then:

- Updates `skills.md` with generic patterns (hot paths, root cause, anti-patterns)
- Archives `handoff.md` to `archive/`
- Resets `handoff.md` to blank template
- Drafts a commit message

---

## File layout

```
~/dev/dev_tools/claude/
  bin/ivi.dart                  ← CLI entry point
  lib/
    commands/setup.dart
    commands/status.dart
    commands/teardown.dart
    handoff_template.dart
    md_io.dart
    paths.dart
  handoff.md                    ← active session state (suggest ↔ debug bridge)
  skills.md                     ← accumulated learnings across sessions
  archive/                      ← past handoffs, one per session (gitignored)
```

---

## Claude Code integration

The Claude commands (`/suggest`, `/debug`, `/teardown`) live in the project repo under `.claude/commands/`. They read `~/dev/dev_tools/claude/handoff.md` and `skills.md` at the start of every session.

The global `/ivi` command lives in `~/.claude/commands/ivi.md` and serves as a fallback if the CLI hasn't been run yet.

### Workflow in practice

```bash
# 1. Start session from your project root
cd ~/dev/apps/dc-flutter
ivi setup

# 2. In Claude Code — explore the problem
/suggest

# 3. Once suggest writes KT to handoff, switch to debug
/debug

# 4. If debug hits a wall, it writes progress back — pick up in suggest
/suggest

# 5. When resolved, tear down
ivi teardown
```

### What the agents enforce

| Agent | Reads | Writes | Guards |
|---|---|---|---|
| `/suggest` | skills.md, handoff.md | handoff.md (KT only when confident) | No code until root cause confirmed |
| `/debug` | skills.md, handoff.md | handoff.md (progress summary) | No scope beyond handoff, no git push |
| `teardown` | handoff.md | skills.md | Generic patterns only, no session noise |

---

## Adapting to other projects

The CLI is project-agnostic. To use it with a different codebase:

1. Update the Claude commands in your project's `.claude/commands/` to reference `~/dev/dev_tools/claude/handoff.md` and `skills.md`
2. Scope the `/suggest` command to your relevant package/directory
3. Run `ivi setup` from your project root as usual

---

## License

MIT
