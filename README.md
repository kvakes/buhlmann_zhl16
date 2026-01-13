# buhlmann_zhl16

Nitrogen-only Bühlmann ZHL-16B tissue model utilities for dive planning.

## ⚠️ Safety & Liability Disclaimer ⚠️

This software is provided for educational, research, and experimental purposes only.

It is NOT a dive computer, decompression planner, or safety-critical system.
It is NOT suitable for real-world dive planning or execution.

Diving involves serious risk of injury or death, including decompression sickness, hypoxia, embolism, and drowning. The algorithms implemented here are incomplete, simplified, and not validated for operational use, including but not limited to:

- No ascent/descent modeling (Schreiner)
- No decompression ceilings
- No gradient factors
- No decompression schedule generation
- Nitrogen-only assumptions

*DO NOT* use this library to plan or conduct actual dives.
*DO NOT* rely on its output for safety-critical decisions.

By using this software, you acknowledge and agree that:

- You assume all risks associated with its use
- The author(s) make no warranties, express or implied
- The author(s) accept no liability for any injury, death, or damage resulting from use or misuse of this software

If you need a real dive planner or decompression model, use certified dive computers, established planning tools, and formal training from recognized agencies.

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
