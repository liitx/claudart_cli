import 'package:test/test.dart';
import 'package:claudart_cli/teardown_utils.dart';

void main() {
  group('extractBranch', () {
    test('extracts branch from handoff header', () {
      const doc = '> Session started: 2026-01-01 | Branch: fix/audio-freeze\n';
      expect(extractBranch(doc), 'fix/audio-freeze');
    });

    test('returns unknown when branch not present', () {
      expect(extractBranch('no branch here'), 'unknown');
    });

    test('trims whitespace', () {
      const doc = '> Branch:   main  \n';
      expect(extractBranch(doc), 'main');
    });
  });

  group('extractSection', () {
    const doc = '''
## Debug Progress

Some progress notes.

## Other

other content
''';

    test('extracts section content', () {
      expect(extractSection(doc, 'Debug Progress'), 'Some progress notes.');
    });

    test('returns empty string when section missing', () {
      expect(extractSection(doc, 'Nonexistent'), '');
    });
  });

  group('readSubSection', () {
    const section = '''
### What was attempted
Tried restarting the bloc.

### What changed (files modified)
audio_bloc.dart
''';

    test('extracts subsection content', () {
      expect(readSubSection(section, 'What was attempted'), 'Tried restarting the bloc.');
    });

    test('returns fallback when subsection missing', () {
      expect(readSubSection(section, 'Missing'), '_Nothing yet._');
    });
  });

  group('appendToSection', () {
    const doc = '''## Root Cause Patterns

_No patterns recorded yet._

## Other

content
''';

    test('replaces blank placeholder with first entry', () {
      final result = appendToSection(doc, 'Root Cause Patterns', '- new pattern');
      expect(result, contains('- new pattern'));
      expect(result, isNot(contains('_No patterns recorded yet._')));
    });

    test('appends to existing entries', () {
      var result = appendToSection(doc, 'Root Cause Patterns', '- first');
      result = appendToSection(result, 'Root Cause Patterns', '- second');
      expect(result, contains('- first'));
      expect(result, contains('- second'));
    });

    test('creates new section when header not found', () {
      final result = appendToSection(doc, 'New Section', '- entry');
      expect(result, contains('## New Section'));
      expect(result, contains('- entry'));
    });
  });

  group('incrementHotPath', () {
    const blankSkills = '''## Hot Paths

_No sessions recorded yet._
''';

    test('adds new file with single arrow', () {
      final result = incrementHotPath(blankSkills, 'bloc', 'audio_bloc.dart');
      expect(result, contains('`audio_bloc.dart` ↑'));
      expect(result, contains('[bloc]'));
    });

    test('increments existing file arrow', () {
      var skills = incrementHotPath(blankSkills, 'bloc', 'audio_bloc.dart');
      skills = incrementHotPath(skills, 'bloc', 'audio_bloc.dart');
      expect(RegExp(r'↑+').firstMatch(skills)?.group(0)?.length, 2);
    });
  });

  group('areaFromCategory', () {
    test('bloc categories', () {
      expect(areaFromCategory('bloc-event-handling'), 'bloc');
      expect(areaFromCategory('event-loop'), 'bloc');
    });

    test('provider categories', () {
      expect(areaFromCategory('provider-state'), 'provider');
      expect(areaFromCategory('riverpod-async'), 'provider');
    });

    test('api categories', () {
      expect(areaFromCategory('api-mapping'), 'api');
      expect(areaFromCategory('repository-cache'), 'api');
    });

    test('ui categories', () {
      expect(areaFromCategory('widget-lifecycle'), 'ui');
      expect(areaFromCategory('ui-rebuild'), 'ui');
    });

    test('ffi categories', () {
      expect(areaFromCategory('ffi-bridge'), 'ffi');
      expect(areaFromCategory('bridge-call'), 'ffi');
    });

    test('unknown falls back to general', () {
      expect(areaFromCategory('something-else'), 'general');
    });
  });

  group('buildCommitMessage', () {
    test('formats message without root cause', () {
      final msg = buildCommitMessage('bloc', 'Audio stuck on last frame.', '_Not yet determined._', 'Added restartable transformer');
      expect(msg, startsWith('fix(bloc): Audio stuck on last frame'));
      expect(msg, contains('Added restartable transformer'));
      expect(msg, isNot(contains('Root cause')));
    });

    test('includes root cause when known', () {
      final msg = buildCommitMessage('bloc', 'Audio stuck.', 'Missing transformer.', 'Fixed it');
      expect(msg, contains('Root cause: Missing transformer'));
    });
  });

  group('firstSentence', () {
    test('returns up to first dot when short', () {
      expect(firstSentence('Audio stuck. More detail here.'), 'Audio stuck');
    });

    test('truncates at 72 chars when no dot', () {
      final long = 'A' * 80;
      final result = firstSentence(long);
      expect(result.length, lessThanOrEqualTo(73)); // 72 + ellipsis
      expect(result, endsWith('…'));
    });

    test('returns full string when short and no dot', () {
      expect(firstSentence('short string'), 'short string');
    });
  });

  group('archiveName', () {
    test('contains branch name with slashes replaced', () {
      final name = archiveName('fix/audio-freeze');
      expect(name, contains('fix_audio-freeze'));
      expect(name, startsWith('handoff_'));
      expect(name, endsWith('.md'));
    });

    test('replaces spaces in branch name', () {
      final name = archiveName('my branch');
      expect(name, contains('my_branch'));
    });
  });
}
