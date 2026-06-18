// render_primitives_test.dart — the shared formatting primitives (header,
// status badge, field) that command output migrates onto.
//
// Runs without a TTY, so `ansi.c` strips colour — assertions match plain text
// and verify no escape sequences leak.

import 'package:claudart/ui/render.dart' as render;
import 'package:test/test.dart';

void main() {
  group('StatusBadge — glyph + colour per variant', () {
    for (final badge in render.StatusBadge.values) {
      test(badge.name, () {
        expect(badge.icon, isNotEmpty);
        expect(badge.colorCode, isNotEmpty);
      });
    }

    test('glyphs are unique across badges', () {
      final glyphs = render.StatusBadge.values.map((b) => b.icon).toList();
      expect(glyphs.toSet().length, equals(glyphs.length));
    });
  });

  group('header', () {
    test('frames the title in a bold rule, no ANSI in non-TTY', () {
      final out = render.header('CLAUDART SESSION SETUP');
      expect(out, contains('CLAUDART SESSION SETUP'));
      expect(out, contains('═'));
      expect(out, isNot(contains('\x1b')));
    });

    test('rule width tracks the title length', () {
      final out = render.header('AB');
      // bar = '═' * (len + 4)
      expect(out, contains('═' * 6));
    });
  });

  group('status', () {
    test('renders glyph + label, detail omitted when blank', () {
      final out = render.status(render.StatusBadge.ok, 'Handoff written');
      expect(out, contains('✓'));
      expect(out, contains('Handoff written'));
      expect(out, isNot(contains('\x1b')));
    });

    test('appends detail when present', () {
      final out = render.status(
        render.StatusBadge.fail,
        'Build',
        detail: 'exit 1',
      );
      expect(out, contains('✗'));
      expect(out, contains('Build'));
      expect(out, contains('exit 1'));
    });
  });

  group('field', () {
    test('pads the key column for alignment', () {
      final out = render.field('Symlink', '/tmp/x');
      expect(out, equals('  Symlink   : /tmp/x'));
    });
  });
}
