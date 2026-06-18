# claudart — Agent Response & Output Layer

> Design entry. Source of truth for how claudart structures agent output and renders it
> consistently across CLI, TUI, and every future surface. Pairs with `PLAN.md` (vision)
> and `docs/design.md` (FSA).

## Problem

claudart's output is wordy and unstructured. For multi-workspace, multi-subagent work the
risks are: walls of text, missed questions, redundant subagent work, and no live view of
where work stopped. This layer fixes all four by making every emission a **typed response**
with a **fixed render position**, driven by code, not by a model.

---

## Two speakers

Every response carries a `Speaker` so the render layer can separate who is talking:

- **claudart** — the foreground voice you chat with. Always responsive, never blocked. Its
  own color and header.
- **Agent** — the background orchestrator running subagents. Its own lane.
- **Subagent** — a worker inside the Agent, labeled by workspace/subtask.

claudart watches the Agent's responses as they arrive and stays **non-blocking**: the
orchestrator runs in the background while claudart stays interactive, relaying Progress and
Questions and routing your answers back in. Background runs stay chattable. You always know
who is talking.

---

## AgentResponse — the sealed taxonomy

Every emission is one variant. The render layer is a single exhaustive switch: variant →
component. Nothing prints in an undefined format.

| Variant | Fields | Primary render |
|---------|--------|----------------|
| **Plan** | goal, subtasks[], ordered by priority | priority list + relationship tree |
| **Progress** | workspace, subtask, AgentFlow state, blocked/unblocked | status table + state icon |
| **Question** | origin, workspace, blockedSubtask, question, options[] | pinned callout |
| **Result** | workspace, subtask, filesTouched[], summary | collapsed card |
| **Blocker** | workspace, step, errorType | red row |
| **Handoff** | from, to, resolvedInfo | dim one-liner |
| **Replan** | reason, oldOrder, newOrder | diff list |

Every variant also carries `speaker`.

### Subtask model

```
Subtask: id, workspace, priority, dependsOn[], state
```

### Invariants

1. **Never-guess.** A subtask with an unresolved question may emit only `Question`, never
   `Result`. An unresolved question cannot become a guessed answer.
2. **Safe replan.** The Plan has a single writer (the Agent). Priority is read only at step
   boundaries (FSA transitions), so a `Replan` never preempts in-flight work or races.
3. **Questions float.** Open `Question` responses aggregate into one pinned panel at the top
   of the session view, regardless of arrival order, grouped by origin.

---

## Output template system

### Canonical slot order

Every response renders its slots in this fixed order. A slot renders only when populated, but
its position never changes, so the eye always finds the same thing in the same place.

1. **Header** — required. Per-type label, icon, color, speaker lane.
2. **Overview** — required. Terse, 1–2 lines. The gist.
3. **Body** — type-specific component (priority list / status table / relationship tree /
   result card / diff).
4. **Implications** — optional list. Downstream effects.
5. **Concerns** — optional list. Risks, caveats.
6. **Questions** — optional. Also mirrored to the pinned session panel.
7. **Call to action** — optional, last. What the user does next.

Read path is always: what is it → gist → detail → so-what → what's blocked → what to do.

### Flavor rules

- Terse default. Overview ≤ 2 lines. Lists, never paragraphs.
- One header style per type. Fixed icon + color, owned by enum getters (no bare strings).
- Bodies render as the type's component, never prose.
- Optional slots omit silently when empty. No placeholder noise.
- Long bodies (Result) collapse by default, expand on demand.

### Per-type slot usage

| Variant | Slots used |
|---------|-----------|
| Plan | Header, Overview, Body(priority list + tree), Concerns, CallToAction |
| Progress | Header, Overview, Body(status table) |
| Question | Header, Overview, Body(question + options), CallToAction |
| Result | Header, Overview, Body(collapsed card), Implications, Concerns |
| Blocker | Header, Overview, Body(error row), CallToAction |
| Handoff | Header, Body(one-liner) |
| Replan | Header, Overview, Body(old→new diff), Implications |

### Color & icon

Each variant, each AgentFlow state, and each speaker carries an icon and color via an enum
getter, reusing the state-hue pattern from zedup. The render layer never hardcodes a glyph or
color.

---

## Token reuse — prompt caching

Both the claudart main loop and every subagent cache aggressively so context is paid for once.

- Mark shared context (system prompt, scope files, anything already rendered) with
  `cache_control: {type: "ephemeral"}`. Reads of that prefix cost ~0.1×, up to ~90% off.
- Caching is a prefix match. Stable content first, volatile last. Audit the prefix for
  silent invalidators (timestamps, UUIDs, unsorted JSON, a varying tool set).
- A subagent must reuse the parent's **exact** prefix (same system, tools, model) or it
  misses the cache. Keep model and tools fixed mid-run.
- Keep the main loop on one model. Spawn subagents on a cheaper model for subtasks (the
  Claude Code Explore-on-Haiku pattern). This is the lever against redundant token spend:
  cache the shared scope once, every subagent reads it cheap, none re-renders it.

---

## Render reach

The render layer is the single owner of all of the above. CLI and TUI both render through it;
no other code prints agent output. "Concise and consistent everywhere" is enforced in one
place, not per call site.

---

## Concurrency (next)

Subagents emit `AgentResponse` events as they happen. claudart and the dashboard both watch
these responses as they arrive and re-render on each one. A `Question` blocks only its own
dependency subtree, so other workspaces keep running while one waits. This requires moving the
executor from sequential to concurrent subagent execution whose responses claudart watches
together — speced separately.

## Build order

1. `AgentResponse` sealed taxonomy + `Speaker` + subtask model
2. Render layer (slots, flavor, per-type mapping, speaker lanes)
3. Live responses claudart watches without blocking
4. Concurrent subagent execution
5. Dashboard subscriber

Step 2 alone, even sequential, ends the wall-of-text problem.
