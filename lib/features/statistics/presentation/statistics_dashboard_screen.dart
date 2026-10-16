import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import '../../chat_parser/models/parse_result.dart';
import '../../chat_setup/models/chat_setup_config.dart';
import '../models/chat_statistics.dart';
import '../../subscriptions/presentation/paywall_screen.dart';
import '../../../services/analytics/analytics_service.dart';

class StatisticsDashboardScreen extends StatefulWidget {
  final ParseResult parseResult;
  final ChatStatistics statistics;
  final ChatSetupConfig config;

  const StatisticsDashboardScreen({
    super.key,
    required this.parseResult,
    required this.statistics,
    required this.config,
  });

  @override
  State<StatisticsDashboardScreen> createState() => _StatisticsDashboardScreenState();
}

class _StatisticsDashboardScreenState extends State<StatisticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('stats_viewed');
  }

  void _navigateToPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
          parseResult: widget.parseResult,
          statistics: widget.statistics,
          config: widget.config,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.statistics;
    final user = widget.config.userParticipantName;
    final otherParticipants = stats.participantMessages.keys.where((p) => p != user).toList();
    final otherPerson = otherParticipants.isNotEmpty ? otherParticipants.first : 'Other';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                children: [
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      const WrappedPill(label: 'STEP 3 OF 3'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${user.toUpperCase()} & ${otherPerson.toUpperCase()} · ${formatCount(stats.totalMessages)} MESSAGES',
                    style: AppTypography.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: AppTypography.displayMedium.copyWith(fontSize: 34, height: 1.1),
                      children: const [
                        TextSpan(text: 'Your chat, '),
                        TextSpan(text: 'by the numbers', style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Overview tiles
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: formatCount(stats.totalWords),
                          label: 'words',
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
                      Expanded(child: StatTile(value: _peakHour(stats), label: 'peak hour')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: formatMinutes(stats.medianResponseTimeMinutes[user]),
                          label: 'your reply',
                          valueColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          value: formatMinutes(stats.medianResponseTimeMinutes[otherPerson]),
                          label: 'their reply',
                          valueColor: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          value: '${stats.longestSilenceHours.round()}h',
                          label: 'longest silence',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  SplitBarCard(
                    title: 'Who texts first',
                    trailingLabel: 'ALL TIME',
                    leftName: user,
                    rightName: otherPerson,
                    leftValue: stats.conversationStarters[user] ?? 0,
                    rightValue: stats.conversationStarters[otherPerson] ?? 0,
                  ),
                  const SizedBox(height: 12),
                  SplitBarCard(
                    title: 'Message balance',
                    trailingLabel: 'TEXTS SENT',
                    leftName: user,
                    rightName: otherPerson,
                    leftValue: stats.participantMessages[user] ?? 0,
                    rightValue: stats.participantMessages[otherPerson] ?? 0,
                  ),

                  const SizedBox(height: 12),

                  // Hourly Activity Chart
                  _buildHourlyActivityCard(stats),

                  const SizedBox(height: 12),

                  // Conversational Dynamics: Starters, Double-texts, Enders
                  _buildDynamicsCard(user, otherPerson, stats),

                  const SizedBox(height: 12),

                  // Top Emojis
                  _buildTopEmojisCard(stats),

                  const SizedBox(height: 12),

                  // Top Words
                  _buildTopWordsCard(stats),

                  const SizedBox(height: 12),

                  // Laughter, Questions & Keywords
                  _buildSentimentAndKeywordsCard(user, otherPerson, stats),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Bottom CTA Banner
            Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: ElevatedButton.icon(
                onPressed: _navigateToPaywall,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Get my AI insights'),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildHourlyActivityCard(ChatStatistics stats) {
    final maxHourly = stats.hourlyDistribution.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('24-Hour Activity', style: AppTypography.titleMedium),
              ),
              const Text('PEAK HOURS', style: AppTypography.labelSmall),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxHourly.toDouble() * 1.15,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final val = value.toInt();
                        if (val == 0) return const Text('12a', style: TextStyle(fontSize: 10, color: Colors.white54));
                        if (val == 6) return const Text('6a', style: TextStyle(fontSize: 10, color: Colors.white54));
                        if (val == 12) return const Text('12p', style: TextStyle(fontSize: 10, color: Colors.white54));
                        if (val == 18) return const Text('6p', style: TextStyle(fontSize: 10, color: Colors.white54));
                        if (val == 23) return const Text('11p', style: TextStyle(fontSize: 10, color: Colors.white54));
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(24, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: stats.hourlyDistribution[i].toDouble(),
                        color: i >= 21 || i <= 4 ? AppColors.secondary : AppColors.primary,
                        width: 7,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicsCard(String user, String other, ChatStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conversational Habits', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          _buildComparisonRow(
            'Conversation Starters',
            '${stats.conversationStarters[user] ?? 0}',
            '${stats.conversationStarters[other] ?? 0}',
            user,
            other,
          ),
          const Divider(),
          _buildComparisonRow(
            'Double Texts',
            '${stats.doubleTexts[user] ?? 0}',
            '${stats.doubleTexts[other] ?? 0}',
            user,
            other,
          ),
          const Divider(),
          _buildComparisonRow(
            'Avg Reply Speed',
            '${(stats.avgResponseTimeMinutes[user] ?? 0).toStringAsFixed(0)} min',
            '${(stats.avgResponseTimeMinutes[other] ?? 0).toStringAsFixed(0)} min',
            user,
            other,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String val1, String val2, String u1, String u2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          const SizedBox(width: 8),
          Row(
            children: [
              Text(val1, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
              const Text(' vs ', style: TextStyle(color: Colors.white38)),
              Text(val2, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopEmojisCard(ChatStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Emojis', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          if (stats.topEmojis.isEmpty)
            const Text('No emojis detected in this chat.', style: AppTypography.bodySmall)
          else
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: stats.topEmojis.take(8).map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('${e.count}', style: AppTypography.labelLarge),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTopWordsCard(ChatStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Most Frequent Words (Filtered)', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          if (stats.topWords.isEmpty)
            const Text('No frequent words found.', style: AppTypography.bodySmall)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.topWords.take(12).map((w) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(
                    '${w.word} (${w.count})',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSentimentAndKeywordsCard(String user, String other, ChatStatistics stats) {
    final userQuestions = stats.questionCounts[user] ?? 0;
    final otherQuestions = stats.questionCounts[other] ?? 0;
    final userLaughs = stats.laughCounts[user] ?? 0;
    final otherLaughs = stats.laughCounts[other] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Curiosity & Humor', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          _buildComparisonRow('Questions Asked', '$userQuestions', '$otherQuestions', user, other),
          const Divider(),
          _buildComparisonRow('Laughter / Haha / 😂', '$userLaughs', '$otherLaughs', user, other),
        ],
      ),
    );
  }
}
