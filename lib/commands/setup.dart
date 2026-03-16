import 'dart:io';
import 'package:path/path.dart' as p;
import '../md_io.dart';
import '../paths.dart';
import '../handoff_template.dart';

Future<void> runSetup() async {
  print('\n═══════════════════════════════════════');
  print('  IVI SESSION SETUP');
  print('═══════════════════════════════════════');

  // Check for active handoff
  final existing = readFile(handoffPath);
  if (existing.isNotEmpty) {
    final status = readStatus(existing);
    if (status != 'suggest-investigating' && !existing.contains('_Not yet determined._\n\n---\n\n## Expected')) {
      print('\n⚠  Active handoff found (status: $status)');
      if (!confirm('Overwrite and start a new session?')) {
        print('\nSetup cancelled. Run /suggest or /debug to continue the existing session.');
        exit(0);
      }
    }
  }

  // Detect git branch
  final branch = await _detectBranch();

  // Read skills for relevant context
  final skills = readFile(skillsPath);
  if (skills.isNotEmpty && !skills.contains('_No sessions recorded yet._')) {
    print('\n📚 Skills loaded — relevant patterns will inform /suggest.');
  }

  // Prompt for session context
  print('\nAnswer the following. Be specific — this seeds the handoff for /suggest.\n');

  final bug = prompt('1. What is the bug? (actual behavior)');
  final expected = prompt('2. What should be happening? (expected behavior)');
  final files = prompt(
    '3. Any files already in mind? (e.g. media_bloc.dart, playback_repository.dart)',
    optional: true,
  );
  final blocs = prompt(
    '4. Any BLoC events, provider names, or API calls involved?',
    optional: true,
  );

  // Confirm before writing
  print('\n───────────────────────────────────────');
  print('Branch : $branch');
  print('Bug    : $bug');
  print('Expected: $expected');
  if (files != null) print('Files  : $files');
  if (blocs != null) print('BLoCs  : $blocs');
  print('───────────────────────────────────────');

  if (!confirm('Write handoff with this context?')) {
    print('\nSetup cancelled.');
    exit(0);
  }

  // Write handoff
  final date = DateTime.now().toIso8601String().split('T').first;
  final content = handoffTemplate(
    branch: branch,
    date: date,
    bug: bug!,
    expected: expected!,
    files: files,
    blocs: blocs,
  );
  writeFile(handoffPath, content);

  print('\n✓ Handoff written to $handoffPath');
  print('\nNext step:');
  print('  Open Claude Code and run /suggest to begin exploration.');
  print('  Or run /debug if you already know the root cause.\n');
}

Future<String> _detectBranch() async {
  try {
    final result = await Process.run('git', ['branch', '--show-current']);
    final branch = (result.stdout as String).trim();
    if (branch.isNotEmpty) {
      print('\n🌿 Branch detected: $branch');
      return branch;
    }
  } catch (_) {}

  // Not in a git repo or git not available — ask
  return prompt('Could not detect git branch. Enter branch name manually') ?? 'unknown';
}
