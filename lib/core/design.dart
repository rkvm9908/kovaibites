import 'package:flutter/material.dart';

/// Spacing scale (8pt grid).
class Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// Corner radii.
class Radii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// Brand palette, gradients and shadows.
class Brand {
  static const primary = Color(0xFFFF5B2E);
  static const primaryDark = Color(0xFFE0431A);
  static const ink = Color(0xFF1E1B2E);
  static const cream = Color(0xFFFFF7F1);
  static const success = Color(0xFF16A34A);
  static const star = Color(0xFFFFB300);

  static const gradient = LinearGradient(
    colors: [Color(0xFFFF8A3D), Color(0xFFFF3D54)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const softShadow = [
    BoxShadow(color: Color(0x161E1B2E), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// Shared animation timings.
class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}