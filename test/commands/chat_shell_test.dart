// chat_shell_test.dart — the chat-first command parser (matrix) and the
// hermetic read→parse→dispatch loop. Conversation is the default: plain text is
// a message, only slash commands invoke.

import 'package:claudart/commands/chat_shell.dart';
import 'package:test/test.dart';

void main() {
  group('ChatCommand.parse — conversation is the default', () {
    const cases = <String, ChatCommand>{
      'hello there':  ChatCommand.message, // plain text = conversation
      'flow':         ChatCommand.message, // no slash = NOT the command
      'what is flow?':ChatCommand.message,
      '/flow':        ChatCommand.flow,
      '/FLOW':        ChatCommand.flow,
      '  /flow ':     ChatCommand.flow,
      '/flow now':    ChatCommand.flow,
      '/suggest':     ChatCommand.suggest,
      '/quit':        ChatCommand.quit,
      '/exit':        ChatCommand.quit,
      '/q':           ChatCommand.quit,
      '/help':        ChatCommand.help,
      '/nope':        ChatCommand.help, // unrecognized command → help
      '':             ChatCommand.help,
    };

    cases.forEach((input, expected) {
      test('"$input" → ${expected.name}', () {
        expect(ChatCommand.parse(input), equals(expected));
      });
    });
  });

  group('runChatLoop', () {
    test('plain text routes to onMessage; slash commands dispatch', () async {
      final lines = ['hello', '/flow', 'bye', '/quit', 'never'].iterator;
      final messages = <String>[];
      var flow = 0;
      await runChatLoop(
        readLine:  () => lines.moveNext() ? lines.current : null,
        out:       (_) {},
        onFlow:    () async => flow++,
        onSuggest: () async {},
        onMessage: (t) async => messages.add(t),
      );
      expect(messages, equals(['hello', 'bye']));
      expect(flow, equals(1)); // 'never' after /quit does not run
    });

    test('returns on EOF without hanging', () async {
      await runChatLoop(
        readLine:  () => null,
        out:       (_) {},
        onFlow:    () async {},
        onSuggest: () async {},
        onMessage: (_) async {},
      );
    });

    test('/help prints a hint and dispatches nothing', () async {
      final lines = ['/help', '/quit'].iterator;
      final out = <String>[];
      var touched = 0;
      await runChatLoop(
        readLine:  () => lines.moveNext() ? lines.current : null,
        out:       out.add,
        onFlow:    () async => touched++,
        onSuggest: () async => touched++,
        onMessage: (_) async => touched++,
      );
      expect(touched, equals(0));
      expect(out.length, equals(1));
    });
  });
}
