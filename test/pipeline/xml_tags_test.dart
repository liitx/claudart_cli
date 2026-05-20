// xml_tags_test.dart — tagOr / tagOrNull / tagOrNullIgnoreCase.
//
// Three parsers, three cases: case-sensitive match, no match, and the
// case-insensitive variant introduced for LLM-emitted tags.

import 'package:claudart/pipeline/xml_tags.dart';
import 'package:test/test.dart';

void main() {
  group('tagOr', () {
    test('returns content when tag present', () {
      expect(tagOr('<X>hello</X>', 'X'), equals('hello'));
    });

    test('returns fallback when tag absent', () {
      expect(
        tagOr('no tags here', 'X', 'FALLBACK'),
        equals('FALLBACK'),
      );
    });

    test('default fallback when none provided', () {
      expect(tagOr('no tags', 'X'), isNotEmpty);
    });

    test('case-sensitive — lower-case tag in input misses upper-case lookup',
        () {
      expect(tagOr('<x>hello</x>', 'X', 'MISS'), equals('MISS'));
    });
  });

  group('tagOrNull', () {
    test('returns content when tag present', () {
      expect(tagOrNull('<X>hello</X>', 'X'), equals('hello'));
    });

    test('returns null when tag absent', () {
      expect(tagOrNull('no tags', 'X'), isNull);
    });

    test('case-sensitive — lower-case tag returns null on upper lookup', () {
      expect(tagOrNull('<x>hello</x>', 'X'), isNull);
    });

    test('content with newlines + leading/trailing whitespace is trimmed',
        () {
      expect(
        tagOrNull('<X>\n  hello\n  </X>', 'X'),
        equals('hello'),
      );
    });
  });

  group('tagOrNullIgnoreCase', () {
    test('upper-case tag matches upper-case lookup', () {
      expect(
        tagOrNullIgnoreCase('<CATEGORY>feature</CATEGORY>', 'CATEGORY'),
        equals('feature'),
      );
    });

    test('lower-case tag matches upper-case lookup', () {
      expect(
        tagOrNullIgnoreCase('<category>feature</category>', 'CATEGORY'),
        equals('feature'),
      );
    });

    test('mixed-case tag matches', () {
      expect(
        tagOrNullIgnoreCase('<Category>feature</Category>', 'CATEGORY'),
        equals('feature'),
      );
    });

    test('mismatched open/close case still matches (regex is per-side)', () {
      // Each side of the regex is independently case-insensitive — a
      // `<CATEGORY>...</category>` would also match. Documents the
      // tolerance level.
      expect(
        tagOrNullIgnoreCase('<CATEGORY>feature</category>', 'CATEGORY'),
        equals('feature'),
      );
    });

    test('returns null when tag absent', () {
      expect(tagOrNullIgnoreCase('no tags', 'CATEGORY'), isNull);
    });

    test('value content preserved verbatim (not lowered)', () {
      expect(
        tagOrNullIgnoreCase('<x>HelloWorld</x>', 'X'),
        equals('HelloWorld'),
      );
    });
  });
}
