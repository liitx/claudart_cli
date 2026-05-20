// route_tag.dart — closed set of XML tags an AgentStep's output can
// emit to direct the pipeline.
//
// `flow_steps.dart` and `suggest_steps.dart` declare a `routes` map
// keyed by RouteTag.<variant>.wireTag. The executor scans the step's
// output for each declared variant and follows the matching StepRoute.
//
// Variants:
//   plan      — proposal of work to be done; gates on user approval
//   question  — the step needs information it doesn't have
//   answer    — clarifier step resolved the question
//   unknown   — clarifier step couldn't resolve; escalate to user
//   handoff   — terminal handoff document (construct step output)
//   changes   — concrete change plan emitted by the suggest planner
//               step; consumed by the applier
//
// Adding a variant is a compile error in every exhaustive switch that
// reads the enum — intentional. This is the single source of truth for
// the response-tag axis (distinct from `CategorizeTag` which keys the
// input-classification axis).

/// Closed set of route tags. Constructor takes the wire-format string
/// directly so `RouteTag.plan.wireTag` is a const expression usable in
/// const map literals.
enum RouteTag {
  plan('PLAN'),
  question('QUESTION'),
  answer('ANSWER'),
  unknown('UNKNOWN'),
  handoff('HANDOFF'),
  changes('CHANGES');

  const RouteTag(this.wireTag);

  /// Wire-format tag name emitted by the agent step and matched by the
  /// executor's `tagOrNull` call. Const-initialized via the enhanced
  /// enum constructor so route maps stay const.
  final String wireTag;
}
