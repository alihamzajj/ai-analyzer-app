import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import '../../chat_parser/models/parse_result.dart';
import '../../chat_setup/models/chat_setup_config.dart';
import '../../statistics/models/chat_statistics.dart';
import '../services/subscription_service.dart';
import '../../ai_analysis/presentation/ai_generation_screen.dart';
import '../../../services/analytics/analytics_service.dart';

/// Gate before the AI report. While the store isn't configured the app runs
/// as a free beta: one clear button, no prices, no confusing dialogs.
class PaywallScreen extends StatefulWidget {
  final ParseResult parseResult;
  final ChatStatistics statistics;
  final ChatSetupConfig config;

  const PaywallScreen({
    super.key,
    required this.parseResult,
    required this.statistics,
    required this.config,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isYearlySelected = true;
  bool _isLoading = false;
  String? _statusMessage;

  bool get _isFreeBeta => !SubscriptionService.isConfigured;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('paywall_viewed', {'mode': _isFreeBeta ? 'free_beta' : 'store'});
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final status = await SubscriptionService.purchaseSubscription(
        isYearly: _isYearlySelected,
      );

      if (status.isProActive) {
        AnalyticsService.logEvent('purchase', {
          'plan': _isYearlySelected ? 'yearly' : 'weekly',
        });
        _proceedToAiGeneration();
      } else {
        setState(() => _statusMessage = 'Purchase was not completed.');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Could not reach Google Play. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Restoring purchases...';
    });

    try {
      final status = await SubscriptionService.restorePurchases();
      if (status.isProActive) {
        _proceedToAiGeneration();
      } else {
        setState(() => _statusMessage = 'No active subscriptions found for this Google account.');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Could not reach Google Play. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _proceedToAiGeneration() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AiGenerationScreen(
          parseResult: widget.parseResult,
          statistics: widget.statistics,
          config: widget.config,
        ),
      ),
    );
  }

  /// A real, already-computed fact from the user's chat to tease the report.
  (String, String) _teaser() {
    final stats = widget.statistics;
    final user = widget.config.userParticipantName;
    final others = stats.participantMessages.keys.where((p) => p != user).toList();
    final other = others.isNotEmpty ? others.first : 'They';
    final mine = stats.medianResponseTimeMinutes[user];
    final theirs = stats.medianResponseTimeMinutes[other];
    if (others.length == 1 && mine != null && theirs != null && mine > 0 && theirs > 0) {
      final faster = mine <= theirs ? 'You reply' : '$other replies';
      return (
        '$faster faster',
        'You: ${formatMinutes(mine)} vs $other: ${formatMinutes(theirs)}. But what does it actually mean? The AI reads the vibe.',
      );
    }
    final starters = stats.conversationStarters;
    final total = starters.values.fold<int>(0, (a, b) => a + b);
    if (total > 0) {
      final pct = ((starters[user] ?? 0) * 100 / total).round();
      return ('You start $pct% of chats', 'Is that effort being matched? The AI checks the messages that matter.');
    }
    return (
      '${formatCount(stats.totalMessages)} messages read',
      'Your stats are ready. Now let the AI tell you what they mean.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final (teaserTitle, teaserBody) = _teaser();

    final features = [
      ('\u{1F440}', 'Interest score', 'Who is more into this chat'),
      ('\u{1F6A9}', 'Red & green flags', 'With the exact messages as receipts'),
      ('\u{1F498}', 'Compatibility', 'How well your energy matches'),
      if (widget.config.enableRoast) ('\u{1F525}', 'Roast mode', 'Funny, about texting habits only'),
      ('\u{1F4F8}', 'Story cards', 'Share to Instagram & WhatsApp'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (_isFreeBeta)
                    const WrappedPill(label: 'FREE DURING BETA', color: AppColors.secondary)
                  else
                    TextButton(
                      onPressed: _isLoading ? null : _handleRestore,
                      child: const Text('Restore'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    FadeSlideIn.stagger(
                      0,
                      child: Text.rich(
                        TextSpan(
                          style: AppTypography.displayLarge.copyWith(fontSize: 38),
                          children: const [
                            TextSpan(text: 'Want the\n'),
                            TextSpan(text: 'full story?', style: TextStyle(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn.stagger(
                      1,
                      child: WrappedCard(
                        color: AppColors.secondary,
                        borderColor: null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FROM YOUR CHAT',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.onAccent),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              teaserTitle,
                              style: AppTypography.displayMedium.copyWith(color: AppColors.onAccent),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              teaserBody,
                              style: AppTypography.bodyLarge.copyWith(color: AppColors.onAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeSlideIn.stagger(
                      2,
                      child: Text(
                        'Your AI report includes',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < features.length; i++)
                      FadeSlideIn.stagger(
                        3 + i,
                        child: _featureRow(features[i].$1, features[i].$2, features[i].$3),
                      ),
                    if (!_isFreeBeta) ...[
                      const SizedBox(height: 16),
                      _buildPlans(),
                    ],
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.accentAmber),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Pulse(
                maxScale: 1.03,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : _isFreeBeta
                          ? _proceedToAiGeneration
                          : _handlePurchase,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _isFreeBeta
                        ? 'Get my AI insights'
                        : _isYearlySelected
                            ? 'Start 3-day free trial'
                            : 'Unlock full report',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isFreeBeta
                    ? 'Free while we are in beta. Takes about 30 seconds.'
                    : 'Recurring billing. Cancel anytime in Google Play.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WrappedCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            Icon(
              _isFreeBeta ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
              size: 20,
              color: _isFreeBeta ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlans() {
    Widget plan(bool yearly, String title, String price, String note, String? badge) {
      final selected = _isYearlySelected == yearly;
      return Expanded(
        child: Pressable(
          onTap: () => setState(() => _isYearlySelected = yearly),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24,
                  child: badge == null
                      ? null
                      : WrappedPill(
                          label: badge,
                          compact: true,
                          color: selected ? AppColors.onAccent : AppColors.secondary,
                          textColor: selected ? AppColors.primary : AppColors.onAccent,
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(color: selected ? AppColors.onAccent : AppColors.textPrimary),
                ),
                Text(
                  price,
                  style: AppTypography.titleLarge.copyWith(color: selected ? AppColors.onAccent : AppColors.textPrimary),
                ),
                Text(
                  note,
                  style: AppTypography.bodySmall.copyWith(
                    color: selected ? AppColors.onAccent.withValues(alpha: 0.7) : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        plan(true, 'Yearly', '\$39.99', '\$0.77 / week', 'SAVE 87%'),
        const SizedBox(width: 10),
        plan(false, 'Weekly', '\$5.99', 'Cancel anytime', null),
      ],
    );
  }
}
