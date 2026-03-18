# Experiment 02 — Reasoning Design Session

**Date:** 2026-03-17
**Branch:** feature/makefile
**Model:** Claude Sonnet 4.6
**Goal:** Design Makefile, analysis_options.yaml, and workspace knowledge files.
**Secondary discovery:** The conditions that produce mathematical, exact reasoning from a model.

---

## What this session produced

- `Makefile` with `build`, `test`, `test-file`, `analyze`, `lint`, `fmt`, `clean`, `rebuild`
- `analysis_options.yaml` — wires `lints` package, strict modes, isolate + enum TODO stubs
- Architecture decisions for claudart state design (see below)
- This log — a reproducibility record for the reasoning mode

---

## The reasoning mode: what it looks like

Responses during this session were:

1. **Table-first** — "when should I use X?" answered as a decision table:
   `input conditions → right choice → reason (complexity + tradeoff)`
2. **Set-theoretic for coverage** — `T (testable behaviors) ⊇ C (covered)`, gap = `T − C`
3. **Type-theoretic for design** — enums are finite sets; operations on them are total functions;
   exhaustive switch = proof that the function is total
4. **Parse-once, pass-immutable** — derived from the constraint that re-parsing the same
   string multiple times is a hidden O(n×k) cost with no benefit
5. **Theory / Rule / Example** — always three layers: why the rule exists, the rule itself,
   a concrete code demonstration

---

## What produced this reasoning mode

This is the part you want to preserve. These are the conditions that unlocked it, in order
of impact:

### 1. The "no bare strings" constraint

> "no bare strings which needs to be a lint rule"

This single constraint forces **type-theoretic thinking**. Once strings are banned as
communication medium between components, everything must be typed. Typed things form sets.
Sets have operations (membership, union, intersection). The math follows automatically.

**What to put in skills.md to reproduce this:**
```
Architectural law: no bare string literals where an enum can own the value.
Strings are untyped sets of characters. Enums are typed, finite, exhaustive.
Every string that appears in a switch, comparison, or Map key is a candidate enum value.
```

### 2. The "theory / rule" distinction

> "I love this theory, rule concept"

Once you name the two layers — the *why* (theory) and the *enforcement* (rule) — every
explanation naturally follows the same structure. The model mirrors the vocabulary you
introduce. Name the layers, and the model uses them consistently.

**What to put in skills.md to reproduce this:**
```
When explaining any design decision, always give three layers:
  - Theory: why this is mathematically or architecturally correct
  - Rule: the enforceable constraint (lint, type, test gate)
  - Example: the concrete Dart code that demonstrates it
```

### 3. Enum-first mandate with exhaustive switch

> "enums with dart allowing functions and getters, switches, logic in the enum"

Exhaustive switch means the compiler proves coverage. Once you're working in a system where
the compiler is a proof-checker, every design decision becomes: "is this provably correct,
or just probably correct?" That's the mathematical frame. The model follows it.

**What to put in skills.md to reproduce this:**
```
Dart Enhanced Enums are sealed classes. Every switch on an enum must be exhaustive.
Missing cases are compile errors, not runtime bugs. Design state machines as enums first.
```

### 4. Self-hosting feedback loop

claudart runs on itself. This means:
- A bad abstraction gets felt immediately when the tool is used for its own debug sessions
- Every architectural decision has a real cost — not hypothetical
- The model internalizes this: "would this hold up under claudart teardown itself?"

**What to put in skills.md to reproduce this:**
```
This tool is self-hosted. Every design decision is tested against claudart's own sessions.
If a rule cannot be enforced by the tool itself, it is not strong enough.
```

### 5. Set notation for coverage

Once `T ⊇ C` was on the table, all coverage gaps became calculable rather than intuitive.
The model mirrors formal notation when you introduce it. Introduce it once, and it propagates.

**What to put in skills.md to reproduce this:**
```
Coverage model: T = set of testable behaviors, C = set of covered behaviors.
Gap = T − C. Every new public function, enum getter, or branch adds an element to T.
A session is not done until the gap is empty.
```

---

## Architectural decisions made this session

### State design for claudart (current)

claudart is a **short-lived CLI** — runs, processes, exits. State is value-oriented.

| State | Right type | Reason |
|---|---|---|
| Registry entries | `HashMap<String, RegistryEntry>` | Lookup-only, no ordering → O(1) |
| Handoff fields | `HandoffState` record, parsed once | Avoid repeated regex across call sites |
| Scan results | `List<(String path, int tokens)>` | Dart 3 records — value types, no boilerplate |
| Lookup tables | `const Set<String>` | O(1) membership, uniqueness enforced |
| Token map | `HashMap<String, int>` | Unordered lookup |
| Hot path counts | `Map<String, int>` | `putIfAbsent` O(1) update |

**Key rule:** parse once at the entry point of each command, pass the parsed record down.
Never re-run a regex on the same source string in the same command invocation.

### `HandoffState` record (planned)

```dart
typedef HandoffState = ({
  String branch,
  String bug,
  String rootCause,
  String debugProgress,
  HandoffStatus status,
});
```

Replaces 6+ scattered calls to `extractBranch()`, `readSection()`, etc. inside commands.

### Isolate policy

- **Async/await**: I/O-bound work (file read/write, network) — stays on main isolate
- **`Isolate.run()`**: CPU-bound work (large corpus scan, similarity scoring)
- **`Isolate.spawn()`**: bidirectional long-lived channels only
- **Current claudart commands**: all I/O-bound → no isolates needed yet

### Lint gap (custom_lint TODO)

`analysis_options.yaml` enforces exhaustive switch and type safety but cannot statically
catch "string literal that should be an enum value." This requires a `custom_lint` rule.
Filed as future work. Documented in `analysis_options.yaml` as a comment.

---

## Personas: two variants, different jobs

claudart workspace files (`skills.md`, `code.md`, `dart.md`, etc.) are **persona
configuration**. What you write there programs the agent's reasoning style for every
session in that project. This is the core pub.dev value proposition: structured workspace
files = reproducible, project-specific AI behavior.

Two distinct personas emerged this session. Both should be documented in the README
as examples of what users can configure.

---

### Persona A — Technical / Mathematical (for `/suggest` and `/debug`)

Use when: exploring architecture, designing types, auditing state, writing code.

Characteristics:
- Table-first: "when to use X" answered as a decision table with complexity column
- Three layers: theory (why) → rule (enforcement) → example (Dart code)
- Set notation for coverage: T ⊇ C, gap = T − C
- Enum-first: every value in a switch or comparison is an enum candidate
- Parse-once: no re-running a regex on the same source in the same command
- Self-hosting test: would this design survive claudart teardown on itself?

**Paste into `code.md` to activate:**
```
Reasoning contract:
- Table-first: any "when to use X" answered as a decision table
- Three layers: theory (why) → rule (enforcement) → example (Dart code)
- Set notation for coverage: T ⊇ C, gap = T − C
- Enum-first: every value in a switch or comparison is an enum candidate
- Parse-once: no re-parsing the same source in the same command invocation
- Self-hosting test: would this design hold under claudart's own teardown?
```

**`/suggest` variant** (exploratory form — does not close the space early):
```
Exploration contract:
- Enumerate candidates as a decision table before committing to one
- Mark unknowns explicitly: "needs verification: ..."
- Write KT as theory → rule → open question, not theory → rule → answer
- Gap = T − C must be stated at the end: what still needs a test or decision
```

**`/debug` variant** (deterministic form — executes the spec from suggest):
```
Implementation contract:
- The handoff is the spec. Do not re-explore what suggest already resolved.
- Every change must be exhaustive: no unhandled enum case, no unguarded branch
- State the proof: "this switch is exhaustive because..."
- Final step: gap T − C = ∅ must be verified by running tests
```

---

### Persona B — Documentation / Navigation (for README and pub.dev docs)

Use when: writing or restructuring documentation, building README, organizing knowledge files.

The mathematical persona struggles with docs because it optimizes for precision, not
locatability. A README reader needs to find things in < 3 seconds, not prove correctness.

Characteristics:
- **Locatability-first**: every section answerable by `Cmd+F` on one keyword
- **Depth limit**: `##` for major concepts, `###` for variants, never deeper than `####`
- **Getting started in ≤ 5 steps** before any architecture appears
- **No "Introduction" heading** — the package description IS the introduction
- **Decision tables for "which file does X"** — navigation tables, not type tables
- **Mermaid for flows** (user journey, command pipeline), tables for "what goes where"
- **Every code block has a language tag** — pub.dev and GitHub both render these
- **pub.dev score awareness**: example/ directory, topics tag, screenshot, changelog link

**Paste into a README-session `code.md` to activate:**
```
Documentation contract:
- Locatability-first: every section findable by Cmd+F on one keyword
- Max heading depth: ### (never ####)
- Getting started appears before architecture, always
- Navigation tables: "if you want to do X, go to Y"
- Mermaid for flows, tables for "what lives where", bullets for lists
- Every code block has a language tag
- No passive voice in headings — use imperative ("Configure your workspace")
```

---

## What the README must say about personas (the pub.dev pitch)

This is the core message for the README "How it works" section:

> Your workspace files are not just documentation — they are the agent's reasoning
> configuration. What you write in `code.md` determines how the agent thinks about
> your codebase. What you write in `dart.md` determines what Dart patterns it reaches
> for. The suggest/debug workflow is only as good as the knowledge you give it.

And a concrete example showing the reasoning contract block, so users understand
they can paste Persona A or Persona B into their own workspace to get reproducible behavior.

---

## What goes into the README from this session

- Architecture diagram: command → state → record → file I/O pipeline
- Enum-first design section with decision table
- State design table (above)
- Reasoning contract as a "how to use claudart effectively" note for the workspace consumer
- Link to this experiment log as the source of truth

---

## Related todos (from project_claudart_todos.md)

- Todo #1: `HandoffState` record + parse-once wiring through commands
- Todo #2 (new): `custom_lint` rule for bare string detection
- Makefile: written ✓
- `analysis_options.yaml`: written ✓
- `code.md`, `dart.md`, `testing.md`: next up
