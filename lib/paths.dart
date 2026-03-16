import 'dart:io';
import 'package:path/path.dart' as p;

final String claudeDir = p.join(Platform.environment['HOME']!, 'dev', 'dev_tools', 'claude');
final String handoffPath = p.join(claudeDir, 'handoff.md');
final String skillsPath = p.join(claudeDir, 'skills.md');
final String archiveDir = p.join(claudeDir, 'archive');
