import 'dart:io';
import 'package:path/path.dart' as p;
import '../file_io.dart';
import '../git_utils.dart';
import '../paths.dart';
import '../registry.dart';
import '../session/session_state.dart';
import '../teardown_utils.dart';

/// Result of the skills.md pending update — used in reports and tests.
enum SkillsUpdateResult { written, skipped }

/// Checkpoints the current session state without ending it.
///
/// Writes a dated snapshot to archive/ and appends confirmed facts to the
/// skills.md pending section. Does NOT reset the handoff or remove the symlink
/// — those are teardown/kill's responsibility.
Future<SkillsUpdateResult> runSave({
  FileIO? io,
  String? projectRootOverride,
  Never Function(int code)? exitFn,
}) async {
  final fileIO = io ?? const RealFileIO();
  final exit_ = exitFn ?? exit;

  print('\n═══════════════════════════════════════');
  print('  CLAUDART SAVE');
  print('═══════════════════════════════════════');

  // 1 — Registry lookup.
  final projectRoot = projectRootOverride ?? detectGitContext()?.root;
  if (projectRoot == null) {
    print('\n✗ Not inside a git repository. Cannot detect project.\n');
    exit_(1);
  }

  final registry = Registry.load(io: fileIO);
  final entry = registry.findByProjectRoot(projectRoot);
  if (entry == null) {
    print('\n✗ No claudart session found for this project.');
    print('  Run `claudart setup` to start one.\n');
    exit_(1);
  }

  final workspace = entry.workspacePath;
  final handoffFile = handoffPathFor(workspace);

  // 2 — Read handoff.
  if (!fileIO.fileExists(handoffFile)) {
    print('\n⚠  No handoff found in workspace. Nothing to checkpoint.\n');
    exit_(0);
  }

  final handoff = fileIO.read(handoffFile);
  final state = SessionState.parse(handoff);

  // 3 — Write checkpoint to archive/.
  final archiveDir = archiveDirFor(workspace);
  fileIO.createDir(archiveDir);
  final checkpointFile = p.join(archiveDir, _checkpointName(state.branch));
  fileIO.write(checkpointFile, handoff);

  // 4 — Append confirmed facts to skills.md pending section.
  final skillsFile = skillsPathFor(workspace);
  final skillsResult = _updatePendingSkills(
    fileIO: fileIO,
    skillsFile: skillsFile,
    state: state,
  );

  // 5 — Touch registry.
  registry.touchSession(entry.name).save(io: fileIO);

  // 6 — Report.
  _printReport(entry.name, state, checkpointFile, skillsResult);

  return skillsResult;
}

// ── Skills update ─────────────────────────────────────────────────────────────

SkillsUpdateResult _updatePendingSkills({
  required FileIO fileIO,
  required String skillsFile,
  required SessionState state,
}) {
  if (_isBlank(state.rootCause)) return SkillsUpdateResult.skipped;

  final today = DateTime.now().toIso8601String().split('T').first;
  var skills = fileIO.fileExists(skillsFile)
      ? fileIO.read(skillsFile)
      : _blankSkillsTemplate;

  // Root cause entry — always written when confirmed.
  final causeEntry =
      '- `${state.branch}` ($today): root cause — '
      '${state.rootCause.replaceAll('\n', ' ').trim()}';
  skills = appendToSection(skills, 'Pending', causeEntry);

  // Hot files entry — written when files changed are confirmed.
  if (!_isBlank(state.changed)) {
    final filesEntry =
        '- `${state.branch}` ($today): hot files — '
        '${state.changed.replaceAll('\n', ' ').trim()}';
    skills = appendToSection(skills, 'Pending', filesEntry);
  }

  fileIO.write(skillsFile, skills);
  return SkillsUpdateResult.written;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _checkpointName(String branch) {
  final ts = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final safeBranch = branch.replaceAll('/', '_').replaceAll(' ', '_');
  return 'checkpoint_${safeBranch}_$ts.md';
}

bool _isBlank(String s) =>
    s.isEmpty || s.startsWith('_Not') || s.startsWith('_Nothing');

void _printReport(
  String projectName,
  SessionState state,
  String checkpointFile,
  SkillsUpdateResult skillsResult,
) {
  print('\n✓ Checkpoint: ${p.basename(checkpointFile)}');
  print('  Branch : ${state.branch}');
  print('  Status : ${state.status}');

  if (skillsResult == SkillsUpdateResult.written) {
    print('  Skills : pending entry written (root cause confirmed)');
  } else {
    print('  Skills : skipped (root cause not yet confirmed)');
  }

  print('');
  switch (state.status) {
    case 'suggest-investigating':
      print('Continue exploring. Run /save again when root cause is confirmed.');
    case 'ready-for-debug':
      print('Root cause locked. Run /debug to implement the fix.');
    case 'debug-in-progress':
      print('Fix in progress. Run /save again after confirming the fix.');
    default:
      print('Run /suggest or /debug to continue.');
  }
  print('');
}

const String _blankSkillsTemplate = '''# Accumulated Skills
> Updated by claudart teardown and save. Do not edit manually.

---

## Pending

> Confirmed facts from in-progress sessions. Promoted to patterns by teardown.

_Nothing yet._

---

## Hot Paths

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
