// plan_step_routing_test.dart — verifies the plan step's modelSelector
// actually wires the categorize output to the τ matrix.
//
// Two paths:
//   well-formed atomic-explore categorize → haiku
//   missing / empty categorize             → fallback sonnet

import 'package:claudart/pipeline/agent_model.dart';
import 'package:claudart/pipeline/agents/categorization.dart';
import 'package:claudart/pipeline/flows/flow_steps.dart';
import 'package:claudart/pipeline/pipeline_context.dart';
import 'package:test/test.dart';

const _projectRoot = '/tmp/test-project';
const _bug = 'a real task';
const _expected = 'should work';

PipelineContext _baseCtx() => const PipelineContext(
      projectRoot: _projectRoot,
      bug: _bug,
      expected: _expected,
      files: [],
    );

PipelineContext _ctxWithCategorize(String categorizeOutput) =>
    _baseCtx().withSlot(PipelineSlot.categorize, categorizeOutput);

String _categorize({
  required AgentCategory category,
  required IntentClass intent,
  required ComplexityTier complexity,
}) =>
    '<${CategorizeTag.category.wireTag}>${category.name}</${CategorizeTag.category.wireTag}>\n'
    '<${CategorizeTag.intent.wireTag}>${intent.name}</${CategorizeTag.intent.wireTag}>\n'
    '<${CategorizeTag.complexity.wireTag}>${complexity.name}</${CategorizeTag.complexity.wireTag}>\n';

void main() {
  test('plan step routes atomic-explore to haiku (the cost win)', () {
    final ctx = _ctxWithCategorize(_categorize(
      category: AgentCategory.feature,
      intent: IntentClass.explore,
      complexity: ComplexityTier.atomic,
    ));
    expect(FlowSteps.plan.effectiveModel(ctx), equals(AgentModel.haiku));
  });

  test('plan step routes systemic-explore to opus', () {
    final ctx = _ctxWithCategorize(_categorize(
      category: AgentCategory.research,
      intent: IntentClass.explore,
      complexity: ComplexityTier.systemic,
    ));
    expect(FlowSteps.plan.effectiveModel(ctx), equals(AgentModel.opus));
  });

  test('plan step degrades to sonnet when categorize slot is empty', () {
    expect(FlowSteps.plan.effectiveModel(_baseCtx()),
        equals(AgentModel.sonnet));
  });

  test('plan step degrades to sonnet on malformed categorize output', () {
    final ctx = _ctxWithCategorize('garbage with no xml tags');
    expect(FlowSteps.plan.effectiveModel(ctx), equals(AgentModel.sonnet));
  });
}
