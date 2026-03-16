# claudart

A Dart CLI that gives your AI coding sessions **memory, structure, and privacy**.

> Not a Claude product. Works with any editor that supports slash commands.

---

## The short version

You're debugging a tricky bug. You open Claude Code, type `/suggest`, and it already knows your project's patterns, past mistakes, and what files to avoid. When it finds the fix, `/debug` picks up exactly where `/suggest` left off. When you're done, `claudart teardown` files the learnings so next time is smarter.

**That's claudart** — a local CLI that coordinates a structured, stateful AI workflow across sessions.

```
claudart setup   →   /suggest   →   /debug   →   claudart teardown
```

No cloud sync. No API keys. Everything lives in a local workspace on your machine.

---

## Table of contents

- [Quick start](#quick-start)
- [How it works — the simple version](#how-it-works--the-simple-version)
- [Commands at a glance](#commands-at-a-glance)
- [Privacy & sensitivity protection](#privacy--sensitivity-protection)
- [The continuous improvement loop](#the-continuous-improvement-loop)
- [Detailed docs](#detailed-docs)

---

## Quick start

```bash
# 1. Clone and compile
git clone https://github.com/liitx/claudart ~/dev/claudart
cd ~/dev/claudart
dart compile exe bin/claudart.dart -o ~/bin/claudart

# 2. Add ~/bin to PATH (if not already)
echo 'export PATH=$HOME/bin:$PATH' >> ~/.zshrc

# 3. Point claudart at a workspace folder
echo 'export CLAUDART_WORKSPACE=~/dev/my-workspace' >> ~/.zshrc
source ~/.zshrc

# 4. Initialize workspace
claudart init
claudart init --project my-app

# 5. Start a session
cd ~/dev/my-app
claudart link
claudart setup
# → then type /suggest inside Claude Code
```

**Recompile after updates:**
```bash
dart compile exe ~/dev/claudart/bin/claudart.dart -o ~/bin/claudart
```

---

## How it works — the simple version

### The workspace

Think of the workspace as a **shared brain** — a folder on your machine that multiple projects can reference. It holds everything Claude needs to be useful: past learnings, project patterns, session state.

```
~/my-workspace/
  knowledge/          ← what Claude reads before every session
  handoff.md          ← the current bug being worked on
  skills.md           ← what worked (and didn't) in past sessions
  archive/            ← every past session, for reference
```

It never lives inside a project. Projects just borrow it.

### A session, step by step

```
1. claudart setup
   You describe the bug. claudart writes a structured handoff.md.

2. /suggest  (inside Claude Code)
   Claude reads your knowledge base + handoff.
   Explores the codebase. Builds a theory.
   Writes its findings back to handoff.md.

3. /debug  (inside Claude Code)
   Claude reads the updated handoff.
   Implements a scoped fix.
   Only touches what it said it would touch.

4. claudart teardown
   You confirm the fix. Describe what changed.
   claudart extracts the learnings and adds them to skills.md.
   Archives the full session. Resets handoff for next time.
   Suggests a commit message.
```

Every session makes the next one smarter.

### The handoff status machine

The session has a status that both `/suggest` and `/debug` respect:

| Status | Meaning |
|---|---|
| `suggest-investigating` | `/suggest` is exploring |
| `ready-for-debug` | `/suggest` is confident — `/debug` can start |
| `debug-in-progress` | `/debug` is implementing |
| `needs-suggest` | `/debug` hit a wall — hand back to `/suggest` |

`/debug` refuses to start unless status is `ready-for-debug`. No guessing, no drift.

---

## Commands at a glance

| Command | What it does |
|---|---|
| `claudart` | Interactive launcher — lists projects, routes you in |
| `claudart init` | One-time workspace setup |
| `claudart init --project name` | Register a new project |
| `claudart link` | Wire workspace into current project via symlinks |
| `claudart setup` | Start a session — writes handoff.md |
| `claudart status` | Show current session state |
| `claudart teardown` | End session — update knowledge, archive, suggest commit |
| `claudart unlink` | Remove workspace symlinks from project |
| `claudart scan` | Re-scan project for sensitive tokens |
| `claudart map` | Generate a human-readable token map |
| `claudart report` | Show diagnostic summary |
| `claudart report --file-issue` | File issues to GitHub automatically |

---

## Privacy & sensitivity protection

When you're working on a proprietary codebase, you might not want class names, function signatures, or module structure going to Anthropic's servers verbatim.

**claudart has an opt-in sensitivity mode.**

When enabled during `claudart link`, it:

1. Scans your project's Dart files for sensitive identifiers (class names, BLoC types, repository names, typedefs, etc.)
2. Assigns them stable abstract tokens: `AudioBloc` → `Bloc:A`, `VehicleRepository` → `Repository:A`
3. Builds a **persistent local token map** that grows across sessions
4. Replaces sensitive identifiers in `handoff.md` *before* Claude reads it

Claude sees the full picture — BLoC types, relationships, dependency graphs — just never the real names.

```
Your code                    What Claude sees
─────────────────────        ────────────────────────────────────
AudioBloc                →   Bloc:A
AudioState               →   BlocState:A
AudioRepository          →   Repository:A
fetchTrack(String id)    →   [Method:A]([Param:A])
```

The token map lives locally. It never leaves your machine. Anthropic builds understanding of `Bloc:A` across sessions without ever learning it's called `AudioBloc`.

**To enable:**
```
claudart link
→ Enable sensitivity protection? y
→ Scan scope: lib/ only (recommended)
→ Scan trigger: On setup (when files changed)
→ Share anonymous diagnostic logs? y/n
```

**Your local reference key** — `claudart map` generates a human-readable table so you can always cross-reference abstract tokens back to real names:

```markdown
## Blocs
| Token      | Event        | State        | Dependencies |
|------------|--------------|--------------|--------------|
| Bloc:A     | BlocEvent:A  | BlocState:A  | Repository:A |

## Repositories
| Token        | Returns  | Async |
|--------------|----------|-------|
| Repository:A | Model:A  | yes   |
```

---

## The continuous improvement loop

```
Session ends
    ↓
claudart teardown extracts learnings
    ↓                    ↓
Generic patterns    Project patterns
(all projects)      (this project only)
    ↓
Next session: agents start with richer context automatically
```

`skills.md` accumulates hot paths (files that keep showing up), root cause patterns, anti-patterns (files that looked relevant but weren't), and a full session index. Over time, `/suggest` stops re-exploring dead ends it already visited.

---

## Detailed docs

<details>
<summary><strong>Workspace structure — everything that lives on disk</strong></summary>

```
$CLAUDART_WORKSPACE/
  knowledge/
    generic/
      dart_flutter.md     ← generic Dart/Flutter best practices (version-tagged)
      bloc.md             ← BLoC patterns accumulated from real sessions
      riverpod.md         ← Riverpod patterns
      testing.md          ← testing patterns
    projects/
      my-app.md           ← project-specific context and accumulated patterns
  handoff.md              ← current session state (reset each teardown)
  skills.md               ← cross-session index: hot paths, root causes, anti-patterns
  archive/                ← every past session, timestamped
  token_map.json          ← [sensitivity mode] persistent abstract token map
  config.json             ← per-workspace config (sensitivity mode, scan scope, etc.)
  logs/
    interactions.jsonl    ← per-command structured log (capped at 500 entries)
    errors.jsonl          ← error log with deduplication by fingerprint
    performance.md        ← scan timing and token counts
  .claude/
    commands/
      suggest.md          ← /suggest slash command definition
      debug.md            ← /debug slash command definition
      teardown.md         ← /teardown slash command definition
  CLAUDE.md               ← aggregator: tells Claude which knowledge files to load
```

The workspace is never inside a project. Projects symlink to it at session time and unlink after.

</details>

<details>
<summary><strong>claudart link — how SDK constraints are scoped per project</strong></summary>

`claudart link` does more than create symlinks. It reads the project's `pubspec.yaml`, extracts the `environment.sdk` and `flutter` constraints, and embeds them into the generated `CLAUDE.md`:

```markdown
## Environment

- Dart SDK: `^3.8.0`
- Flutter: `3.32.5`

Do not suggest APIs or syntax unavailable within these constraints.
```

This means the Dart analyzer and Claude Code both know exactly what SDK version to target for *this* project — not whatever is globally installed. Different projects can have different constraints and the workspace handles each correctly.

</details>

<details>
<summary><strong>Sensitivity mode — how the token map works under the hood</strong></summary>

**Detection: TF-IDF + regex**

claudart uses two layers to decide what's sensitive:

1. **Regex heuristics** — `PascalCase` (class names), `camelCase` compound words (method names), `snake_case.dart` filenames. Anything matching these patterns is a candidate.
2. **TF-IDF rarity scoring** — claudart ships with a bundled frequency map of ~100 common Dart/Flutter terms (`String`, `BuildContext`, `BlocBuilder`, etc.). These score low (common = safe). Project-specific identifiers don't appear in the corpus, so they score high (rare = sensitive).

Anything flagged as sensitive and not in the safe list gets a stable abstract token.

**The token map is relational**

Tokens preserve semantic relationships, not just names:

```json
{
  "Bloc:A": { "r": "AudioBloc", "e": "BlocEvent:A", "s": "BlocState:A", "deps": ["Repository:A"] },
  "BlocState:A": { "r": "AudioState", "b": "Bloc:A" },
  "Extension:A": { "r": "AudioBlocX", "on": "Bloc:A" }
}
```

Claude sees `Extension:A on Bloc:A` and knows it's an extension on that specific BLoC. It can reason about the architecture without knowing the domain.

**Append-only, never reassigned**

Once `AudioBloc` → `Bloc:A`, that mapping is permanent. If the class is renamed, the old token gets a `renamedTo` field. If deleted, `deprecated: true`. The token is never reused for a different class. This means Anthropic's understanding of `Bloc:A` accumulates correctly across every session.

**The API boundary is enforced**

```
Raw Dart identifiers (your machine only)
  ↓  static analysis + token map
  ↓  abstracted content
─────────────────────────── ← Anthropic API boundary
  ↓  Claude Code reads abstracted handoff.md
```

If `isNotSensitive()` returns false after abstraction, claudart warns you before writing.

</details>

<details>
<summary><strong>Static analysis scanner — how entity detection works</strong></summary>

The scanner uses regex-based pattern matching (no full AST parser — kept light for performance).

**What gets detected:**

| Pattern | Entity type | Token prefix |
|---|---|---|
| `class X extends Bloc<E, S>` | BLoC | `Bloc:` |
| `class X extends Cubit<S>` | Cubit | `Cubit:` |
| `class XState` / `sealed class XState` | BLoC state | `BlocState:` |
| `class XEvent` / `sealed class XEvent` | BLoC event | `BlocEvent:` |
| `class XRepository` | Repository | `Repository:` |
| `class X extends StatelessWidget` | Widget | `Widget:` |
| `extension X on Y` | Extension | `Extension:` |
| `typedef X = ...` | Callback/typedef | `Callback:` |
| `final xProvider = Provider(...)` | Riverpod provider | `Provider:` |
| `enum X { }` | Enum | `Enum:` |
| `mixin X` | Mixin | `Mixin:` |
| `class X` (unmatched) | Generic class | `Class:` |

**Threshold protection**

Default threshold: 300 files. If exceeded:

```
⚠ Large scan detected
  └── 847 Dart files found in project root
  └── Estimated scan time: ~45s

This may be slow. Suggestions:
  1. Narrow scope to lib/ only    → claudart link --scope lib
  2. Add *.g.dart to .claudartignore
  3. Run: claudart scan --scope lib

? Switch to lib/ scope now and continue? (Y/n)
```

**`.claudartignore`**

Place at your project root. Default patterns applied if file is missing:

```
**/*.g.dart
**/*.freezed.dart
**/*.mocks.dart
build/
.dart_tool/
```

**Incremental rescans**

The scanner checks file mtimes against `lastScan` in `config.json`. Only modified files are reprocessed. Full rescan: `claudart scan --full`.

</details>

<details>
<summary><strong>Logging & diagnostics — what gets captured and why</strong></summary>

**Three log files, all capped:**

| File | Cap | Content |
|---|---|---|
| `logs/interactions.jsonl` | 500 entries | One JSON line per command run |
| `logs/errors.jsonl` | 200 entries | Errors with deduplication by fingerprint |
| `logs/performance.md` | 50 entries | Scan timing table |

Rotation is silent. When a file exceeds its cap, oldest entries are dropped. A `logs/summary.json` preserves aggregate counts so the signal is never fully lost.

**Error deduplication**

Every error gets a fingerprint: `"$command.$errorType.$reason"`. If the same error occurs again, it increments a `count` field on the existing entry instead of creating a new one. This means `errors.jsonl` stays small and meaningful even over many sessions.

**Sensitivity in logs**

If sensitivity mode is on, the token map is applied to stack traces before they're written to disk. Real identifiers never appear in log files.

**`claudart report --file-issue`**

Reads `errors.jsonl`, checks each entry's fingerprint against existing GitHub issues on `liitx/claudart`, and either:
- Files a new issue (labels: `claudart-generated`, error type) if none exists
- Comments on the existing issue with updated frequency if `count` crossed a threshold

Uses the system `gh` CLI. Falls back to PAT prompt if `gh` is not configured.

</details>

<details>
<summary><strong>Cosine similarity — how relevant context is selected</strong></summary>

When building the handoff, claudart doesn't dump all of `skills.md` into context. It selects the top-K most relevant chunks using sparse TF-IDF cosine similarity.

**How it works:**

1. Tokenize the session's bug description into a query vector (TF-IDF weighted, using the bundled corpus)
2. Tokenize each section of `skills.md` into chunk vectors (same weighting)
3. Compute sparse dot product between query and each chunk
4. Return the top-3 chunks by cosine score

Sparse vectors only — no full vocabulary materialization. For typical `skills.md` sections, vectors have 20–50 non-zero dimensions instead of 800. Fast and cheap.

This means that after 20 sessions, `/suggest` doesn't get overwhelmed with unrelated history — it gets the 3 most relevant past patterns.

</details>

<details>
<summary><strong>Architecture — how the code is organized</strong></summary>

```
bin/claudart.dart           ← entry point + command dispatch

lib/
  commands/
    init.dart               ← workspace + project initialization
    launch.dart             ← interactive launcher menu
    link.dart               ← pubspec parsing, symlinks, config questions
    unlink.dart             ← safe symlink removal
    setup.dart              ← session start, scan trigger, abstraction, logging
    status.dart             ← display current handoff state
    teardown.dart           ← end session, update knowledge, archive
    scan.dart               ← on-demand project rescan
    report.dart             ← diagnostic bundle + GitHub issue filing
    map_cmd.dart            ← generate token_map.md

  sensitivity/
    detector.dart           ← TF-IDF + regex sensitive token detection
    token_map.dart          ← persistent relational token map (load/save/assign)
    abstractor.dart         ← replace/restore sensitive tokens in text

  scanner/
    scanner.dart            ← Dart static analysis, entity extraction
    scan_threshold_exception.dart

  similarity/
    cosine.dart             ← sparse TF-IDF cosine similarity

  logging/
    logger.dart             ← interactions.jsonl, errors.jsonl, performance.md

  assets/
    corpus.dart             ← bundled IDF weights for ~100 safe Dart/Flutter terms

  config.dart               ← WorkspaceConfig read/write (config.json)
  ignore_rules.dart         ← .claudartignore pattern matching
  file_io.dart              ← abstract FileIO + RealFileIO (testability)
  process_runner.dart       ← abstract ProcessRunner + RealProcessRunner
  md_io.dart                ← markdown section read/write utilities
  handoff_template.dart     ← handoff.md template generator
  knowledge_templates.dart  ← starter knowledge content generators
  pubspec_utils.dart        ← SDK constraint extraction from pubspec.yaml
  teardown_utils.dart       ← pure teardown logic (extracted for testability)
  paths.dart                ← workspace path resolution from env var
```

**Key design patterns:**

- All file I/O goes through the `FileIO` interface — production uses `RealFileIO`, tests use `MemoryFileIO` (in-memory map) or `MockFileIO` (mocktail-based)
- Pure functions are separated from side effects — `teardown_utils.dart`, `knowledge_templates.dart`, `md_io.dart` have no I/O side effects and are trivially testable
- No new runtime dependencies — TF-IDF, cosine similarity, and static analysis are all implemented in pure Dart

**164 tests. Zero warnings on `dart pub publish --dry-run`.**

</details>

---

## License

MIT
