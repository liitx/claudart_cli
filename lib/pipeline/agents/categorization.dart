// categorization.dart — typed taxonomy for agent task classification
//
// Three orthogonal axes form a Cartesian product:
//
//   T = AgentCategory × IntentClass × ComplexityTier
//     = 5 × 4 × 3 = 60 cells
//
// Model routing function:
//   τ : T → AgentModel  (total — exhaustive switch, Gap = ∅ by construction)
//
// Adding a new variant to any axis without updating τ is a compile error.
//
// Invariants (set-theoretic, from WorkStatus / BranchType pattern):
//   AgentCategory.feature.intents ∩ {IntentClass.document} = ∅
//   AgentCategory.research.intents ∩ {IntentClass.implement} = ∅
//   ComplexityTier.atomic ∩ ComplexityTier.systemic = ∅  (disjoint tiers)

import '../agent_model.dart';
import '../xml_tags.dart';

/// XML tag names emitted by the categorize step. Exposed so the route
/// resolver, the planner log, and any future consumer reference a
/// single source for the wire-format.
const String kCategorizeCategoryTag   = 'CATEGORY';
const String kCategorizeIntentTag     = 'INTENT';
const String kCategorizeComplexityTag = 'COMPLEXITY';

// ── Axes ──────────────────────────────────────────────────────────────────────

/// What kind of work is being requested.
///
/// Invariant: active ∪ terminal = AgentCategory.values  (no uncategorised work)
enum AgentCategory {
  feature,   // new capability addition
  bug,       // defect investigation / repair
  refactor,  // structural improvement without behaviour change
  research,  // knowledge extraction / reference lookup
  setup,     // workspace or environment configuration
  gui;       // visual surface — widgets, painters, theme tokens

  /// Intent classes valid for this category.
  ///
  /// Invariant: feature.intents ∩ {IntentClass.document} = ∅
  /// Invariant: research.intents ∩ {IntentClass.implement} = ∅
  /// Invariant: gui.intents ⊆ {analyze, implement, design}
  Set<IntentClass> get intents => switch (this) {
        feature  => {IntentClass.explore, IntentClass.analyze, IntentClass.implement},
        bug      => {IntentClass.explore, IntentClass.analyze},
        refactor => {IntentClass.analyze, IntentClass.implement},
        research => {IntentClass.explore, IntentClass.document},
        setup    => {IntentClass.implement, IntentClass.document},
        gui      => {IntentClass.analyze, IntentClass.implement, IntentClass.design},
      };
}

/// What the agent is primarily doing within the task.
///
/// Partition: explore ∪ analyze ∪ implement ∪ document = IntentClass.values
enum IntentClass {
  explore,    // broad codebase or knowledge discovery
  analyze,    // reasoning over known, bounded context
  implement,  // code generation or modification
  document,   // structured output — reference, glossary, report
  design;     // visual surface review / spec generation
}

/// How broadly the task affects the codebase.
///
/// Partition: atomic ∪ compound ∪ systemic = ComplexityTier.values
/// Invariant: atomic ∩ systemic = ∅  (no task is both isolated and cross-cutting)
enum ComplexityTier {
  atomic,    // isolated — single file, clear scope, no cross-cutting concerns
  compound,  // multi-file — known dependencies, bounded blast radius
  systemic;  // cross-cutting — architectural impact, affects multiple subsystems
}

// ── Routing function ──────────────────────────────────────────────────────────

/// τ : AgentCategory × IntentClass × ComplexityTier → AgentModel
///
/// Total function — exhaustive switch over all 60 cells.
/// Three-layer rationale:
///   Theory:  opus excels at broad discovery; sonnet at reasoning + generation;
///            haiku at fast structured lookup.
///   Rule:    systemic × {explore,analyze} → opus;
///            * × {analyze,implement} → sonnet (unless systemic);
///            * × {explore,document} on atomic/compound → haiku.
///   Example: "explain how this codebase handles state" =
///            research × explore × systemic → opus.
AgentModel routeModel(
  AgentCategory category,
  IntentClass intent,
  ComplexityTier complexity,
) =>
    switch ((category, intent, complexity)) {
      // Systemic exploration or analysis always warrants maximum capability.
      (_, IntentClass.explore,   ComplexityTier.systemic)  => AgentModel.opus,
      (_, IntentClass.analyze,   ComplexityTier.systemic)  => AgentModel.opus,

      // Any analysis or implementation at compound/atomic tier → balanced.
      (_, IntentClass.analyze,   _)                         => AgentModel.sonnet,
      (_, IntentClass.implement, _)                         => AgentModel.sonnet,

      // Compound exploration still benefits from balanced reasoning.
      (_, IntentClass.explore,   ComplexityTier.compound)  => AgentModel.sonnet,

      // Atomic exploration and all documentation → fast lookup tier.
      (_, IntentClass.explore,   _)                         => AgentModel.haiku,
      (_, IntentClass.document,  _)                         => AgentModel.haiku,

      // Visual design — balanced reasoning for spec generation at any tier.
      (_, IntentClass.design,    _)                         => AgentModel.sonnet,
    };

/// Resolves an [AgentModel] from a categorize step's raw XML output by
/// extracting the three classification tags and consulting [routeModel].
/// Returns [fallback] when any tag is missing or maps to an unknown
/// enum variant — degrading gracefully per the reasoner's constraint
/// ("misrouting complex tasks to haiku is worse than full sonnet").
///
/// Wired into [AgentStep.modelSelector] for the plan step so the
/// categorize step's three-axis classification actually drives the
/// downstream model choice instead of being recorded and ignored.
AgentModel modelForCategorizeOutput(
  String rawOutput, {
  required AgentModel fallback,
}) {
  if (rawOutput.isEmpty) return fallback;
  final category =
      _enumByName(AgentCategory.values, tagOrNull(rawOutput, kCategorizeCategoryTag));
  final intent =
      _enumByName(IntentClass.values, tagOrNull(rawOutput, kCategorizeIntentTag));
  final complexity = _enumByName(
      ComplexityTier.values, tagOrNull(rawOutput, kCategorizeComplexityTag));
  if (category == null || intent == null || complexity == null) {
    return fallback;
  }
  return routeModel(category, intent, complexity);
}

/// Case-insensitive lookup by [Enum.name]. The LLM may capitalize
/// (`'Sonnet'` vs `'sonnet'`) so we normalize before matching.
T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  final lower = name.toLowerCase();
  for (final value in values) {
    if (value.name.toLowerCase() == lower) return value;
  }
  return null;
}
