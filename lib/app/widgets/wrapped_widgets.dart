import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'motion.dart';

/// Shared building blocks for the "Chat Wrapped" visual language.

final NumberFormat _thousands = NumberFormat.decimalPattern('en_US');

String formatCount(num value) => _thousands.format(value);

/// Formats minutes as a compact duration: 4m, 2h, 3d.
String formatMinutes(double? minutes) {
  if (minutes == null || minutes.isNaN || minutes <= 0) return '—';
  if (minutes < 1) return '<1m';
  if (minutes < 60) return '${minutes.round()}m';
  if (minutes < 60 * 24) return '${(minutes / 60).round()}h';
  return '${(minutes / (60 * 24)).round()}d';
}

/// Up to two-letter initials from a display name.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/// Round outlined icon button used in headers (back, settings).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const CircleIconButton({super.key, required this.icon, required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.surfaceElevated,
      shape: const CircleBorder(side: BorderSide(color: AppColors.surfaceBorder)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Small mono pill, filled or outlined.
class WrappedPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final Color? textColor;
  final bool compact;

  const WrappedPill({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.filled = true,
    this.textColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14, vertical: compact ? 4 : 7),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: filled ? color : (textColor ?? color), width: 1.2),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: textColor ?? (filled ? AppColors.onAccent : color),
          fontSize: compact ? 11 : 12,
          letterSpacing: compact ? 0.4 : 0.8,
        ),
      ),
    );
  }
}

/// Rounded dark card with the standard border.
class WrappedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  const WrappedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.color = AppColors.surfaceCard,
    this.borderColor = AppColors.surfaceBorder,
    this.radius = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!),
    );
    final card = Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

/// Compact metric tile: big colored value + small caption.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return WrappedCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.number(size: 26, color: valueColor)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Two-sided split bar ("Who texts first", message balance).
class SplitBarCard extends StatelessWidget {
  final String title;
  final String trailingLabel;
  final String leftName;
  final String rightName;
  final int leftValue;
  final int rightValue;

  const SplitBarCard({
    super.key,
    required this.title,
    required this.trailingLabel,
    required this.leftName,
    required this.rightName,
    required this.leftValue,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    final total = leftValue + rightValue;
    final leftPct = total == 0 ? 50 : (leftValue * 100 / total).round();
    final rightPct = 100 - leftPct;

    return WrappedCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(trailingLabel, style: AppTypography.labelSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: math.max(leftPct, 4),
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: math.max(rightPct, 4),
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$leftName $leftPct%',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$rightName $rightPct%',
                  textAlign: TextAlign.right,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.secondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular 0–100 gauge with a big number in the middle.
class ScoreRing extends StatelessWidget {
  final int? score;
  final double size;
  final String caption;

  const ScoreRing({super.key, required this.score, this.size = 220, this.caption = 'OUT OF 100'});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (score ?? 0).clamp(0, 100) / 100),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(progress: value),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score == null ? '—' : '${(value * 100).round()}',
                    style: AppTypography.number(size: size * 0.36),
                  ),
                  const SizedBox(height: 6),
                  Text(caption, style: AppTypography.labelSmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress <= 0) return;
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );

    // Orange knob at the end of the arc.
    final end = Offset(
      center.dx + radius * math.cos(start + sweep),
      center.dy + radius * math.sin(start + sweep),
    );
    canvas.drawCircle(end, stroke * 0.62, Paint()..color = AppColors.background);
    canvas.drawCircle(end, stroke * 0.46, Paint()..color = AppColors.secondary);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Card with a dashed outline, used for AI interpretation blurbs.
class DashedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DashedCard({super.key, required this.child, this.padding = const EdgeInsets.all(22)});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    ).deflate(0.5);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 24 animated bars showing when the chat is most active; peak hour in orange.
class HourlyBarsCard extends StatelessWidget {
  final List<int> hours;

  const HourlyBarsCard({super.key, required this.hours});

  @override
  Widget build(BuildContext context) {
    final maxV = hours.isEmpty ? 0 : hours.reduce(math.max);
    final peak = maxV == 0 ? -1 : hours.indexOf(maxV);

    return WrappedCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('When you talk', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
              ),
              const Text('24 HOURS', style: AppTypography.labelSmall),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var h = 0; h < hours.length; h++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          height: maxV == 0 ? 4 : math.max(4, 90 * t * hours[h] / maxV),
                          decoration: BoxDecoration(
                            color: h == peak ? AppColors.secondary : AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00', style: AppTypography.labelSmall),
              Text('06', style: AppTypography.labelSmall),
              Text('12', style: AppTypography.labelSmall),
              Text('18', style: AppTypography.labelSmall),
              Text('23', style: AppTypography.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
