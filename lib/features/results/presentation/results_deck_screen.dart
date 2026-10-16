import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import '../../ai_analysis/models/analysis_report.dart';
import '../../ai_analysis/models/report_card.dart';
import '../../chat_parser/models/parsed_message.dart';
import '../../receipts/presentation/receipt_details_sheet.dart';
import '../../share_cards/services/card_generator.dart';
import '../../../services/analytics/analytics_service.dart';

/// Story-style deck of AI insight cards (tap edges or swipe to step).
class ResultsDeckScreen extends StatefulWidget {
  final AnalysisReport report;
  final List<ParsedMessage> sourceMessages;
  final int initialIndex;

  const ResultsDeckScreen({
    super.key,
    required this.report,
    required this.sourceMessages,
    this.initialIndex = 0,
  });

  @override
  State<ResultsDeckScreen> createState() => _ResultsDeckScreenState();
}

class _ResultsDeckScreenState extends State<ResultsDeckScreen> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;
  bool _useInitialsForSharing = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('results_viewed', {
      'cards_count': widget.report.cards.length,
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shareCurrentCard() {
    if (widget.report.cards.isEmpty) return;
    final card = widget.report.cards[_currentIndex];
    final p1 = widget.report.userParticipant;
    final otherParticipants = widget.report.participants
        .where((p) => p != p1)
        .toList();
    final p2 = otherParticipants.isNotEmpty
        ? otherParticipants.first
        : 'Partner';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Share 1080×1920 Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate a high-res Wrapped card for Instagram Stories, TikTok, or WhatsApp.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Use initials instead of names',
                  style: AppTypography.labelLarge,
                ),
                subtitle: const Text(
                  'Enhanced privacy for social sharing',
                  style: AppTypography.bodySmall,
                ),
                value: _useInitialsForSharing,
                onChanged: (val) {
                  setDialogState(() => _useInitialsForSharing = val);
                  setState(() => _useInitialsForSharing = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () {
                Navigator.pop(ctx);
                AnalyticsService.logEvent('card_shared', {
                  'card_type': card.type.name,
                });
                CardGenerator.shareCard(
                  context: context,
                  card: card,
                  participant1: p1,
                  participant2: p2,
                  useInitials: _useInitialsForSharing,
                );
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('Export & Share'),
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.report.cards.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.report.cards;
    final isLast = _currentIndex >= cards.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Story-style progress segments
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: List.generate(cards.length, (idx) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: idx <= _currentIndex
                            ? AppColors.primary
                            : AppColors.surfaceBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR CHAT, WRAPPED',
                          style: AppTypography.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_currentIndex + 1} of ${cards.length}',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.ios_share_rounded,
                    tooltip: 'Share card',
                    onPressed: _shareCurrentCard,
                  ),
                ],
              ),
            ),

            // Swipeable deck; tap left/right edge to step like stories
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: cards.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      final page = _pageController.position.haveDimensions
                          ? (_pageController.page ?? _currentIndex.toDouble())
                          : _currentIndex.toDouble();
                      final scale =
                          1 - ((page - index).abs() * 0.08).clamp(0.0, 0.08);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: GestureDetector(
                      onTapUp: (d) {
                        final w = MediaQuery.of(context).size.width;
                        if (d.globalPosition.dx < w * 0.3) {
                          _goTo(index - 1);
                        } else if (d.globalPosition.dx > w * 0.7) {
                          _goTo(index + 1);
                        }
                      },
                      child: _buildReportCardView(cards[index], index),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
              child: ElevatedButton.icon(
                onPressed: isLast
                    ? _shareCurrentCard
                    : () => _goTo(_currentIndex + 1),
                icon: Icon(
                  isLast
                      ? Icons.ios_share_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(isLast ? 'Share your Wrapped' : 'Next insight'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Map<ReportCardType, String> _emoji = {
    ReportCardType.interestMeter: '\u{1F440}',
    ReportCardType.situationshipStatus: '\u{1F914}',
    ReportCardType.simpScore: '\u{1F97A}',
    ReportCardType.compatibilityScore: '\u{1F498}',
    ReportCardType.redFlags: '\u{1F6A9}',
    ReportCardType.greenFlags: '\u{1F49A}',
    ReportCardType.doubleTextChampion: '\u{1F4AC}',
    ReportCardType.dryTexterDetector: '\u{1F634}',
    ReportCardType.effortGap: '\u{2696}\u{FE0F}',
    ReportCardType.textingPersonality: '\u{1F9E0}',
    ReportCardType.groupRoles: '\u{1F465}',
    ReportCardType.chatWrapped: '\u{1F381}',
    ReportCardType.roastMode: '\u{1F525}',
    ReportCardType.whosTheProblem: '\u{1F575}\u{FE0F}',
  };

  /// Card fill: semantic for specific types, otherwise cycles lime / dark / orange.
  static (Color, Color, Color) _palette(ReportCard card, int index) {
    const lime = (AppColors.primary, AppColors.onAccent, Color(0xB30A1410));
    const orange = (AppColors.secondary, AppColors.onAccent, Color(0xB30A1410));
    const red = (Color(0xFFE53935), Colors.white, Color(0xCCFFFFFF));
    const dark = (
      AppColors.surfaceElevated,
      AppColors.textPrimary,
      AppColors.textSecondary,
    );
    switch (card.type) {
      case ReportCardType.roastMode:
        return orange;
      case ReportCardType.redFlags:
        return red;
      case ReportCardType.greenFlags:
        return lime;
      default:
        return [lime, dark, orange][index % 3];
    }
  }

  static String _typeLabel(ReportCardType t) {
    switch (t) {
      case ReportCardType.greenFlags:
        return 'GREEN FLAGS';
      case ReportCardType.redFlags:
        return 'RED FLAGS';
      case ReportCardType.roastMode:
        return 'ROAST MODE';
      case ReportCardType.simpScore:
        return 'SIMP SCORE';
      case ReportCardType.interestMeter:
        return 'INTEREST METER';
      case ReportCardType.situationshipStatus:
        return 'SITUATIONSHIP STATUS';
      case ReportCardType.compatibilityScore:
        return 'COMPATIBILITY SCORE';
      case ReportCardType.doubleTextChampion:
        return 'DOUBLE-TEXT CHAMPION';
      case ReportCardType.dryTexterDetector:
        return 'DRY TEXTER DETECTOR';
      case ReportCardType.effortGap:
        return 'EFFORT GAP';
      case ReportCardType.textingPersonality:
        return 'TEXTING PERSONALITY';
      case ReportCardType.groupRoles:
        return 'GROUP ROLES';
      case ReportCardType.whosTheProblem:
        return 'WHO\'S THE PROBLEM';
      case ReportCardType.chatWrapped:
        return 'CHAT WRAPPED';
    }
  }

  Widget _buildReportCardView(ReportCard card, int index) {
    final (bg, ink, muted) = _palette(card, index);
    final isDark = bg == AppColors.surfaceElevated;
    final emoji = _emoji[card.type] ?? '✨';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(34),
          border: isDark ? Border.all(color: AppColors.surfaceBorder) : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, constraints.maxHeight - 52),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _typeLabel(card.type),
                            style: AppTypography.labelSmall.copyWith(
                              color: ink,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      child: Text(
                        card.title,
                        style: AppTypography.displayLarge.copyWith(
                          color: ink,
                          fontSize: 36,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        card.subtitle,
                        style: AppTypography.titleLarge.copyWith(
                          color: isDark ? AppColors.primary : ink.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (card.score != null) ...[
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          CountUp(
                            value: card.score!,
                            style: AppTypography.number(size: 96, color: ink),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '/100',
                            style: AppTypography.titleLarge.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: card.score! / 100),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 10,
                            color: isDark ? AppColors.primary : ink,
                            backgroundColor: ink.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: ink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ink.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                card.type == ReportCardType.greenFlags
                                    ? 'Healthy Strengths Detected'
                                    : card.type == ReportCardType.redFlags
                                        ? 'Caution & Communication Patterns'
                                        : 'Key Conversation Dynamics',
                                style: AppTypography.labelLarge.copyWith(
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceElevated.withValues(alpha: 0.6)
                              : ink.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ink.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Text(
                          card.summary,
                          style: AppTypography.bodyLarge.copyWith(
                            color: ink,
                            fontSize: 17,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        WrappedPill(
                          label: '${card.confidence.toUpperCase()} CONFIDENCE',
                          filled: false,
                          color: isDark ? AppColors.textSecondary : ink,
                          compact: true,
                        ),
                        if (card.messageIds.isNotEmpty &&
                            widget.sourceMessages.isNotEmpty)
                          Pressable(
                            onTap: () => ReceiptDetailsSheet.show(
                              context,
                              card,
                              widget.sourceMessages,
                            ),
                            child: WrappedPill(
                              label:
                                  '\u{1F9FE} ${card.messageIds.length} RECEIPTS',
                              color: isDark
                                  ? AppColors.primary
                                  : AppColors.onAccent,
                              textColor: isDark ? AppColors.onAccent : bg,
                              compact: true,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
