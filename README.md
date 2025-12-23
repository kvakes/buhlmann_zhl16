# buhlmann_zhl16

Nitrogen-only Bühlmann ZHL-16B tissue model utilities for dive planning.

## Features
- ZHL-16B N2 compartments
- Square segments (constant depth for duration)
- No ascent/descent (Schreiner) yet
- No ceilings / gradient factors / deco schedule yet

## Usage

```dart
import 'package:buhlmann_zhl16/buhlmann_zhl16.dart';

void main() {
  final segs = [
    const SquareSegment(depthMeters: 30, durationMinutes: 20),
    const SquareSegment(depthMeters: 10, durationMinutes: 10),
  ];

  final model = Zhl16bN2.runSquareProfile(segs);
  print(model.maxPn2());
}
