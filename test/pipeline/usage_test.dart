// usage_test.dart — Usage value type matrix.
//
// Every counter accumulates independently under `+`. `format()` shows
// each non-zero counter; cacheCreation renders as `cache-wr`. Tests
// cover each field in isolation so a regression in any single
// accumulation is caught.

import 'package:claudart/pipeline/usage.dart';
import 'package:test/test.dart';

const _fieldLabelCacheWrite = 'cache-wr';
const _fieldLabelCached     = 'cached';
const _fieldLabelOut        = 'out';
const _fieldLabelIn         = 'in';

void main() {
  group('Usage zero value', () {
    test('all counters are zero by default', () {
      const usage = Usage();
      expect(usage.input,         equals(0));
      expect(usage.output,        equals(0));
      expect(usage.cacheRead,     equals(0));
      expect(usage.cacheCreation, equals(0));
      expect(usage.cost,          equals(0));
    });
  });

  group('Usage + Usage accumulates every counter independently', () {
    test('input + input', () {
      final sum = const Usage(input: 10) + const Usage(input: 7);
      expect(sum.input, equals(17));
    });

    test('output + output', () {
      final sum = const Usage(output: 50) + const Usage(output: 25);
      expect(sum.output, equals(75));
    });

    test('cacheRead + cacheRead', () {
      final sum = const Usage(cacheRead: 1000) + const Usage(cacheRead: 200);
      expect(sum.cacheRead, equals(1200));
    });

    test('cacheCreation + cacheCreation', () {
      final sum = const Usage(cacheCreation: 800) +
          const Usage(cacheCreation: 150);
      expect(sum.cacheCreation, equals(950));
    });

    test('cost + cost', () {
      final sum = const Usage(cost: 0.01) + const Usage(cost: 0.02);
      expect(sum.cost, closeTo(0.03, 1e-9));
    });

    test('mixed fields accumulate together', () {
      const a = Usage(
        input: 100,
        output: 200,
        cacheRead: 300,
        cacheCreation: 400,
        cost: 1.5,
      );
      const b = Usage(
        input: 11,
        output: 22,
        cacheRead: 33,
        cacheCreation: 44,
        cost: 0.5,
      );
      final sum = a + b;
      expect(sum.input,         equals(111));
      expect(sum.output,        equals(222));
      expect(sum.cacheRead,     equals(333));
      expect(sum.cacheCreation, equals(444));
      expect(sum.cost,          closeTo(2.0, 1e-9));
    });
  });

  group('Usage.format renders non-zero counters with their labels', () {
    test('zero usage renders only in=0 + out=0', () {
      const usage = Usage();
      final formatted = usage.format();
      expect(formatted, contains('$_fieldLabelIn 0'));
      expect(formatted, contains('$_fieldLabelOut 0'));
      expect(formatted, isNot(contains(_fieldLabelCached)));
      expect(formatted, isNot(contains(_fieldLabelCacheWrite)));
    });

    test('cacheRead-only renders cached, hides cache-wr', () {
      const usage = Usage(input: 5, output: 5, cacheRead: 1024);
      final formatted = usage.format();
      expect(formatted, contains(_fieldLabelCached));
      expect(formatted, isNot(contains(_fieldLabelCacheWrite)));
    });

    test('cacheCreation-only renders cache-wr, hides cached', () {
      const usage = Usage(input: 5, output: 5, cacheCreation: 2048);
      final formatted = usage.format();
      expect(formatted, contains(_fieldLabelCacheWrite));
      expect(formatted, isNot(contains(_fieldLabelCached)));
    });

    test('both cache counters render', () {
      const usage =
          Usage(input: 5, output: 5, cacheRead: 100, cacheCreation: 200);
      final formatted = usage.format();
      expect(formatted, contains(_fieldLabelCached));
      expect(formatted, contains(_fieldLabelCacheWrite));
    });
  });

  test('Usage.toString includes every field name', () {
    const usage = Usage(
      input: 1,
      output: 2,
      cacheRead: 3,
      cacheCreation: 4,
      cost: 5,
    );
    final repr = usage.toString();
    expect(repr, contains('in:1'));
    expect(repr, contains('out:2'));
    expect(repr, contains('cached:3'));
    expect(repr, contains('cacheWrite:4'));
    expect(repr, contains(r'$5'));
  });
}
