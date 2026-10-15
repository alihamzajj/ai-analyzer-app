import 'package:flutter/material.dart';

/// Centralized color palette for AI Chat Analyser.
/// "Chat Wrapped" aesthetic: deep forest-black surfaces with
/// an electric lime primary and a hot orange secondary.
class AppColors {
  // Surface & Background Colors
  static const Color background = Color(0xFF0A1410);
  static const Color surface = Color(0xFF10201A);
  static const Color surfaceElevated = Color(0xFF13251D);
  static const Color surfaceCard = Color(0xFF13251D);
  static const Color surfaceBorder = Color(0xFF223A2E);

  // Core Brand Accents
  static const Color primary = Color(0xFFCDF24A); // Electric Lime
  static const Color primaryLight = Color(0xFFDDF77F);
  static const Color primaryDark = Color(0xFF9DBD25);

  static const Color secondary = Color(0xFFFF7A35); // Hot Orange
  static const Color accentCyan = Color(0xFF5ED6C1);
  static const Color accentAmber = Color(0xFFFFC145);
  static const Color accentGreen = Color(0xFFCDF24A);
  static const Color accentRed = Color(0xFFFF5A4E);

  /// Ink used for text/icons placed on lime or orange fills.
  static const Color onAccent = Color(0xFF0A1410);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F2E8);
  static const Color textSecondary = Color(0xFF9DAEA3);
  static const Color textMuted = Color(0xFF6E8276);
  static const Color textDisabled = Color(0xFF4A5C51);

  // Analysis Modes Accents
  static const Color romanceAccent = Color(0xFFFF7A35);
  static const Color friendshipAccent = Color(0xFFCDF24A);
  static const Color groupAccent = Color(0xFF5ED6C1);
  static const Color roastAccent = Color(0xFFFF7A35);

  // Gradients (kept flat-ish to match the solid-block style)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFCDF24A), Color(0xFFB8E03A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roastGradient = LinearGradient(
    colors: [Color(0xFFFF7A35), Color(0xFFFF5A4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x33CDF24A), Color(0x110A1410)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
