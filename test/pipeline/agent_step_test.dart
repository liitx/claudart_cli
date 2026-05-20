// agent_step_test.dart — AgentStep.effectiveModel contract.
//
// Three rows:
//   - no selector → falls back to `model`
//   - selector returns AgentModel → that wins
//   - selector returns null → falls back to `model`
//
// Pure unit tests — no pipeline executor, no LLM.

import 'package:claudart/pipeline/agent_model.dart';
import 'package:claudart/pipeline/agent_step.dart';
import 'package:claudart/pipeline/pipeline_context.dart';
import 'package:test/test.dart';

const _projectRoot = '/tmp/test-project';

PipelineContext _ctx() => const PipelineContext(
      projectRoot: _projectRoot,
      bug: '',
      expected: '',
      files: [],
    );

void main() {
  group('AgentStep.effectiveModel', () {
    test('no selector → returns the static `model`', () {
      final step = AgentStep(
        id: 'a',
        label: 'Step A',
        model: AgentModel.haiku,
        systemPrompt: 'sys',
        buildPrompt: (_) => 'msg',
      );
      expect(step.effectiveModel(_ctx()), equals(AgentModel.haiku));
    });

    test('selector returns a model → that model wins over `model`', () {
      final step = AgentStep(
        id: 'a',
        label: 'Step A',
        model: AgentModel.sonnet,
        modelSelector: (_) => AgentModel.haiku,
        systemPrompt: 'sys',
        buildPrompt: (_) => 'msg',
      );
      expect(step.effectiveModel(_ctx()), equals(AgentModel.haiku));
    });

    test('selector returns null → falls back to `model`', () {
      final step = AgentStep(
        id: 'a',
        label: 'Step A',
        model: AgentModel.sonnet,
        modelSelector: (_) => null,
        systemPrompt: 'sys',
        buildPrompt: (_) => 'msg',
      );
      expect(step.effectiveModel(_ctx()), equals(AgentModel.sonnet));
    });

    test('selector receives the ctx passed to effectiveModel', () {
      PipelineContext? captured;
      final step = AgentStep(
        id: 'a',
        label: 'Step A',
        model: AgentModel.sonnet,
        modelSelector: (ctx) {
          captured = ctx;
          return null;
        },
        systemPrompt: 'sys',
        buildPrompt: (_) => 'msg',
      );
      final ctx = _ctx();
      step.effectiveModel(ctx);
      expect(identical(captured, ctx), isTrue);
    });
  });
}
