import 'dart:io';
import 'package:path/path.dart' as p;
import '../md_io.dart';
import '../paths.dart';
import '../handoff_template.dart';
import '../teardown_utils.dart';

Future<void> runTeardown() async {
  print('\n═══════════════════════════════════════');
  print('  IVI SESSION TEARDOWN');
  print('═══════════════════════════════════════');

  final handoff = readFile(handoffPath);
  if (handoff.isEmpty) {
    print('\nNo active handoff found. Nothing to tear down.\n');
    exit(0);
  }

  if (!confirm('Is the bug confirmed resolved?')) {
    print('\nCome back when the fix is confirmed. Continue with /debug or /suggest.\n');
    exit(0);
  }

  final fixSummary = prompt('Briefly describe the fix (one or two sentences)');

  // Extract session info
  final bug = readSection(handoff, 'Bug');
  final rootCause = readSection(handoff, 'Root Cause');
  final debugProgress = extractSection(handoff, 'Debug Progress');
  // filesChanged reserved for future knowledge routing
  readSubSection(debugProgress, 'What changed (files modified)');
  final branch = extractBranch(handoff);

  print('\n───────────────────────────────────────');
  print('Extracting learnings from session...');
  print('───────────────────────────────────────');

  // Prompt for what was genuinely useful
  print('\nHelp categorize this session for skills.md:\n');

  final category = prompt(
    'Root cause category?\n  (e.g. bloc-event-handling / provider-state / api-mapping / widget-lifecycle / ffi-bridge)',
  );

  final hotFiles = prompt(
    'Which files were confirmed key to the fix? (comma-separated, or "none")',
    optional: true,
  );

  final coldFiles = prompt(
    'Any files explored but NOT the root cause? (comma-separated, or skip)',
    optional: true,
  );

  final pattern = prompt(
    'Describe the root cause pattern generically (one sentence)\n  e.g. "BLoC emits stale state when event fires before previous async resolves"',
  );

  final fixPattern = prompt(
    'Describe the fix pattern generically (one sentence)\n  e.g. "Added restartable transformer to ensure sequential event processing"',
  );

  // Update skills.md
  _updateSkills(
    branch: branch,
    category: category!,
    hotFiles: hotFiles,
    coldFiles: coldFiles,
    pattern: pattern!,
    fixPattern: fixPattern!,
  );

  // Archive handoff
  _archiveHandoff(handoff, branch);

  // Reset handoff
  writeFile(handoffPath, blankHandoff);

  // Suggest commit message
  final area = areaFromCategory(category);
  final commitMsg = buildCommitMessage(area, bug, rootCause, fixSummary!);

  print('\n✓ Skills updated: $skillsPath');
  print('✓ Handoff archived: ${p.join(archiveDir, archiveName(branch))}');
  print('✓ Handoff reset.\n');
  print('───────────────────────────────────────');
  print('Suggested commit message:\n');
  print(commitMsg);
  print('───────────────────────────────────────');
  print('\nRemember: do not push to remote. Open a merge request from your branch.\n');
}

void _updateSkills({
  required String branch,
  required String category,
  String? hotFiles,
  String? coldFiles,
  required String pattern,
  required String fixPattern,
}) {
  var skills = readFile(skillsPath);
  if (skills.isEmpty) {
    skills = _defaultSkillsTemplate();
  }

  final date = DateTime.now().toIso8601String().split('T').first;

  final newPattern = '- **$category**: $pattern → Fix: $fixPattern';
  skills = appendToSection(skills, 'Root Cause Patterns', newPattern);

  if (hotFiles != null && hotFiles.toLowerCase() != 'none') {
    final files = hotFiles.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty);
    for (final file in files) {
      skills = incrementHotPath(skills, category, file);
    }
  }

  if (coldFiles != null && coldFiles.toLowerCase() != 'none') {
    final files = coldFiles.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty);
    for (final file in files) {
      final entry = '- `$file` — explored for $category, not the root cause';
      skills = appendToSection(skills, 'Anti-patterns', entry);
    }
  }

  if (branch != 'unknown') {
    final note = '- `$branch` ($date): $category resolved';
    skills = appendToSection(skills, 'Branch Notes', note);
  }

  final indexEntry = '`$branch` | $date | $category | resolved';
  skills = appendToSection(skills, 'Session Index', indexEntry);

  writeFile(skillsPath, skills);
}

void _archiveHandoff(String content, String branch) {
  Directory(archiveDir).createSync(recursive: true);
  final name = archiveName(branch);
  writeFile(p.join(archiveDir, name), content);
}

String _defaultSkillsTemplate() => '''# dc-flutter / media_ivi — Accumulated Skills

> Updated by `claudart teardown` after each resolved session.
> Read by `/suggest` and `/debug` at the start of every session.

---

## Hot Paths — media_ivi

_No sessions recorded yet._

---

## Root Cause Patterns

_No patterns recorded yet._

---

## Anti-patterns

_None recorded yet._

---

## Branch Notes

_None recorded yet._

---

## Session Index

_No sessions recorded yet._
''';
