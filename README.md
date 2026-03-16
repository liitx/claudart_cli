# claudart_cli

A generic Dart CLI that manages the suggest/debug agent workflow for Claude Code.

`claudart_cli` is a **package** — it has no opinions about your project structure. You point it at a local workspace directory where your session files live. That workspace is yours to configure per project.

---

## Concept

```
claudart_cli (generic package)
      ↕  reads/writes
$CLAUDART_WORKSPACE/   ← your local workspace (project-specific overrides)
  handoff.md           ← active session state
  skills.md            ← accumulated learnings
  archive/             ← past sessions
```

Your workspace is where the local, project-specific md files live — handoff, skills, any overrides. The CLI doesn't care what project you're in; it just manages those files.

---

## Dependency chain

```
ivi (global command)
  └── activated from <path-to-claudart_cli>
        └── reads/writes $CLAUDART_WORKSPACE/
```

`ivi` works because of two things. If either is missing it will break:

1. **Global activation** — `claudart_cli` must be activated via `dart pub global activate`
2. **`CLAUDART_WORKSPACE`** — must be set in your shell profile pointing to your workspace directory

---

## Install

Requires Dart SDK `^3.0.0`.

```bash
git clone https://github.com/liitx/claudart_cli <your-local-path>
cd <your-local-path>
dart pub get
dart pub global activate --source path <your-local-path>
```

---

## Configure your workspace

Set `CLAUDART_WORKSPACE` to wherever your local session files should live.
Defaults to `~/.claudart/` if not set.

```bash
# In your ~/.zshrc or ~/.bashrc
export CLAUDART_WORKSPACE=~/your/workspace/path
```

The workspace directory and its subdirectories are created automatically on first use.

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

Writes a structured `handoff.md` to your workspace, ready for `/suggest` or `/debug`.

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
<your-local-path>/          ← the package (generic, no project paths)
  bin/ivi.dart              ← CLI entry point
  lib/
    commands/
      setup.dart
      status.dart
      teardown.dart
    handoff_template.dart
    md_io.dart
    paths.dart              ← resolves workspace from CLAUDART_WORKSPACE

$CLAUDART_WORKSPACE/        ← your local workspace
  handoff.md                ← active session state (suggest ↔ debug bridge)
  skills.md                 ← accumulated learnings across sessions
  archive/                  ← past handoffs (auto-created, keep gitignored)
```

---

## Claude Code integration

The Claude commands (`/suggest`, `/debug`, `/teardown`) live in your project repo under `.claude/commands/`. They read from `$CLAUDART_WORKSPACE/handoff.md` and `skills.md` at the start of every session.

> **Important:** `.claude/` and `CLAUDE.md` are local Claude Code config — never commit them to your project repo. Add them to your project's `.gitignore`.

A global `/ivi` fallback command can be placed at `~/.claude/commands/ivi.md` for use if the CLI hasn't been run yet in a session.

### Workflow in practice

```bash
# 1. Start session from your project root
cd <your-project>
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

1. Clone `claudart_cli` and activate it globally
2. Set `CLAUDART_WORKSPACE` in your shell profile for that project's session files
3. Add `.claude/commands/suggest.md`, `debug.md`, `teardown.md` to the project, pointing to `$CLAUDART_WORKSPACE`
4. Add `.claude/` and `CLAUDE.md` to the project's `.gitignore`
5. Run `ivi setup` from the project root

---

## License

MIT
