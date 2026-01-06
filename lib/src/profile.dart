// Domain models for a minimal recreational dive planning library.
//
// Conventions:
// - Depth in meters (>= 0)
// - Duration in minutes (> 0)
// - Gas fraction values are 0..1
//
// Surface intervals are represented explicitly as [SurfaceInterval] steps.

// A step within a dive timeline.
sealed class DiveStep {
  const DiveStep();

  // Duration in minutes (> 0).
  int get minutes;
}

// A constant-depth segment (square profile piece).
final class SquareSegment extends DiveStep {
  final int depthMeters;
  @override
  final int minutes;
  final double fn2;

  SquareSegment({
    required this.depthMeters,
    required this.minutes,
    this.fn2 = 0.79,
  }) {
    if (depthMeters < 0) {
      throw ArgumentError.value(depthMeters, 'depthMeters', 'Must be >= 0.');
    }
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be > 0.');
    }
    if (fn2 <= 0.0 || fn2 > 1.0) {
      throw ArgumentError.value(fn2, 'fn2', 'Must be > 0 and <= 1.');
    }
  }
}

// A surface interval (time at 0 meters).
final class SurfaceInterval extends DiveStep {
  @override
  final int minutes;

  SurfaceInterval({required this.minutes}) {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be > 0.');
    }
  }
}

// A single dive timeline composed of sequential [DiveStep]s.
//
// Note: With explicit surface intervals, a "Plan" can be a single [Dive]
// containing multiple steps, or you can still group steps into multiple [Dive]s
// depending on your UI. The model supports both.
final class Dive {
  final List<DiveStep> steps;

  Dive({required List<DiveStep> steps}) : steps = List.unmodifiable(steps) {
    if (this.steps.isEmpty) {
      throw ArgumentError.value(
          steps, 'steps', 'A dive must have at least one step.');
    }
  }

  int get totalMinutes => steps.fold<int>(0, (sum, s) => sum + s.minutes);

  // Max depth among square segments; surface intervals contribute 0.
  int get maxDepthMeters => steps.fold<int>(0, (m, s) {
        if (s is SquareSegment) {
          return s.depthMeters > m ? s.depthMeters : m;
        }
        return m;
      });

  @override
  String toString() =>
      'Dive(steps: ${steps.length}, totalMinutes: $totalMinutes, maxDepthMeters: $maxDepthMeters)';
}

// A plan composed of sequential dives.
//
// Surface intervals can be placed:
// - inside a Dive (as [SurfaceInterval] steps), and/or
// - between Dives (as a dedicated Dive containing only a [SurfaceInterval]),
// depending on your chosen UX. This library does not enforce either.
final class Plan {
  final List<Dive> dives;

  Plan({required List<Dive> dives}) : dives = List.unmodifiable(dives) {
    if (this.dives.isEmpty) {
      throw ArgumentError.value(
          dives, 'dives', 'A plan must have at least one dive.');
    }
  }

  int get totalMinutes => dives.fold<int>(0, (sum, d) => sum + d.totalMinutes);

  int get maxDepthMeters =>
      dives.fold<int>(0, (m, d) => d.maxDepthMeters > m ? d.maxDepthMeters : m);

  @override
  String toString() =>
      'Plan(dives: ${dives.length}, totalMinutes: $totalMinutes, maxDepthMeters: $maxDepthMeters)';
}
