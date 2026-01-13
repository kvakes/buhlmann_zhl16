/// WARNING:
/// This library is NOT a dive planner and must not be used for real-world diving.
/// For educational and experimental use only.
library;

import 'package:buhlmann_zhl16/buhlmann_zhl16.dart';

void main() {
  final plan = Plan(dives: [
    Dive(steps: [
      SquareSegment(depthMeters: 18, minutes: 40), // dive
      SurfaceInterval(minutes: 60), // SI
      SquareSegment(depthMeters: 12, minutes: 50), // repetitive dive
    ]),
  ]);

  final model = Zhl16cN2.runPlan(plan);

  print('Max PN2 (ATA): ${model.maxPn2()}');
  print('Ceiling (ATA): ${model.ceilingAmbientAta()}');
  print('Ceiling (m):   ${model.ceilingDepthMeters()}');
}
