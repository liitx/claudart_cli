// agent_step.dart — a single step in an agent pipeline
//
// An AgentStep is a self-contained unit of work:
//   - which model to call (or how to pick one from context)
//   - what system prompt to use
//   - how to build the message from current context
//   - which XML tag in the output triggers which route
//
// Model selection:
//   - `model` is the fallback when no [modelSelector] is provided, or
//     when the selector returns null.
//   - [modelSelector] is the dynamic hook — the executor calls it once
//     per step with the current [PipelineContext] so the categorize
//     step's classification can drive downstream model choice. See
//     `agents/categorization.dart` for [modelForCategorizeOutput],
//     the canonical selector used by the plan step.
//
// Routing:
//   routes is empty  → no branching; executor proceeds to next step in list
//   routes non-empty → executor parses output for first matching tag, routes accordingly
//
// All prompt building is deferred to buildPrompt(ctx) so steps are pure
// data — no I/O at declaration time. Tests can inject any PipelineContext.

import 'agent_model.dart';
import 'pipeline_context.dart';
import 'step_route.dart';

/// Resolves a step's model from the current [PipelineContext]. Return
/// `null` to fall through to [AgentStep.model]. Pure — no IO.
typedef ModelSelector = AgentModel? Function(PipelineContext ctx);

class AgentStep {
  final String id;
  final String label;

  /// Fallback model used when [modelSelector] is unset or returns null.
  /// Steps that don't need dynamic routing leave [modelSelector] null
  /// and read this directly.
  final AgentModel model;

  final String systemPrompt;
  final String Function(PipelineContext ctx) buildPrompt;

  /// Dynamic model resolver. Lets downstream steps pick a model based
  /// on what an earlier step produced (e.g. plan step reads the
  /// categorize step's `<COMPLEXITY>` tag to route atomic tasks to
  /// haiku). Null means "use [model] always."
  final ModelSelector? modelSelector;

  /// Tag-to-route map. The executor finds the first tag present in the step's
  /// output and follows its route. Order matters: entries are checked in
  /// insertion order (Dart Map preserves insertion order).
  final Map<String, StepRoute> routes;

  const AgentStep({
    required this.id,
    required this.label,
    required this.model,
    required this.systemPrompt,
    required this.buildPrompt,
    this.modelSelector,
    this.routes = const {},
  });

  /// Resolves the model the executor should invoke for this step given
  /// [ctx]. Honors [modelSelector] when present; falls through to
  /// [model] when the selector is unset or returns null.
  AgentModel effectiveModel(PipelineContext ctx) =>
      modelSelector?.call(ctx) ?? model;
}
