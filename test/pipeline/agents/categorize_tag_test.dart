// categorize_tag_test.dart — CategorizeTag enum matrix.
//
// One row per variant: wire format + extractFrom round-trip.
// Adding a new tag forces a new arm here at compile time.

import 'package:claudart/pipeline/agents/categorization.dart';
import 'package:test/test.dart';

extension on CategorizeTag {
  /// Expected wire-format name per variant. Asserting prod against this
  /// fixture catches a rename of the wire format that doesn't propagate
  /// to either side of the contract.
  String get expectedWireTag => switch (this) {
        CategorizeTag.category   => 'CATEGORY',
        CategorizeTag.intent     => 'INTENT',
        CategorizeTag.complexity => 'COMPLEXITY',
        CategorizeTag.model      => 'MODEL',
      };
}

void main() {
  group('CategorizeTag.wireTag — one wire name per variant', () {
    for (final tag in CategorizeTag.values) {
      test(tag.name, () {
        expect(tag.wireTag, equals(tag.expectedWireTag));
      });
    }
  });

  group('CategorizeTag.wireTag — names are unique across variants', () {
    test('no two variants share a wire name', () {
      final wireNames =
          CategorizeTag.values.map((t) => t.wireTag).toList();
      expect(wireNames.toSet().length, equals(wireNames.length));
    });
  });

  group('CategorizeTag.extractFrom normalizes empty content to null', () {
    for (final tag in CategorizeTag.values) {
      test('${tag.name} with empty body returns null', () {
        final raw = '<${tag.wireTag}></${tag.wireTag}>';
        expect(tag.extractFrom(raw), isNull);
      });

      test('${tag.name} with whitespace-only body returns null', () {
        final raw = '<${tag.wireTag}>   \n  </${tag.wireTag}>';
        expect(tag.extractFrom(raw), isNull);
      });
    }
  });

  group('CategorizeTag.extractFrom — round-trip per variant', () {
    for (final tag in CategorizeTag.values) {
      test('${tag.name} extracts its own tagged content', () {
        const content = 'value-for-test';
        final raw = '<${tag.wireTag}>$content</${tag.wireTag}>';
        expect(tag.extractFrom(raw), equals(content));
      });

      test('${tag.name} returns null when absent', () {
        // Use a tag-shaped string that is NOT this variant's wire tag.
        const otherTagged = '<UNRELATED>x</UNRELATED>';
        expect(tag.extractFrom(otherTagged), isNull);
      });

      test('${tag.name} extracts despite lower-case tag (LLM tolerance)',
          () {
        const content = 'value';
        final raw =
            '<${tag.wireTag.toLowerCase()}>$content</${tag.wireTag.toLowerCase()}>';
        expect(tag.extractFrom(raw), equals(content));
      });
    }
  });
}
