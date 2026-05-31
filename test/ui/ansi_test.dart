import 'dart:io';
import 'package:test/test.dart';
import 'package:claudart/ui/ansi.dart';

class MockStdout implements Stdout {
  final bool _hasTerminal;
  MockStdout(this._hasTerminal);

  @override
  bool get hasTerminal => _hasTerminal;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ansi', () {
    test('constants', () {
      expect(reset, '\x1b[0m');
      expect(bold, '\x1b[1m');
      expect(dim, '\x1b[2m');
      expect(red, '\x1b[31m');
      expect(green, '\x1b[32m');
      expect(yellow, '\x1b[33m');
      expect(cyan, '\x1b[36m');
      expect(hideCursor, '\x1b[?25l');
      expect(showCursor, '\x1b[?25h');
      expect(clearLine, '\r\x1b[K');
    });

    test('cursorUp', () {
      expect(cursorUp(1), '\x1b[1A');
      expect(cursorUp(5), '\x1b[5A');
    });

    group('c() helper', () {
      test('wraps text when stdout has terminal', () {
        IOOverrides.runZoned(
          () {
            expect(c(red, 'Hello'), '${red}Hello$reset');
          },
          stdout: () => MockStdout(true),
        );
      });

      test('does not wrap text when stdout does not have terminal', () {
        IOOverrides.runZoned(
          () {
            expect(c(red, 'Hello'), 'Hello');
          },
          stdout: () => MockStdout(false),
        );
      });
    });
  });
}
