import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Vibe Check mark: a lime chat bubble holding "vibe bars", with an orange
/// check badge. Used for the launcher icon and inside the app.
class VibeLogo extends StatelessWidget {
  final double size;

  /// Paint the dark rounded tile behind the mark (false for adaptive-icon foreground).
  final bool withBackground;

  const VibeLogo({super.key, this.size = 96, this.withBackground = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: VibeLogoPainter(withBackground: withBackground)),
    );
  }
}

class VibeLogoPainter extends CustomPainter {
  final bool withBackground;

  /// Fraction of the canvas the mark occupies (adaptive icons need padding).
  final double markScale;

  VibeLogoPainter({this.withBackground = true, this.markScale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    if (withBackground) {
      final tile = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.22));
      canvas.drawRRect(tile, Paint()..color = AppColors.background);
      // Soft lime glow behind the bubble.
      canvas.drawCircle(
        Offset(s * 0.5, s * 0.46),
        s * 0.46,
        Paint()
          ..shader = RadialGradient(
            colors: [AppColors.primary.withValues(alpha: 0.28), AppColors.primary.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: Offset(s * 0.5, s * 0.46), radius: s * 0.46)),
      );
    }

    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.scale(markScale);
    canvas.translate(-s / 2, -s / 2);

    // Chat bubble with a tail at the bottom-left.
    final bubble = Rect.fromLTWH(s * 0.17, s * 0.22, s * 0.66, s * 0.5);
    final bubblePaint = Paint()..color = AppColors.primary;
    canvas.drawRRect(RRect.fromRectAndRadius(bubble, Radius.circular(s * 0.17)), bubblePaint);
    // Tail drawn separately so overlapping winding can't punch a hole.
    final tail = Path()
      ..moveTo(bubble.left + s * 0.11, bubble.bottom - s * 0.06)
      ..lineTo(bubble.left + s * 0.07, bubble.bottom + s * 0.1)
      ..quadraticBezierTo(
        bubble.left + s * 0.16,
        bubble.bottom + s * 0.05,
        bubble.left + s * 0.27,
        bubble.bottom - s * 0.01,
      )
      ..close();
    canvas.drawPath(tail, bubblePaint);

    // Vibe bars (a little level meter) inside the bubble.
    const heights = [0.34, 0.66, 1.0, 0.58, 0.3];
    final barW = s * 0.064;
    final gap = s * 0.04;
    final totalW = heights.length * barW + (heights.length - 1) * gap;
    final maxH = bubble.height * 0.56;
    var x = bubble.center.dx - totalW / 2;
    final barPaint = Paint()..color = AppColors.onAccent;
    for (final h in heights) {
      final barH = math.max(barW, maxH * h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, bubble.center.dy - barH / 2, barW, barH),
          Radius.circular(barW / 2),
        ),
        barPaint,
      );
      x += barW + gap;
    }

    // Orange check badge on the top-right of the bubble.
    final badgeC = Offset(bubble.right - s * 0.02, bubble.top + s * 0.02);
    final badgeR = s * 0.12;
    canvas.drawCircle(badgeC, badgeR + s * 0.022, Paint()..color = AppColors.background);
    canvas.drawCircle(badgeC, badgeR, Paint()..color = AppColors.secondary);
    final check = Path()
      ..moveTo(badgeC.dx - badgeR * 0.45, badgeC.dy + badgeR * 0.02)
      ..lineTo(badgeC.dx - badgeR * 0.1, badgeC.dy + badgeR * 0.36)
      ..lineTo(badgeC.dx + badgeR * 0.5, badgeC.dy - badgeR * 0.34);
    canvas.drawPath(
      check,
      Paint()
        ..color = AppColors.onAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.034
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(VibeLogoPainter old) =>
      old.withBackground != withBackground || old.markScale != markScale;
}
