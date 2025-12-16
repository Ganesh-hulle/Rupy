import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme buildTextTheme(ColorScheme scheme) {
  final base = GoogleFonts.manropeTextTheme();
  return base.copyWith(
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    bodyMedium: base.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );
}
