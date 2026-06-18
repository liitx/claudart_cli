// agent_response_test.dart — AgentResponse taxonomy matrix + invariants.
//
// One test per ResponseKind / Speaker variant (surface grows with the enum),
// plus the structural invariants: never-guess and questions-float.

import 'package:claudart/pipeline/agent_flow.dart';
import 'package:claudart/pipeline/agent_response.dart';
import 'package:zedup/zedup.dart' show StateHue;
import 'package:test/test.dart';

extension on ResponseKind {
  String get expectedLabel => switch (this) {
        ResponseKind.plan     => 'Plan',
        ResponseKind.progress => 'Progress',
        ResponseKind.question => 'Question',
        ResponseKind.result   => 'Result',
        ResponseKind.blocker  => 'Blocker',
        ResponseKind.handoff  => 'Handoff',
        ResponseKind.replan   => 'Replan',
        ResponseKind.action   => 'Action',
      };
}

extension on SubtaskState {
  StateHue get expectedHue => switch (this) {
        SubtaskState.ready          => StateHue.ready,
        SubtaskState.blocked        => StateHue.inactive,
        SubtaskState.awaitingAnswer => StateHue.paused,
        SubtaskState.running        => StateHue.active,
        SubtaskState.done           => StateHue.success,
        SubtaskState.failed         => StateHue.error,
      };
}

void main() {
  group('ResponseKind — label / icon / colour per variant', () {
    for (final kind in ResponseKind.values) {
      test(kind.name, () {
        expect(kind.label, equals(kind.expectedLabel));
        expect(kind.icon, isNotEmpty);
      });
    }
  });

  group('ResponseKind.sortPriority', () {
    test('unique across variants', () {
      final priorities = ResponseKind.values.map((k) => k.sortPriority).toList();
      expect(priorities.toSet().length, equals(priorities.length));
    });

    test('question floats first (lowest priority)', () {
      final lowest = ResponseKind.values
          .map((k) => k.sortPriority)
          .reduce((a, b) => a < b ? a : b);
      expect(ResponseKind.question.sortPriority, equals(lowest));
    });
  });

  group('SubtaskState.hue — one state colour per variant', () {
    for (final state in SubtaskState.values) {
      test(state.name, () {
        expect(state.hue, equals(state.expectedHue));
      });
    }
  });

  group('Speaker — label per variant', () {
    for (final speaker in Speaker.values) {
      test(speaker.name, () {
        expect(speaker.label, isNotEmpty);
      });
    }

    test('labels unique across speakers', () {
      final labels = Speaker.values.map((s) => s.label).toList();
      expect(labels.toSet().length, equals(labels.length));
    });
  });

  group('never-guess invariant', () {
    test('Result.forSubtask throws when the subtask awaits an answer', () {
      const subtask = Subtask(
        id:        'a',
        workspace: 'w',
        priority:  1,
        state:     SubtaskState.awaitingAnswer,
      );
      expect(
        () => Result.forSubtask(
          subtask,
          speaker:      Speaker.subagent,
          filesTouched: const [],
          summary:      's',
        ),
        throwsStateError,
      );
    });

    test('Result.forSubtask builds for a resolved subtask', () {
      const subtask = Subtask(id: 'a', workspace: 'w', priority: 1);
      final result = Result.forSubtask(
        subtask,
        speaker:      Speaker.subagent,
        filesTouched: const ['f'],
        summary:      's',
      );
      expect(result.subtask, equals('a'));
      expect(result.workspace, equals('w'));
    });
  });

  group('floatQuestions', () {
    test('questions sort to the front, others keep arrival order', () {
      final responses = <AgentResponse>[
        const Progress(
          speaker:   Speaker.agent,
          workspace: 'w',
          subtask:   't1',
          flow:      AgentFlow.flow,
          blocked:   false,
        ),
        const Question(
          speaker:        Speaker.subagent,
          origin:         'b',
          workspace:      'w',
          blockedSubtask: 't2',
          question:       'q',
        ),
        const Result(
          speaker:      Speaker.subagent,
          workspace:    'w',
          subtask:      't3',
          filesTouched: [],
          summary:      'done',
        ),
      ];
      final ordered = floatQuestions(responses);
      expect(ordered[0], isA<Question>());
      expect(ordered[1], isA<Progress>());
      expect(ordered[2], isA<Result>());
    });
  });
}
