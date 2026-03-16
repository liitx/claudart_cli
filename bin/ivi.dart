import 'dart:io';
import 'package:args/args.dart';
import '../lib/commands/setup.dart';
import '../lib/commands/status.dart';
import '../lib/commands/teardown.dart';

const _usage = '''
IVI Claude Workflow CLI

Usage:
  ivi <command>

Commands:
  setup      Start a new debug/suggest session (initializes handoff.md)
  status     Show current session status
  teardown   Close session: update skills, archive handoff, suggest commit

Options:
  -h, --help   Show this help message
''';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false);

  ArgResults parsed;
  try {
    parsed = parser.parse(args);
  } catch (_) {
    print(_usage);
    exit(1);
  }

  if (parsed['help'] as bool || parsed.rest.isEmpty) {
    print(_usage);
    exit(0);
  }

  final command = parsed.rest.first;

  switch (command) {
    case 'setup':
      await runSetup();
    case 'status':
      runStatus();
    case 'teardown':
      await runTeardown();
    default:
      print('Unknown command: $command\n');
      print(_usage);
      exit(1);
  }
}
