import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../ai_analysis/models/report_card.dart';
import '../../../core/errors/app_exception.dart';

/// Service to render and export 1080x1920 Wrapped-style story cards.
class CardGenerator {
  static final ScreenshotController _screenshotController = ScreenshotController();

  /// Captures an offscreen 1080x1920 widget as PNG bytes and launches the native share sheet.
  static Future<void> shareCard({
    required BuildContext context,
    required ReportCard card,
    required String participant1,
    required String participant2,
    bool useInitials = false,
  }) async {
    try {
      final name1 = useInitials ? _toInitials(participant1) : participant1;
      final name2 = useInitials ? _toInitials(participant2) : participant2;

      final widget = _buildShareCanvas(
        card: card,
        name1: name1,
        name2: name2,
      );

      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        widget,
        targetSize: const Size(1080, 1920),
        delay: const Duration(milliseconds: 100),
      );

      final xFile = XFile.fromData(
        imageBytes,
        mimeType: 'image/png',
        name: 'chat_analysis_${card.type.name}.png',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'We just got our chat vibe-checked 🔥 #VibeCheck',
        ),
      );
    } catch (e) {
      throw StorageException('Failed to generate or share card: $e', details: e);
    }
  }

  static String _toInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static Widget _buildShareCanvas({
    required ReportCard card,
    required String name1,
    required String name2,
  }) {
    final isRoast = card.type == ReportCardType.roastMode;
    final isRed = card.type == ReportCardType.redFlags;
    final accent = isRoast
        ? AppColors.roastAccent
        : isRed
            ? const Color(0xFFEF5350)
            : AppColors.primary;
    final gradient = isRoast
        ? AppColors.roastGradient
        : isRed
            ? const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient;

    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -200,
            left: 200,
            child: Container(
              width: 700,
              height: 700,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -100,
            child: Container(
              width: 800,
              height: 800,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top App Branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: AppColors.onAccent,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'VIBE CHECK',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Participants Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: AppColors.surfaceBorder, width: 2),
                  ),
                  child: Text(
                    '$name1  ×  $name2',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const Spacer(),

                // Center Highlight Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(60),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.5),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Score Circle if applicable
                      if (card.score != null) ...[
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: gradient,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${card.score}%',
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      Text(
                        card.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        card.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        card.summary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Watermark & Call To Action
                Column(
                  children: [
                    Text(
                      'Scan or import your chat to uncover your dynamic',
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: 24,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Get your chat vibe-checked  •  Vibe Check',
                      style: AppTypography.labelLarge.copyWith(
                        fontSize: 22,
                        letterSpacing: 1.2,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
