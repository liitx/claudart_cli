// debug_mode_test.dart — runtime flag × env var matrix.
//
// Both sources must OR together. Tests inject the env map directly so
// they never depend on the host environment.

import 'package:claudart/pipeline/debug_mode.dart';
import 'package:test/test.dart';

void main() {
  // Tests reset the runtime flag between cases — it's a process-level
  // global mutated by the CLI, and leaking state between tests would
  // mask bugs.
  tearDown(() => setDebugEnabled(false));

  // ── exported constants ────────────────────────────────────────────────────

  group('exported constants', () {
    test('CLAUDART_DEBUG is the env var name', () {
      expect(kClaudartDebugEnvVar, equals('CLAUDART_DEBUG'));
    });

    test('CLAUDART_DEBUG_PATH is the path-override env var name', () {
      expect(kClaudartDebugPathEnvVar, equals('CLAUDART_DEBUG_PATH'));
    });

    test('enabled value is "1"', () {
      expect(kClaudartDebugEnabledValue, equals('1'));
    });

    test('default log path is non-empty + .log-suffixed', () {
      expect(kDefaultClaudartDebugLogPath, isNotEmpty);
      expect(kDefaultClaudartDebugLogPath, endsWith('.log'));
    });
  });

  // ── debugEnabled matrix: (runtime × env) → expected ─────────────────────

  group('debugEnabled — runtime × env matrix', () {
    final cases = <(bool runtime, String? envValue, bool expected)>[
      (false, null,                            false), // both off
      (false, '0',                             false), // env set but not "1"
      (false, '',                              false), // env empty
      (false, 'true',                          false), // env truthy-looking but not "1"
      (true,  null,                            true),  // runtime only
      (false, kClaudartDebugEnabledValue,      true),  // env only
      (true,  kClaudartDebugEnabledValue,      true),  // both on
      (true,  '0',                             true),  // runtime overrides env=0
    ];

    for (final (runtime, envValue, expected) in cases) {
      test('runtime=$runtime  env="${envValue ?? '<unset>'}" → $expected', () {
        setDebugEnabled(runtime);
        final env = envValue == null
            ? <String, String>{}
            : {kClaudartDebugEnvVar: envValue};
        expect(debugEnabled(environment: env), equals(expected));
      });
    }
  });

  // ── debugLogFile path resolution ─────────────────────────────────────────

  group('debugLogFile — path resolution', () {
    test('returns null when debug is off', () {
      setDebugEnabled(false);
      expect(debugLogFile(environment: const {}), isNull);
    });

    test('returns default-path file when runtime flag is on', () {
      setDebugEnabled(true);
      final file = debugLogFile(environment: const {});
      expect(file, isNotNull);
      expect(file!.path, equals(kDefaultClaudartDebugLogPath));
    });

    test('honors CLAUDART_DEBUG_PATH override when set', () {
      setDebugEnabled(true);
      const overridePath = '/tmp/custom_claudart_debug.log';
      final file = debugLogFile(
        environment: const {kClaudartDebugPathEnvVarLiteral: overridePath},
      );
      expect(file, isNotNull);
      expect(file!.path, equals(overridePath));
    });

    test('env-only enable (no runtime flag) still produces a file', () {
      setDebugEnabled(false);
      final file = debugLogFile(
        environment: const {kClaudartDebugEnvVarLiteral: '1'},
      );
      expect(file, isNotNull);
      expect(file!.path, equals(kDefaultClaudartDebugLogPath));
    });
  });

  // ── setDebugEnabled is idempotent for tests ──────────────────────────────

  test('setDebugEnabled(false) clears the runtime flag', () {
    setDebugEnabled(true);
    expect(debugEnabled(environment: const {}), isTrue);
    setDebugEnabled(false);
    expect(debugEnabled(environment: const {}), isFalse);
  });
}

// ── Literal env-var name aliases used only by the path-override case ──────
//
// Map literals require const keys; importing them as `const` symbols
// from the production file produces compile-time-const maps without
// duplicating the string. If the production const renames, these
// references break the test at compile time — the desired coupling.

const String kClaudartDebugEnvVarLiteral = kClaudartDebugEnvVar;
const String kClaudartDebugPathEnvVarLiteral = kClaudartDebugPathEnvVar;
