// planner_log_test.dart — PlannerLog emits one JSONL record per decision
// and tallies DesignSurface variants across the input paths.

import 'dart:convert';
import 'dart:io';

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

  group('PlannerDecision.fromCategorizeOutput', () {
    const tally = <DesignSurface, int>{};
    final fixedNow = DateTime(2026, 5, 19, 12);

    test('parses a well-formed classification block', () {
      const raw = '''
<CATEGORY>feature</CATEGORY>
<INTENT>explore</INTENT>
<COMPLEXITY>compound</COMPLEXITY>
<MODEL>sonnet</MODEL>
''';
      final decision = PlannerDecision.fromCategorizeOutput(
        raw,
        designSurfaceCounts: tally,
        now: () => fixedNow,
      );
      expect(decision, isNotNull);
      expect(decision!.category, equals(AgentCategory.feature));
      expect(decision.intent, equals(IntentClass.explore));
      expect(decision.complexity, equals(ComplexityTier.compound));
      expect(decision.model, equals(AgentModel.sonnet));
      expect(decision.timestamp, equals(fixedNow));
    });

    test('is case-insensitive (Sonnet vs sonnet)', () {
      const raw = '''
<CATEGORY>Feature</CATEGORY>
<INTENT>Explore</INTENT>
<COMPLEXITY>Compound</COMPLEXITY>
<MODEL>Sonnet</MODEL>
''';
      final decision = PlannerDecision.fromCategorizeOutput(
        raw,
        designSurfaceCounts: tally,
      );
      expect(decision, isNotNull);
      expect(decision!.model, equals(AgentModel.sonnet));
    });

    test('returns null when a required tag is missing', () {
      const raw = '''
<CATEGORY>feature</CATEGORY>
<INTENT>explore</INTENT>
<COMPLEXITY>compound</COMPLEXITY>
''';
      expect(
        PlannerDecision.fromCategorizeOutput(
          raw,
          designSurfaceCounts: tally,
        ),
        isNull,
      );
    });

    test('returns null when a tag maps to an unknown enum variant', () {
      const raw = '''
<CATEGORY>feature</CATEGORY>
<INTENT>explore</INTENT>
<COMPLEXITY>compound</COMPLEXITY>
<MODEL>gpt-9</MODEL>
''';
      expect(
        PlannerDecision.fromCategorizeOutput(
          raw,
          designSurfaceCounts: tally,
        ),
        isNull,
      );
    });

    test('full round-trip: parser → record → JSONL', () {
      const raw = '''
<CATEGORY>bug</CATEGORY>
<INTENT>analyze</INTENT>
<COMPLEXITY>atomic</COMPLEXITY>
<MODEL>haiku</MODEL>
''';
      final lines = <String>[];
      final log = PlannerLog(
        path: '/tmp/planner.jsonl',
        appender: (_, line) => lines.add(line),
      );
      final decision = PlannerDecision.fromCategorizeOutput(
        raw,
        designSurfaceCounts: log.tallySurfaces(const ['lib/widgets/x.dart']),
      );
      expect(decision, isNotNull);
      log.record(decision!);
      final decoded = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(decoded['category'], equals('bug'));
      expect(decoded['model'], equals('haiku'));
      expect((decoded['surfaces'] as Map)['widget'], equals(1));
    });
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

  group('PlannerDecision timestamp normalization', () {
    test('default clock returns UTC so JSONL streams sort cross-timezone', () {
      const raw = '''
<CATEGORY>feature</CATEGORY>
<INTENT>explore</INTENT>
<COMPLEXITY>compound</COMPLEXITY>
<MODEL>sonnet</MODEL>
''';
      final decision = PlannerDecision.fromCategorizeOutput(
        raw,
        designSurfaceCounts: const {},
      );
      expect(decision, isNotNull);
      expect(decision!.timestamp.isUtc, isTrue,
          reason: 'default timestamp must be UTC to match SessionLogger');
    });

    test('serialized ts ends with Z when default clock is used', () {
      const raw = '''
<CATEGORY>feature</CATEGORY>
<INTENT>explore</INTENT>
<COMPLEXITY>compound</COMPLEXITY>
<MODEL>sonnet</MODEL>
''';
      final decision = PlannerDecision.fromCategorizeOutput(
        raw,
        designSurfaceCounts: const {},
      );
      final ts = decision!.toJson()['ts'] as String;
      expect(ts, endsWith('Z'));
    });
  });

  test('plannerLogRecordFailureWarning is non-empty and prose-shaped', () {
    expect(plannerLogRecordFailureWarning, isNotEmpty);
    expect(plannerLogRecordFailureWarning.toLowerCase(), contains('planner'));
  });

  // ── PlannerLog.record propagates appender exceptions ────────────────────
  //
  // Documents the contract `_recordClassification` (lib/commands/flow.dart)
  // depends on: an appender that throws (disk full, perms, missing dir)
  // bubbles the exception from .record(...). Callers are responsible for
  // wrapping in try/catch — see [plannerLogRecordFailureWarning] for the
  // stderr line emitted on the catch path.

  test('PlannerLog.record bubbles appender exceptions to caller', () {
    final log = PlannerLog(
      path: '/tmp/ignored',
      appender: (_, __) => throw const FileSystemException('disk full'),
    );
    expect(
      () => log.record(PlannerDecision(
        timestamp: DateTime.utc(2026, 5, 19),
        flow: AgentFlow.flow,
        category: AgentCategory.bug,
        intent: IntentClass.analyze,
        complexity: ComplexityTier.atomic,
        model: AgentModel.haiku,
        designSurfaceCounts: const {},
      )),
      throwsA(isA<FileSystemException>()),
    );
  });
}
