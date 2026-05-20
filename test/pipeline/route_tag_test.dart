// route_tag_test.dart — RouteTag matrix.
//
// Per-variant fixture lives as an extension so adding a tag forces the
// switch arm here at compile time. Matrix iterates `RouteTag.values`
// so test surface grows automatically with the enum — no per-variant
// test function authored.

import 'package:claudart/pipeline/route_tag.dart';
import 'package:test/test.dart';

extension on RouteTag {
  /// Expected wire-format string per variant. Asserting prod against
  /// this fixture catches a rename of the wire format that doesn't
  /// propagate to either side of the contract.
  String get expectedWireTag => switch (this) {
        RouteTag.plan     => 'PLAN',
        RouteTag.question => 'QUESTION',
        RouteTag.answer   => 'ANSWER',
        RouteTag.unknown  => 'UNKNOWN',
        RouteTag.handoff  => 'HANDOFF',
        RouteTag.changes  => 'CHANGES',
      };
}

void main() {
  group('RouteTag.wireTag — one wire name per variant', () {
    for (final tag in RouteTag.values) {
      test(tag.name, () {
        expect(tag.wireTag, equals(tag.expectedWireTag));
      });
    }
  });

  group('RouteTag.wireTag — uniqueness across variants', () {
    test('no two variants share a wire name', () {
      final wireNames = RouteTag.values.map((t) => t.wireTag).toList();
      expect(wireNames.toSet().length, equals(wireNames.length));
    });

    test('every wire name is non-empty', () {
      for (final tag in RouteTag.values) {
        expect(tag.wireTag, isNotEmpty, reason: tag.name);
      }
    });
  });

  group('RouteTag.wireTag usable as runtime map key', () {
    // Documents that `RouteTag.<v>.wireTag` is fine as a key in a
    // non-const map literal. Const map literals don't compile because
    // Dart's const-evaluation rules don't allow property access on
    // const-created enum values — that's why the production maps in
    // `flow_steps.dart` and `suggest_steps.dart` are non-const at the
    // outer level (inner StepRoute values remain const).
    test('runtime map literal accepts every variant as a key', () {
      final routes = <String, int>{
        for (final tag in RouteTag.values) tag.wireTag: tag.index,
      };
      expect(routes.length, equals(RouteTag.values.length));
      for (final tag in RouteTag.values) {
        expect(routes[tag.wireTag], equals(tag.index));
      }
    });
  });
}
