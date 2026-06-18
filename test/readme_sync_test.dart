import 'dart:io';
import 'package:test/test.dart';

/// Verifies README.md stays 1:1 with the codebase.
///
/// The README is a single-page narrative (see the `docs/readme-rewrite` commit
/// "rewrite README — single-page, diagram + proof heavy, Phase 5 deferred to
/// PLAN"). It documents shipped surface only and intentionally carries **no**
/// per-enum glossary — the HandoffStatus / AgentFlow variant taxonomy lives in
/// PLAN.md, and deferred flows (e.g. guiDesign) are deliberately not advertised
/// here. The two sync guarantees that actually matter for that form:
///
/// 1. Command routing — every `claudart X` in the README dispatches in
///    bin/claudart.dart.
/// 2. File references — every .dart file the prose names exists on disk. The
///    Roadmap section is excluded: it legitimately names planned, not-yet-built
///    files (e.g. `planner.dart`).
///
/// Run: CLAUDART_WORKSPACE=/tmp/claudart_test dart test test/readme_sync_test.dart
void main() {
  late String readme;

  setUpAll(() {
    readme = File('README.md').readAsStringSync();
  });

  group('Command routing sync', () {
    test('every `claudart X` command in the README dispatches in '
        'bin/claudart.dart', () {
      final entry = File('bin/claudart.dart').readAsStringSync();

      // Matches "`claudart X`" — single-word sub-commands. Excludes the bare
      // "`claudart`" launcher and multi-word forms (the base command is still
      // captured).
      final readmeCmds = RegExp(r'`claudart (\w[\w-]*)`')
          .allMatches(readme)
          .map((m) => m.group(1)!)
          .toSet();

      for (final cmd in readmeCmds) {
        expect(
          entry,
          contains("'$cmd'"),
          reason: 'Command `$cmd` appears in the README but has no case in '
              'bin/claudart.dart. Add routing or remove the row.',
        );
      }
    });
  });

  group('File reference sync', () {
    test('every .dart file referenced in the prose exists under lib/ or bin/ '
        '(Roadmap excluded)', () {
      // The Roadmap names planned files that intentionally do not exist yet.
      final prose = readme.replaceAll(
        RegExp(r'\n## Roadmap\b.*?(?=\n## )', dotAll: true),
        '\n',
      );

      final dartFiles = [
        ...Directory('lib').listSync(recursive: true),
        ...Directory('bin').listSync(recursive: true),
      ].whereType<File>().map((f) => f.path).toList();

      final refs = RegExp(r'[A-Za-z0-9_/]+\.dart')
          .allMatches(prose)
          .map((m) => m.group(0)!.split('/').last)
          .toSet();

      for (final basename in refs) {
        expect(
          dartFiles.any((f) => f.endsWith('/$basename')),
          isTrue,
          reason: '`$basename` is referenced in README.md prose but does not '
              'exist under lib/ or bin/. Fix or remove the reference.',
        );
      }
    });
  });
}
