// path_heuristic_test.dart — DesignSurface contract + classifier matrix.

import 'package:claudart/pipeline/agents/path_heuristic.dart';
import 'package:test/test.dart';

extension on DesignSurface {
  String get expectedTag => switch (this) {
        DesignSurface.guiWidget   => 'widget',
        DesignSurface.guiUi       => 'ui',
        DesignSurface.guiPainter  => 'painter',
        DesignSurface.guiTheme    => 'theme',
        DesignSurface.logic       => 'logic',
      };

  bool get expectedIsDesignSurface => this != DesignSurface.logic;

  /// A representative path the classifier must map back to this variant.
  String get exemplarPath => switch (this) {
        DesignSurface.guiWidget   => 'lib/widgets/foo_widget.dart',
        DesignSurface.guiUi       => 'lib/ui/home_screen.dart',
        DesignSurface.guiPainter  => 'lib/painters/wave_painter.dart',
        DesignSurface.guiTheme    => 'lib/theme/colors.dart',
        DesignSurface.logic       => 'lib/services/repository.dart',
      };
}

void main() {
  group('DesignSurface.tag', () {
    for (final s in DesignSurface.values) {
      test(s.name, () {
        expect(s.tag, equals(s.expectedTag));
      });
    }
  });

  group('DesignSurface.isDesignSurface', () {
    for (final s in DesignSurface.values) {
      test(s.name, () {
        expect(s.isDesignSurface, equals(s.expectedIsDesignSurface));
      });
    }
  });

  group('classifyPath roundtrips every DesignSurface variant', () {
    for (final s in DesignSurface.values) {
      test(s.name, () {
        expect(classifyPath(s.exemplarPath), equals(s));
      });
    }
  });

  test('classifyPath — alternate painter pattern (file-suffix variant)', () {
    expect(
      classifyPath('lib/render/wave_painter.dart'),
      equals(DesignSurface.guiPainter),
    );
  });

  test('isDesignScope — empty input returns false', () {
    expect(isDesignScope(const []), isFalse);
  });

  test('isDesignScope — majority design surfaces routes to gui flow', () {
    expect(
      isDesignScope(const [
        'lib/widgets/a.dart',
        'lib/widgets/b.dart',
        'lib/services/c.dart',
      ]),
      isTrue,
    );
  });

  test('isDesignScope — minority design surfaces stays on logic flow', () {
    expect(
      isDesignScope(const [
        'lib/widgets/a.dart',
        'lib/services/b.dart',
        'lib/services/c.dart',
      ]),
      isFalse,
    );
  });
}
