import 'package:flutter/material.dart';

class AppPalette {
  static const Color seed = Color(0xFF1E3A8A);
  static const Color accent = Color(0xFF0EA5E9);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
}

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: AppPalette.seed,
  brightness: Brightness.light,
  surface: const Color(0xFFF7F9FC),
  secondary: AppPalette.accent,
  tertiary: const Color(0xFF7C3AED),
);

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppPalette.seed,
  brightness: Brightness.dark,
);
