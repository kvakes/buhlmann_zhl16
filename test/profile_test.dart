import 'package:test/test.dart';
import 'package:buhlmann_zhl16/buhlmann_zhl16.dart';

void main() {
  group('SquareSegment – construction and invariants', () {
    test('constructs with valid depth and duration', () {
      final s = SquareSegment(depthMeters: 18, minutes: 40);
      fail('Not implemented');
    });

    test('depth must be non-negative', () {
      // Expect: constructor rejects negative depth
      // (either throws ArgumentError/RangeError, or asserts in debug)
      fail('Not implemented');
    });

    test('duration must be positive', () {
      // Expect: constructor rejects 0 and negative duration
      fail('Not implemented');
    });
  });

  group('SquareSegment – value semantics', () {
    test('is immutable / fields are final', () {
      // This is effectively a compile-time guarantee; keep as a “contract test”
      // or delete later if you prefer not to test language semantics.
      fail('Not implemented');
    });
  });

  group('Profile helpers – optional minimal API', () {
    test('a dive is a list of segments (if you add Dive)', () {
      // Placeholder for when you introduce:
      // class Dive { List<SquareSegment> segments; ... }
      fail('Not implemented');
    });

    test('a plan is a list of dives (if you add Plan)', () {
      // Placeholder for when you introduce:
      // class Plan { List<Dive> dives; ... }
      fail('Not implemented');
    });
  });
}
