import 'dart:math' as math;

import 'profile.dart';

/// Nitrogen-only Bühlmann ZHL-16C tissue model (no helium, no GF, no deco stops).
///
/// Units:
/// - Pressures in ATA
/// - Time in minutes
/// - Depth in meters
///
/// Safety note:
/// This package is for educational/research/planning use. It is not a dive computer.
class Zhl16cN2 {
  /// Air nitrogen fraction (approx).
  static const double fn2Air = 0.79;

  /// Water vapor pressure in ATA (approx at 37°C).
  static const double waterVaporAta = 0.0627;

  /// Ambient pressure in ATA at a given depth in meters (simple seawater approximation).
  /// 10 m seawater ≈ +1 ATA.
  static double ambientAtaAtDepthMeters(int depthMeters) => 1.0 + (depthMeters / 10.0);

  /// Inspired nitrogen pressure (ATA), simplified alveolar model:
  /// P_iN2 = (P_amb - P_H2O) * FN2
  static double inspiredN2Ata({
    required double ambientAta,
    double fn2 = fn2Air,
    double ph2oAta = waterVaporAta,
  }) {
    final dryGasAta = math.max(0.0, ambientAta - ph2oAta);
    return dryGasAta * fn2;
  }

  /// ZHL-16C N2 compartment constants.
  ///
  /// Source (commonly used reference implementation):
  /// Subsurface deco.cpp
  static const List<_Comp> comps = [
    _Comp(halfTimeMin: 5.0, a: 1.1696, b: 0.5578),
    _Comp(halfTimeMin: 8.0, a: 1.0, b: 0.6514),
    _Comp(halfTimeMin: 12.5, a: 0.8618, b: 0.7222),
    _Comp(halfTimeMin: 18.5, a: 0.7562, b: 0.7825),
    _Comp(halfTimeMin: 27.0, a: 0.62, b: 0.8126),
    _Comp(halfTimeMin: 38.3, a: 0.5043, b: 0.8434),
    _Comp(halfTimeMin: 54.3, a: 0.441, b: 0.8693),
    _Comp(halfTimeMin: 77.0, a: 0.4, b: 0.8910),
    _Comp(halfTimeMin: 109.0, a: 0.375, b: 0.9092),
    _Comp(halfTimeMin: 146.0, a: 0.35, b: 0.9222),
    _Comp(halfTimeMin: 187.0, a: 0.3295, b: 0.9319),
    _Comp(halfTimeMin: 239.0, a: 0.3065, b: 0.9403),
    _Comp(halfTimeMin: 305.0, a: 0.2835, b: 0.9477),
    _Comp(halfTimeMin: 390.0, a: 0.261, b: 0.9544),
    _Comp(halfTimeMin: 498.0, a: 0.248, b: 0.9602),
    _Comp(halfTimeMin: 635.0, a: 0.2327, b: 0.9653),
  ];

  /// Tissue N2 pressures (ATA) for 16 compartments.
  final List<double> pn2;

  Zhl16cN2._(this.pn2);

  /// Initialize compartments at surface equilibrium breathing a gas with [fn2].
  factory Zhl16cN2.atSurfaceEquilibrium({double fn2 = fn2Air}) {
    final pIn2 = inspiredN2Ata(ambientAta: 1.0, fn2: fn2);
    return Zhl16cN2._(List<double>.filled(16, pIn2));
  }

  Zhl16cN2 copy() => Zhl16cN2._(List<double>.from(pn2));

  /// Apply a constant-depth exposure (square segment).
  ///
  /// P(t) = P_i + (P0 - P_i) * e^(-k t)
  /// where k = ln(2)/halfTime
  void applySquareSegment({
    required int depthMeters,
    required int durationMinutes,
    double fn2 = fn2Air,
  }) {
    if (durationMinutes <= 0) return;

    final pAmb = ambientAtaAtDepthMeters(depthMeters);
    final pIn2 = inspiredN2Ata(ambientAta: pAmb, fn2: fn2);

    final t = durationMinutes.toDouble();
    for (var i = 0; i < 16; i++) {
      final k = math.ln2 / comps[i].halfTimeMin;
      final p0 = pn2[i];
      pn2[i] = pIn2 + (p0 - pIn2) * math.exp(-k * t);
    }
  }

  /// Returns per-compartment minimum allowable ambient pressure (ATA),
  /// i.e. the decompression ceiling expressed as ambient pressure.
  ///
  /// Using Bühlmann M-line: Pt <= A + B * Pamb
  /// Rearranged for ceiling: Pamb >= (Pt - A) / B
  List<double> ceilingAmbientAtaPerCompartment() {
    assert(pn2.length == comps.length);
    final out = List<double>.filled(16, 0.0);
    for (var i = 0; i < 16; i++) {
      final pt = pn2[i];
      final a = comps[i].a;
      final b = comps[i].b;
      out[i] = (pt - a) / b;
    }
    return out;
  }

  /// Overall ceiling as ambient pressure (ATA): max over compartments.
  double ceilingAmbientAta() {
    final per = ceilingAmbientAtaPerCompartment();
    return per.reduce((x, y) => x > y ? x : y);
  }

  /// Overall ceiling as depth in meters (rounded up).
  int ceilingDepthMeters() {
    final pamb = ceilingAmbientAta();
    final depth = (pamb - 1.0) * 10.0;
    if (depth <= 0) return 0;
    return depth.ceil();
  }

  /// Convenience: maximum compartment PN2 (ATA).
  double maxPn2() => pn2.reduce((a, b) => a > b ? a : b);

  // ---------------------------------------------------------------------------
  // Runners (Profile/Dive/Plan)
  // ---------------------------------------------------------------------------

  /// Run a list of [SquareSegment]s starting from surface equilibrium.
  ///
  /// By default, each segment uses its own [SquareSegment.fn2].
  /// If [fn2Override] is provided, it overrides every segment's fn2.
  static Zhl16cN2 runSquareProfile(
    Iterable<SquareSegment> segments, {
    double? fn2Override,
  }) {
    final model = Zhl16cN2.atSurfaceEquilibrium(fn2: fn2Air);

    for (final s in segments) {
      model.applySquareSegment(
        depthMeters: s.depthMeters,
        durationMinutes: s.minutes,
        fn2: fn2Override ?? s.fn2,
      );
    }

    return model;
  }

  /// Run a sequence of [DiveStep]s (square segments + surface intervals)
  /// starting from surface equilibrium.
  ///
  /// Semantics:
  /// - SquareSegment: uses segment.fn2
  /// - SurfaceInterval: treated as depth=0 breathing air (fn2Air)
  static Zhl16cN2 runDiveSteps(Iterable<DiveStep> steps) {
    final model = Zhl16cN2.atSurfaceEquilibrium(fn2: fn2Air);

    for (final step in steps) {
      if (step is SquareSegment) {
        model.applySquareSegment(
          depthMeters: step.depthMeters,
          durationMinutes: step.minutes,
          fn2: step.fn2,
        );
      } else if (step is SurfaceInterval) {
        model.applySquareSegment(
          depthMeters: 0,
          durationMinutes: step.minutes,
          fn2: fn2Air,
        );
      } else {
        throw StateError('Unknown DiveStep type: ${step.runtimeType}');
      }
    }

    return model;
  }

  /// Run a single [Dive] starting from surface equilibrium.
  static Zhl16cN2 runDive(Dive dive) => runDiveSteps(dive.steps);

  /// Run an entire [Plan] sequentially starting from surface equilibrium.
  static Zhl16cN2 runPlan(Plan plan) {
    final model = Zhl16cN2.atSurfaceEquilibrium(fn2: fn2Air);

    for (final dive in plan.dives) {
      for (final step in dive.steps) {
        if (step is SquareSegment) {
          model.applySquareSegment(
            depthMeters: step.depthMeters,
            durationMinutes: step.minutes,
            fn2: step.fn2,
          );
        } else if (step is SurfaceInterval) {
          model.applySquareSegment(
            depthMeters: 0,
            durationMinutes: step.minutes,
            fn2: fn2Air,
          );
        } else {
          throw StateError('Unknown DiveStep type: ${step.runtimeType}');
        }
      }
    }

    return model;
  }
}

class _Comp {
  final double halfTimeMin;
  final double a;
  final double b;

  const _Comp({
    required this.halfTimeMin,
    required this.a,
    required this.b,
  });
}
