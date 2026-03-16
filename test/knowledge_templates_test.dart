import 'package:test/test.dart';
import 'package:claudart/knowledge_templates.dart';

void main() {
  group('dartFlutterTemplate', () {
    test('includes version tags', () {
      final t = dartFlutterTemplate('3.32.5', '3.8.0');
      expect(t, contains('Flutter 3.32.5'));
      expect(t, contains('Dart 3.8.0'));
    });

    test('contains core practices', () {
      final t = dartFlutterTemplate('3.x', '3.x');
      expect(t, contains('const'));
      expect(t, contains('sealed'));
    });
  });

  group('blocTemplate', () {
    test('is non-empty and contains key headings', () {
      expect(blocTemplate, contains('## Events'));
      expect(blocTemplate, contains('## State'));
      expect(blocTemplate, contains('## BLoC class'));
    });
  });

  group('riverpodTemplate', () {
    test('contains key headings', () {
      expect(riverpodTemplate, contains('## Providers'));
      expect(riverpodTemplate, contains('## AsyncNotifier'));
    });
  });

  group('testingTemplate', () {
    test('contains key headings', () {
      expect(testingTemplate, contains('## Unit tests'));
      expect(testingTemplate, contains('## Widget tests'));
      expect(testingTemplate, contains('## Coverage'));
    });
  });

  group('projectTemplate', () {
    test('includes project name', () {
      final t = projectTemplate('my-app');
      expect(t, contains('my-app'));
    });

    test('contains expected sections', () {
      final t = projectTemplate('x');
      expect(t, contains('## Architecture'));
      expect(t, contains('## Hot paths'));
      expect(t, contains('## Root cause patterns'));
      expect(t, contains('## Anti-patterns'));
    });
  });

  group('claudeMdTemplate', () {
    final base = claudeMdTemplate(
      workspacePath: '/workspace',
      projectName: 'my-app',
      genericFiles: ['bloc.md', 'dart_flutter.md'],
    );

    test('includes project name', () {
      expect(base, contains('Project: my-app'));
    });

    test('lists generic knowledge files with absolute paths', () {
      expect(base, contains('/workspace/knowledge/generic/bloc.md'));
      expect(base, contains('/workspace/knowledge/generic/dart_flutter.md'));
    });

    test('includes project knowledge path', () {
      expect(base, contains('/workspace/knowledge/projects/my-app.md'));
    });

    test('includes session state paths', () {
      expect(base, contains('/workspace/handoff.md'));
      expect(base, contains('/workspace/skills.md'));
    });

    test('no environment section when constraints absent', () {
      expect(base, isNot(contains('## Environment')));
    });

    test('includes environment section when sdk provided', () {
      final t = claudeMdTemplate(
        workspacePath: '/workspace',
        projectName: 'my-app',
        genericFiles: [],
        sdkConstraint: '^3.8.0',
      );
      expect(t, contains('## Environment'));
      expect(t, contains('Dart SDK: `^3.8.0`'));
      expect(t, isNot(contains('Flutter')));
    });

    test('includes flutter constraint when provided', () {
      final t = claudeMdTemplate(
        workspacePath: '/workspace',
        projectName: 'my-app',
        genericFiles: [],
        sdkConstraint: '^3.8.0',
        flutterConstraint: '3.32.5',
      );
      expect(t, contains('Flutter: `3.32.5`'));
    });

    test('includes analyzer instruction in environment section', () {
      final t = claudeMdTemplate(
        workspacePath: '/workspace',
        projectName: 'my-app',
        genericFiles: [],
        sdkConstraint: '^3.8.0',
      );
      expect(t, contains('Do not suggest APIs or syntax unavailable'));
    });
  });
}
