# claudart — Session Log

> Running record of design decisions, cleanups, and known issues.
> Updated manually at the end of each significant work session.

---

## 2026-03-17 — Framework-agnostic cleanup + line editor + teardown improvements

### What claudart is

A generic Dart CLI that manages a structured suggest → debug → teardown workflow
for AI-assisted debugging sessions. It is not Flutter-specific. It runs on any
Dart project.

The workflow:

```
claudart link          — register project in workspace registry
claudart setup         — describe the bug; writes handoff.md
  ↓
/suggest               — AI explores the codebase, writes root cause to handoff
claudart save          — checkpoint confirmed root cause to skills.md (Pending)
  ↓
/debug                 — AI implements the fix, scoped to handoff
  ↓
claudart teardown      — classify session, archive handoff, update skills.md, suggest commit
```

### Commands (as of this session)

| Command               | What it does |
|-----------------------|--------------|
| `claudart`            | Interactive launcher — list projects, route into setup |
| `claudart init`       | Scaffold workspace: dart.md, testing.md, slash commands |
| `claudart init -p X`  | Add project knowledge file |
| `claudart link [name]`| Register project; write CLAUDE.md with workspace refs |
| `claudart unlink`     | Remove symlinks |
| `claudart setup`      | Prompt for bug context; write handoff.md |
| `claudart status`     | Show active session state; `--prompt` for shell RPROMPT |
| `claudart save`       | Snapshot handoff to archive/checkpoint_*; deposit root cause to skills.md Pending |
| `claudart teardown`   | Categorise session; archive handoff; update skills.md; suggest commit |
| `claudart kill`       | Abandon session without skills update |
| `claudart preflight`  | Sync check before debug/save/test |
| `claudart scan`       | Re-scan project for sensitive tokens |
| `claudart report`     | Diagnostic report |
| `claudart map`        | Generate token_map.md from token_map.json |
| `claudart experiment` | Run command and tee output to experiments/ |

### Files written by the workflow

```
~/.claudart/                        ← CLAUDART_WORKSPACE (global root, v2)
  registry.json                     ← maps project roots to workspace paths
  <project-name>/
    handoff.md                      ← live session state (suggest ↔ debug)
    skills.md                       ← accumulated cross-session learnings
    archive/
      checkpoint_<branch>_<ts>.md  ← save snapshots
      handoff_<branch>_<ts>.md     ← teardown archives
    knowledge/
      generic/
        dart.md                     ← generic Dart practices
        testing.md                  ← generic testing practices
      projects/
        <name>.md                   ← project-specific context
    commands/                       ← Claude Code slash commands
      suggest.md
      debug.md
      save.md
      teardown.md
    logs/
    token_map.json / token_map.md
```

### What was cleaned up this session

**Flutter/BLoC context removed from the generic CLI:**

Previously, claudart had hardcoded Flutter-specific assumptions throughout:
- `handoff_template.dart` had a `### BLoCs / providers in play` section
- `setup.dart` stored the answer in a `blocs` variable
- `teardown.dart` had Flutter-specific categories: `bloc-event-handling`,
  `widget-lifecycle`, `provider-state`, `ffi-bridge`
- `teardown_utils.dart` mapped categories to commit areas using BLoC/widget/ffi terms
- `suggest_template.dart` and `debug_template.dart` told the AI to read `bloc.md`
  and `riverpod.md` and traced `API → repository → BLoC/provider → widget`
- `knowledge_templates.dart` contained `blocTemplate` and `riverpodTemplate`
- `init.dart` wrote `bloc.md` and `riverpod.md` to the workspace on init

**Root cause:** These were dc-flutter-specific assumptions carried over from the
original dc-flutter workflow and never genericised.

**What replaced them:**
- Handoff section: `### Key entry points in play`
- Setup variable: `entryPoints`
- Teardown categories: `api-integration`, `concurrency`, `configuration`,
  `data-parsing`, `io-filesystem`, `state-management`, `general`, `other`
- `TeardownCategory` constants: `apiIntegration`, `concurrency`, `configuration`,
  `dataParsing`, `ioFilesystem`, `stateManagement`, `general`, `other`
- `areaFromCategory()`: maps to `api`, `async`, `config`, `io`, `state`, `data`, `fix`
- Knowledge starters: `dart.md` + `testing.md` only (no framework assumptions)
- Templates: generic data flow language; no framework-specific file references

**Note:** The scanner (`lib/scanner/`) and sensitivity modules (`lib/sensitivity/`)
still detect BLoC/Riverpod patterns — this is correct. Those modules scan
*target* project code, not claudart itself.

### Other improvements this session

- **Line editor** (`lib/ui/line_editor.dart`): raw-mode mini readline for all
  text prompts — left/right arrows, home/end, backspace, delete, Ctrl+A/E/U
- **Teardown pre-population**: hot files pre-filled from "What changed"; root
  cause pattern pre-filled from handoff Root Cause section
- **Arrow-key category menu**: teardown category selection uses `arrowMenu`
  instead of free-text entry
- **`TeardownCategory` named constants**: replaces magic indices in tests
- **Legacy path migration** (scan + logger): `scan.dart` and `logger.dart` now
  resolve paths per-project via `workspacePath` instead of the global `claudeDir`
- **21 unit tests** for teardown + **3 e2e smoke tests** (save → teardown pipeline)

### Known issues / open questions

1. **`setup` has no unit tests** — highest-priority coverage gap. Setup is the
   most complex command (prompts, handoff write, scan, logging) and has zero test
   coverage. Drift is likely here.

2. **`init` still detects Flutter version** — removed from template generation but
   `_detectVersion('flutter', ...)` call can be removed entirely since `claudeMdTemplate`
   accepts `flutterConstraint` as an optional param (used when target project is Flutter).

3. **skills.md Pending section** — the current `skills.md` in the self-hosted
   workspace has a malformed Pending entry (from a prior session where the category
   leaked). Review and clean manually if needed.

4. **`claudart scan` standalone** — resolves workspace from registry correctly now
   but has no dedicated test for the standalone binary path.

5. **Category selection is fixed-length** — if a user wants a project-specific
   category not in the list, they must pick `other (type manually)`. A future
   improvement: derive additional options from existing skills.md Root Cause Patterns.

### Test coverage summary

| Area                        | Tests |
|-----------------------------|-------|
| Registry                    | ✓     |
| HandoffTemplate             | ✓     |
| KnowledgeTemplates          | ✓     |
| TeardownUtils               | ✓     |
| SessionState                | ✓     |
| SyncCheck                   | ✓     |
| WorkspaceGuard              | ✓     |
| Link                        | ✓ 16  |
| Save                        | ✓     |
| Teardown                    | ✓ 21  |
| Kill                        | ✓     |
| Status                      | ✓     |
| Launch                      | ✓     |
| Preflight                   | ✓     |
| Scan                        | ✓     |
| E2E (save → teardown)       | ✓ 3   |
| **Setup**                   | ✗ 0   |
| README sync                 | ✓     |
| Total                       | 375   |

### Commit at end of session

```
ebcf12f fix: remove Flutter/BLoC context — claudart is framework-agnostic
```
