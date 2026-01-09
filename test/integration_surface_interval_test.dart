import 'package:test/test.dart';
import 'package:buhlmann_zhl16/buhlmann_zhl16.dart';

void main() {
  group('Integration – SurfaceInterval', () {
    test('SurfaceInterval is equivalent to depth=0 square segment on air', () {
      final steps = [
        SquareSegment(depthMeters: 30, minutes: 30), // load
        SurfaceInterval(minutes: 60),                // offgas
        SquareSegment(depthMeters: 18, minutes: 40), // repetitive dive
      ];

      // Path A: domain runner (SurfaceInterval included)
      final viaRunner = Zhl16cN2.runDiveSteps(steps);

      // Path B: manually apply the equivalent physics steps
      final manual = Zhl16cN2.atSurfaceEquilibrium();
      manual.applySquareSegment(depthMeters: 30, durationMinutes: 30, fn2: 0.79);
      manual.applySquareSegment(depthMeters: 0, durationMinutes: 60, fn2: 0.79); // surface interval equivalence
      manual.applySquareSegment(depthMeters: 18, durationMinutes: 40, fn2: 0.79);

      // Compare per-compartment PN2 (integration correctness)
      expect(viaRunner.pn2.length, equals(manual.pn2.length));

      for (var i = 0; i < viaRunner.pn2.length; i++) {
        expect(
          viaRunner.pn2[i],
          closeTo(manual.pn2[i], 1e-12),
          reason: 'compartment $i',
        );
      }

      // Compare derived outputs too (optional but useful)
      expect(viaRunner.ceilingAmbientAta(), closeTo(manual.ceilingAmbientAta(), 1e-12));
      expect(viaRunner.ceilingDepthMeters(), equals(manual.ceilingDepthMeters()));
    });
  });
}
