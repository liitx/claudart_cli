import 'dart:io';
import 'package:path/path.dart' as p;

/// Workspace directory — where handoff.md, skills.md, and archive/ live.
/// Resolved from CLAUDART_WORKSPACE env var, falls back to ~/.claudart/
final String claudeDir = () {
  final env = Platform.environment['CLAUDART_WORKSPACE'];
  if (env != null && env.isNotEmpty) {
    // Expand leading ~ manually since Dart doesn't shell-expand paths
    if (env.startsWith('~/')) {
      return p.join(Platform.environment['HOME']!, env.substring(2));
    }
    return env;
  }
  return p.join(Platform.environment['HOME']!, '.claudart');
}();

final String handoffPath = p.join(claudeDir, 'handoff.md');
final String skillsPath = p.join(claudeDir, 'skills.md');
final String archiveDir = p.join(claudeDir, 'archive');
