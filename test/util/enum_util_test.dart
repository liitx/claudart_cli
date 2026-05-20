// enum_util_test.dart — generic `enumByName` matrix.
//
// Test surface piggybacks on an existing closed enum (`AgentModel`)
// rather than authoring a new test-only enum. The helper is generic
// over `T extends Enum`, so coverage from any one enum's variants
// proves the contract; using `AgentModel` means renaming a model
// variant updates the test surface automatically.

import 'package:claudart/pipeline/agent_model.dart';
import 'package:claudart/util/enum_util.dart';
import 'package:test/test.dart';

void main() {
  group('enumByName round-trips every AgentModel variant', () {
    // Matrix: one row per variant, exact-case lookup.
    for (final model in AgentModel.values) {
      test(model.name, () {
        expect(enumByName(AgentModel.values, model.name), equals(model));
      });
    }
  });

  group('enumByName is case-insensitive — every variant in upper-case', () {
    for (final model in AgentModel.values) {
      test('${model.name} (uppercased input)', () {
        expect(
          enumByName(AgentModel.values, model.name.toUpperCase()),
          equals(model),
        );
      });
    }
  });

  group('enumByName returns null on absent input', () {
    test('null input returns null', () {
      expect(enumByName(AgentModel.values, null), isNull);
    });

    test('empty string returns null', () {
      expect(enumByName(AgentModel.values, ''), isNull);
    });

    test('unknown variant returns null', () {
      // Pick a string that is not any AgentModel variant name.
      expect(enumByName(AgentModel.values, 'spelunk'), isNull);
    });

    test('near-miss substring returns null', () {
      // Confirms the comparison is whole-string equality, not contains.
      final firstVariant = AgentModel.values.first.name;
      expect(
        enumByName(AgentModel.values, '${firstVariant}x'),
        isNull,
      );
    });
  });
}
