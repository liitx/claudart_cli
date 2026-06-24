import 'package:claudart/pipeline/claude_session.dart';
import 'package:test/test.dart';

void main() {
  group('newClaudeSessionId', () {
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('is a well-formed RFC-4122 v4 UUID', () {
      for (var i = 0; i < 100; i++) {
        expect(newClaudeSessionId(), matches(uuidV4));
      }
    });

    test('is unique per call (no session collisions across runs)', () {
      final ids = {for (var i = 0; i < 1000; i++) newClaudeSessionId()};
      expect(ids.length, 1000);
    });
  });
}
