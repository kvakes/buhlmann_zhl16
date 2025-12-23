import 'package:test/test.dart';
import 'package:buhlmann_zhl16/buhlmann_zhl16.dart';

void main() {
  test('Surface equilibrium PN2 is stable', () {
    final m = Zhl16bN2.atSurfaceEquilibrium();
    final before = List<double>.from(m.pn2);

    // 60 minutes at surface breathing air should remain at equilibrium.
    m.applySquareSegment(depthMeters: 0, durationMinutes: 60);

    for (var i = 0; i < 16; i++) {
      expect((m.pn2[i] - before[i]).abs() < 1e-9, isTrue);
    }
  });

  test('PN2 increases during bottom time at depth', () {
    final m = Zhl16bN2.atSurfaceEquilibrium();
    final beforeMax = m.maxPn2();

    m.applySquareSegment(depthMeters: 30, durationMinutes: 20);

    expect(m.maxPn2(), greaterThan(beforeMax));
  });

  test('Running a profile equals applying segments sequentially', () {
    final segs = [
      const SquareSegment(depthMeters: 18, durationMinutes: 20),
      const SquareSegment(depthMeters: 10, durationMinutes: 10),
    ];

    final a = Zhl16bN2.runSquareProfile(segs);

    final b = Zhl16bN2.atSurfaceEquilibrium();
    for (final s in segs) {
      b.applySquareSegment(
          depthMeters: s.depthMeters, durationMinutes: s.durationMinutes);
    }

    for (var i = 0; i < 16; i++) {
      expect((a.pn2[i] - b.pn2[i]).abs() < 1e-12, isTrue);
    }
  });
}
