import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:buhlmann_zhl16/buhlmann_zhl16.dart';

void main() {
  group('Zhl16cN2 – initialization', () {
    test('surface equilibrium initializes 16 compartments', () {
      final model = Zhl16cN2.atSurfaceEquilibrium();
      expect(model.pn2, hasLength(16));
    });

    test('surface equilibrium breathing air has no decompression ceiling', () {
      final model = Zhl16cN2.atSurfaceEquilibrium();

      expect(model.ceilingDepthMeters(), equals(0));
      expect(model.ceilingAmbientAta(), lessThanOrEqualTo(1.0));
    });
  });

  group('Zhl16cN2 – square segment kinetics', () {
    test('square segment at depth increases tissue PN2', () {
      final model = Zhl16cN2.atSurfaceEquilibrium();

      final before = List<double>.from(model.pn2);

      model.applySquareSegment(depthMeters: 30, durationMinutes: 10);

      // At 30m, inspired N2 is higher than surface equilibrium, so all compartments
      // should move upward (on-gas).
      for (var i = 0; i < model.pn2.length; i++) {
        expect(model.pn2[i], greaterThan(before[i]), reason: 'compartment $i');
      }
    });

    test('tissue loading does not exceed inspired N2 at constant depth', () {
      final model = Zhl16cN2.atSurfaceEquilibrium();

      const depth = 30;
      const minutes = 30;

      final pAmb = Zhl16cN2.ambientAtaAtDepthMeters(depth);
      final pIn2 = Zhl16cN2.inspiredN2Ata(ambientAta: pAmb);

      model.applySquareSegment(depthMeters: depth, durationMinutes: minutes);

      // For a constant inspired pressure, the exponential approach should not overshoot.
      for (var i = 0; i < model.pn2.length; i++) {
        expect(model.pn2[i], lessThanOrEqualTo(pIn2 + 1e-12),
            reason: 'compartment $i');
      }
    });

    test('constant-depth exposure follows Bühlmann exponential kinetics', () {
      final model = Zhl16cN2.atSurfaceEquilibrium();

      const depth = 30;
      const minutes = 1000; // realistic long exposure, not full saturation

      final p0 = List<double>.from(model.pn2);

      final pAmb = Zhl16cN2.ambientAtaAtDepthMeters(depth);
      final pIn2 = Zhl16cN2.inspiredN2Ata(ambientAta: pAmb);

      model.applySquareSegment(depthMeters: depth, durationMinutes: minutes);

      final t = minutes.toDouble();

      for (var i = 0; i < model.pn2.length; i++) {
        final halfTime = Zhl16cN2.comps[i].halfTimeMin;
        final k = math.ln2 / halfTime;

        final expected = pIn2 + (p0[i] - pIn2) * math.exp(-k * t);

        expect(
          model.pn2[i],
          closeTo(expected, 1e-12),
          reason: 'compartment $i',
        );
      }
    });
  });

  group('Zhl16cN2 – offgassing and surface intervals', () {
    test('surface interval after deep dive reduces tissue PN2', () {
      final model = Zhl16cN2.atSurfaceEquilibrium();

      // Load tissues at depth.
      model.applySquareSegment(depthMeters: 30, durationMinutes: 30);
      final loaded = List<double>.from(model.pn2);

      // Surface interval (offgassing).
      model.applySquareSegment(depthMeters: 0, durationMinutes: 60);

      for (var i = 0; i < model.pn2.length; i++) {
        expect(
          model.pn2[i],
          lessThan(loaded[i]),
          reason: 'compartment $i',
        );
      }
    });

    test(
        'surface interval does not undershoot (not less than) surface inspired N2',
        () {
      final model = Zhl16cN2.atSurfaceEquilibrium();

      model.applySquareSegment(depthMeters: 30, durationMinutes: 30);

      final loaded = List<double>.from(model.pn2);

      // Long surface interval.
      model.applySquareSegment(depthMeters: 0, durationMinutes: 240);

      final pSurfaceIn2 = Zhl16cN2.inspiredN2Ata(ambientAta: 1.0);

      for (var i = 0; i < model.pn2.length; i++) {
        // It should have decreased (offgassed)…
        expect(model.pn2[i], lessThan(loaded[i]), reason: 'compartment $i');

        // …but should not undershoot the equilibrium inspired N2 at the surface.
        expect(
          model.pn2[i],
          greaterThanOrEqualTo(pSurfaceIn2 - 1e-12),
          reason: 'compartment $i',
        );
      }
    });
  });

  group('Zhl16cN2 – decompression ceiling', () {
    test('aggressive exposure produces a non-zero ceiling', () {
      final model = Zhl16cN2.atSurfaceEquilibrium();

      model.applySquareSegment(depthMeters: 40, durationMinutes: 40);

      // A real ceiling means required ambient pressure is > surface pressure.
      expect(model.ceilingAmbientAta(), greaterThan(1.0));

      // And therefore the depth ceiling (rounded up) must be > 0 m.
      expect(model.ceilingDepthMeters(), greaterThan(0));
    });

    test('ceiling decreases after offgassing at surface', () {
      final model = Zhl16cN2.atSurfaceEquilibrium();

      // Load enough to create a ceiling.
      model.applySquareSegment(depthMeters: 40, durationMinutes: 40);

      final ceilingAtaLoaded = model.ceilingAmbientAta();
      final ceilingDepthLoaded = model.ceilingDepthMeters();

      expect(ceilingAtaLoaded, greaterThan(1.0));
      expect(ceilingDepthLoaded, greaterThan(0));

      // Offgas at surface.
      model.applySquareSegment(depthMeters: 0, durationMinutes: 120);

      final ceilingAtaAfter = model.ceilingAmbientAta();
      final ceilingDepthAfter = model.ceilingDepthMeters();

      expect(ceilingAtaAfter, lessThanOrEqualTo(ceilingAtaLoaded + 1e-12));
      expect(ceilingDepthAfter, lessThanOrEqualTo(ceilingDepthLoaded));
    });
    test('overall ceiling equals max of per-compartment ceilings', () {
      final model = Zhl16cN2.atSurfaceEquilibrium();

      model.applySquareSegment(depthMeters: 40, durationMinutes: 40);

      final per = model.ceilingAmbientAtaPerCompartment();
      final overall = model.ceilingAmbientAta();

      // Manual max to keep the test explicit.
      var maxPer = per.first;
      for (var i = 1; i < per.length; i++) {
        if (per[i] > maxPer) maxPer = per[i];
      }

      expect(overall, closeTo(maxPer, 1e-12));
    });
  });

  group('Zhl16cN2 – repetitive dive behavior', () {
    test('repetitive dive has higher tissue loading than fresh dive', () {
      // Dive 2 (the dive we compare in both scenarios)
      final dive2 = [SquareSegment(depthMeters: 18, minutes: 40)];

      // Fresh start: only dive 2
      final fresh = Zhl16cN2.runSquareProfile(dive2);

      // Repetitive: dive 1 + surface interval + dive 2
      final repetitive = Zhl16cN2.atSurfaceEquilibrium();
      repetitive.applySquareSegment(
          depthMeters: 30, durationMinutes: 25); // dive 1
      repetitive.applySquareSegment(
          depthMeters: 0, durationMinutes: 60); // surface interval
      repetitive.applySquareSegment(
          depthMeters: 18, durationMinutes: 40); // dive 2

      // Repetitive should have higher remaining inert gas loading.
      expect(repetitive.maxPn2(), greaterThan(fresh.maxPn2()));

      // Optional secondary check: ceiling should be at least as restrictive.
      expect(
        repetitive.ceilingAmbientAta(),
        greaterThanOrEqualTo(fresh.ceilingAmbientAta() - 1e-12),
      );
    });
  });
}
