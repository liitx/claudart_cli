// planner_log_test.dart — PlannerLog emits one JSONL record per decision
// and tallies DesignSurface variants across the input paths.

import 'dart:convert';

import 'package:claudart/logging/planner_log.dart';
import 'package:claudart/pipeline/agent_flow.dart';
import 'package:claudart/pipeline/agent_model.dart';
import 'package:claudart/pipeline/agents/categorization.dart';
import 'package:claudart/pipeline/agents/path_heuristic.dart';
import 'package:test/test.dart';

void main() {
  group('PlannerLog.tallySurfaces is exhaustive over DesignSurface', () {
    final log = PlannerLog(path: '/tmp/ignored', appender: (_, __) {});
    test('every variant key is present even with empty input', () {
      final tally = log.tallySurfaces(const []);
      for (final v in DesignSurface.values) {
        expect(tally.containsKey(v), isTrue, reason: '${v.name} missing');
      }
    });

    for (final v in DesignSurface.values) {
      test('${v.name} counts the exemplar path', () {
        final exemplar = switch (v) {
          DesignSurface.guiWidget  => 'lib/widgets/a.dart',
          DesignSurface.guiUi      => 'lib/ui/a.dart',
          DesignSurface.guiPainter => 'lib/painters/a.dart',
          DesignSurface.guiTheme   => 'lib/theme/colors.dart',
          DesignSurface.logic      => 'lib/services/a.dart',
        };
        final tally = log.tallySurfaces([exemplar]);
        expect(tally[v], equals(1));
      });
    }
  });

  test('PlannerLog.record emits a JSONL line via the injected appender', () {
    final lines = <String>[];
    final log = PlannerLog(
      path: '/tmp/planner.jsonl',
      appender: (_, line) => lines.add(line),
    );
    log.record(PlannerDecision(
      timestamp: DateTime(2026, 5, 15, 12),
      flow: AgentFlow.guiDesign,
      category: AgentCategory.gui,
      intent: IntentClass.design,
      complexity: ComplexityTier.compound,
      model: AgentModel.sonnet,
      designSurfaceCounts: log.tallySurfaces(const [
        'lib/widgets/foo.dart',
        'lib/painters/bar.dart',
      ]),
      note: 'routed by path heuristic',
    ));
    expect(lines, hasLength(1));
    final decoded = jsonDecode(lines.single) as Map<String, dynamic>;
    expect(decoded['flow'], equals('guiDesign'));
    expect(decoded['intent'], equals('design'));
    expect(decoded['model'], equals('sonnet'));
    expect((decoded['surfaces'] as Map)['widget'], equals(1));
    expect((decoded['surfaces'] as Map)['painter'], equals(1));
    expect((decoded['surfaces'] as Map)['logic'], equals(0));
  });
}
