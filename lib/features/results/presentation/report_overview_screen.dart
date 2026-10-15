import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import '../../ai_analysis/models/analysis_report.dart';
import '../../chat_parser/models/parsed_message.dart';
import '../../saved_reports/services/sample_report.dart';
import '../../statistics/models/chat_statistics.dart';
import 'results_deck_screen.dart';

/// Single-chat summary: score ring, key stats, who texts first and
/// the AI interpretation. Entry point into the swipeable results deck.
class ReportOverviewScreen extends StatelessWidget {
  final AnalysisReport report;
  final List<ParsedMessage> sourceMessages;

  const ReportOverviewScreen({
    super.key,
    required this.report,
    this.sourceMessages = const [],
  });

  void _openDeck(BuildContext context, [int initialIndex = 0]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsDeckScreen(
          report: report,
          sourceMessages: sourceMessages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = report.statistics;
    final user = report.userParticipant;
    final other = report.isGroup ? 'Everyone else' : report.otherPerson;
    final score = report.headlineScore;
    final interpretation = report.interpretationCard;
    final hasAi = report.cards.isNotEmpty;

    final title = report.isGroup
        ? '${report.participants.length} PEOPLE'
        : '${user.toUpperCase()} & ${report.otherPerson.toUpperCase()}';

    final isSample = SampleReport.isSample(report);
    var i = 0;
    Widget step(Widget w) => FadeSlideIn.stagger(i++, child: w);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          children: [
            step(Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                WrappedPill(
                  label: isSample ? 'SAMPLE REPORT' : hasAi ? 'AI REPORT' : 'FREE · ON-DEVICE',
                  color: isSample ? AppColors.secondary : AppColors.primary,
                ),
              ],
            )),
            const SizedBox(height: 24),
            step(Text(
              '$title · ${formatCount(stats.totalMessages)} MESSAGES',
              style: AppTypography.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(height: 8),
            step(_Headline(score: score, user: user, other: report.otherPerson, isGroup: report.isGroup)),
            const SizedBox(height: 28),
            Center(child: ScoreRing(score: score)),
            const SizedBox(height: 28),
            step(Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: _replyShare(stats, user),
                    label: 'reply rate',
                    valueColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    value: '${stats.longestDailyStreakDays}d',
                    label: 'streak',
                    valueColor: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(value: _peakHour(stats), label: 'peak hour'),
                ),
              ],
            )),
            const SizedBox(height: 12),
            step(SplitBarCard(
              title: 'Who texts first',
              trailingLabel: 'ALL TIME',
              leftName: user,
              rightName: other,
              leftValue: stats.conversationStarters[user] ?? 0,
              rightValue: _sumExcept(stats.conversationStarters, user),
            )),
            const SizedBox(height: 12),
            step(HourlyBarsCard(hours: stats.hourlyDistribution)),
            const SizedBox(height: 12),
            if (interpretation != null)
              step(DashedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI INTERPRETATION · ${interpretation.confidence.toUpperCase()} CONFIDENCE',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      interpretation.summary.isNotEmpty
                          ? interpretation.summary
                          : interpretation.subtitle,
                      style: AppTypography.bodyLarge.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              )),
            if (hasAi) ...[
              const SizedBox(height: 28),
              step(Text(
                'Inside your deck',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              )),
              const SizedBox(height: 12),
              step(Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var c = 0; c < report.cards.length; c++)
                    Pressable(
                      onTap: () => _openDeck(context, c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Text(report.cards[c].title, style: AppTypography.labelLarge),
                      ),
                    ),
                ],
              )),
              const SizedBox(height: 20),
              step(Pulse(
                maxScale: 1.03,
                child: ElevatedButton.icon(
                  onPressed: () => _openDeck(context),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Play your Wrapped · ${report.cards.length} cards'),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  /// Share of messages answered by the user's counterpart(s), capped at 100%.
  static String _replyShare(ChatStatistics stats, String user) {
    final mine = stats.participantMessages[user] ?? 0;
    final theirs = _sumExcept(stats.participantMessages, user);
    if (mine == 0) return '—';
    final pct = (theirs * 100 / mine).clamp(0, 100).round();
    return '$pct%';
  }

  static String _peakHour(ChatStatistics stats) {
    final hours = stats.hourlyDistribution;
    if (hours.isEmpty || hours.every((h) => h == 0)) return '—';
    var best = 0;
    for (var i = 1; i < hours.length; i++) {
      if (hours[i] > hours[best]) best = i;
    }
    return '${best.toString().padLeft(2, '0')}:00';
  }

  static int _sumExcept(Map<String, int> map, String key) =>
      map.entries.where((e) => e.key != key).fold(0, (sum, e) => sum + e.value);
}

class _Headline extends StatelessWidget {
  final int? score;
  final String user;
  final String other;
  final bool isGroup;

  const _Headline({required this.score, required this.user, required this.other, required this.isGroup});

  @override
  Widget build(BuildContext context) {
    final (String lead, String accent) = switch (score) {
      null => ('Your chat,', 'by the numbers'),
      int s when isGroup && s >= 60 => ('This group is', 'buzzing'),
      _ when isGroup => ('This group is', 'cooling off'),
      int s when s >= 65 => ('$other is leaning', 'toward $user'),
      int s when s >= 40 => ('$other is', 'on the fence'),
      _ => ('$other is', 'drifting away'),
    };

    return Text.rich(
      TextSpan(
        style: AppTypography.displayMedium.copyWith(fontSize: 34, height: 1.1),
        children: [
          TextSpan(text: '$lead '),
          TextSpan(
            text: accent,
            style: TextStyle(color: (score ?? 100) >= 40 ? AppColors.primary : AppColors.secondary),
          ),
        ],
      ),
    );
  }
}
