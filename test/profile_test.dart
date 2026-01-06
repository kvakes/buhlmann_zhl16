import 'package:test/test.dart';
import 'package:buhlmann_zhl16/buhlmann_zhl16.dart';

void main() {
  group('SquareSegment – construction and invariants', () {
    test('constructs with valid depth and duration', () {
      final s = SquareSegment(depthMeters: 18, minutes: 40);

      expect(s.depthMeters, equals(18));
      expect(s.minutes, equals(40));
      expect(s.fn2, equals(0.79));
    });

    test('depth must be non-negative', () {
      expect(
        () => SquareSegment(depthMeters: -1, minutes: 10),
        throwsArgumentError,
      );
    });

    test('duration must be positive', () {
      expect(
        () => SquareSegment(depthMeters: 10, minutes: 0),
        throwsArgumentError,
      );

      expect(
        () => SquareSegment(depthMeters: 10, minutes: -5),
        throwsArgumentError,
      );
    });
  });

  group('SurfaceInterval – construction and invariants', () {
    test('constructs with positive duration', () {
      final si = SurfaceInterval(minutes: 60);
      expect(si.minutes, equals(60));
    });

    test('duration must be positive', () {
      expect(
        () => SurfaceInterval(minutes: 0),
        throwsArgumentError,
      );

      expect(
        () => SurfaceInterval(minutes: -10),
        throwsArgumentError,
      );
    });
  });

  group('Dive – aggregation semantics', () {
    test('total minutes is sum of steps', () {
      final dive = Dive(steps: [
        SquareSegment(depthMeters: 18, minutes: 40),
        SurfaceInterval(minutes: 60),
        SquareSegment(depthMeters: 12, minutes: 30),
      ]);

      expect(dive.totalMinutes, equals(130));
    });

    test('max depth considers only square segments', () {
      final dive = Dive(steps: [
        SurfaceInterval(minutes: 30),
        SquareSegment(depthMeters: 20, minutes: 25),
        SquareSegment(depthMeters: 12, minutes: 40),
      ]);

      expect(dive.maxDepthMeters, equals(20));
    });
  });

  group('Plan – aggregation semantics', () {
    test('total minutes is sum of dives', () {
      final plan = Plan(dives: [
        Dive(steps: [
          SquareSegment(depthMeters: 18, minutes: 40),
          SurfaceInterval(minutes: 60),
        ]),
        Dive(steps: [
          SquareSegment(depthMeters: 12, minutes: 50),
        ]),
      ]);

      expect(plan.totalMinutes, equals(150));
    });

    test('max depth is max across dives', () {
      final plan = Plan(dives: [
        Dive(steps: [
          SquareSegment(depthMeters: 18, minutes: 40),
        ]),
        Dive(steps: [
          SquareSegment(depthMeters: 30, minutes: 25),
        ]),
      ]);

      expect(plan.maxDepthMeters, equals(30));
    });
  });
}
