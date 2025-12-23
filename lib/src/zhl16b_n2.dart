import 'dart:math' as math;

import 'profile.dart';

/// Nitrogen-only Bühlmann ZHL-16B tissue model (no helium, no GF, no deco stops yet).
///
/// Units:
/// - Pressures in ATA
/// - Time in minutes
/// - Depth in meters
///
/// Safety note:
/// This package is for educational/research/planning use. It is not a dive computer.
class Zhl16bN2 {
  /// Air nitrogen fraction (assumption).
  static const double fn2Air = 0.79;

  /// Water vapor pressure in ATA (approx at 37°C).
  static const double waterVaporAta = 0.0627;

  /// Ambient pressure in ATA at a given depth in meters (simple seawater approximation).
  static double ambientAtaAtDepthMeters(int depthMeters) =>
      1.0 + (depthMeters / 10.0);

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

  /// ZHL-16B N2 compartment constants.
  static const List<_Comp> comps = [
    _Comp(halfTimeMin: 4.0, a: 1.2599, b: 0.5050),
    _Comp(halfTimeMin: 8.0, a: 1.0000, b: 0.6514),
    _Comp(halfTimeMin: 12.5, a: 0.8618, b: 0.7222),
    _Comp(halfTimeMin: 18.5, a: 0.7562, b: 0.7825),
    _Comp(halfTimeMin: 27.0, a: 0.6667, b: 0.8126),
    _Comp(halfTimeMin: 38.3, a: 0.5933, b: 0.8434),
    _Comp(halfTimeMin: 54.3, a: 0.5282, b: 0.8693),
    _Comp(halfTimeMin: 77.0, a: 0.4701, b: 0.8910),
    _Comp(halfTimeMin: 109.0, a: 0.4187, b: 0.9092),
    _Comp(halfTimeMin: 146.0, a: 0.3798, b: 0.9222),
    _Comp(halfTimeMin: 187.0, a: 0.3497, b: 0.9319),
    _Comp(halfTimeMin: 239.0, a: 0.3223, b: 0.9403),
    _Comp(halfTimeMin: 305.0, a: 0.2971, b: 0.9477),
    _Comp(halfTimeMin: 390.0, a: 0.2737, b: 0.9544),
    _Comp(halfTimeMin: 498.0, a: 0.2523, b: 0.9602),
    _Comp(halfTimeMin: 635.0, a: 0.2327, b: 0.9653),
  ];

  /// Tissue N2 pressures (ATA) for 16 compartments.
  final List<double> pn2;

  Zhl16bN2._(this.pn2);

  /// Initialize compartments at surface equilibrium breathing air.
  factory Zhl16bN2.atSurfaceEquilibrium({double fn2 = fn2Air}) {
    final pIn2 = inspiredN2Ata(ambientAta: 1.0, fn2: fn2);
    return Zhl16bN2._(List<double>.filled(16, pIn2));
  }

  Zhl16bN2 copy() => Zhl16bN2._(List<double>.from(pn2));

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

  /// Run a list of square segments starting from surface equilibrium.
  static Zhl16bN2 runSquareProfile(
    Iterable<SquareSegment> segments, {
    double fn2 = fn2Air,
  }) {
    final model = Zhl16bN2.atSurfaceEquilibrium(fn2: fn2);
    for (final s in segments) {
      model.applySquareSegment(
        depthMeters: s.depthMeters,
        durationMinutes: s.durationMinutes,
        fn2: fn2,
      );
    }
    return model;
  }

  /// Convenience: maximum compartment PN2 (ATA).
  double maxPn2() => pn2.reduce((a, b) => a > b ? a : b);
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
