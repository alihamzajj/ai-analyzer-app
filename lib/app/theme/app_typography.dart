import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Editorial typography: Space Grotesk for display/body,
/// Space Mono for small uppercase eyebrow labels.
class AppTypography {
  static const String sans = 'SpaceGrotesk';
  static const String mono = 'SpaceMono';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: sans,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.4,
    color: AppColors.textPrimary,
    height: 1.05,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: sans,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: sans,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: sans,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  /// Uppercase mono eyebrow label, e.g. "INTEREST METER".
  static const TextStyle labelSmall = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.3,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  /// Big numeric display used in meters and stat tiles.
  static TextStyle number({double size = 64, Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -size * 0.04,
        color: color,
        height: 1.0,
      );
}
