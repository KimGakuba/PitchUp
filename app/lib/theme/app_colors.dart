import 'package:flutter/material.dart';

/// PITCHUP brand palette. Keep this the single source of truth for color —
/// never hardcode a hex value in a screen/widget.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF176B45);
  static const Color darkContainer = Color(0xFF0D3527);
  static const Color accent = Color(0xFFA3E635);
  static const Color background = Color(0xFFF7F9F6);
  static const Color headings = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF374151);
  static const Color border = Color(0xFFD1D5DB);
  static const Color success = Color(0xFF219653);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC4545);

  // Text colors guaranteed to be high-contrast on [darkContainer].
  static const Color onDarkContainerWhite = Color(0xFFFFFFFF);
  static const Color onDarkContainerAccent = Color(0xFFA3E635);
  static const Color onDarkContainerMint = Color(0xFFD1FAE5);

  static const Color surface = Color(0xFFFFFFFF);
}
