import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../chat_parser/models/parse_result.dart';
import '../../chat_setup/models/chat_setup_config.dart';
import '../../statistics/models/chat_statistics.dart';
import '../services/subscription_service.dart';
import '../../ai_analysis/presentation/ai_generation_screen.dart';
import '../../../services/analytics/analytics_service.dart';

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

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('paywall_viewed');
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
        // Fallback for development/testing when live Google Play billing is unconfigured
        _showUnconfiguredStoreDialog();
      }
    } catch (e) {
      _showUnconfiguredStoreDialog();
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
      setState(() => _statusMessage = 'Store is running in development mode.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUnconfiguredStoreDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Store Mode Notice'),
        content: const Text(
          'RevenueCat & Google Play Billing keys are not configured yet. Would you like to proceed with the full AI Analysis in developer preview mode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _proceedToAiGeneration();
            },
            child: const Text('Unlock in Preview Mode'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Unlock Full Report', style: AppTypography.titleLarge),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleRestore,
            child: const Text('Restore', style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Teaser Insight Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGlowGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.onAccent),
                            ),
                            const SizedBox(width: 10),
                            const Text('TEASER INSIGHT', style: AppTypography.labelLarge),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text('Mutual Resonance: 86%', style: AppTypography.titleLarge),
                        const SizedBox(height: 6),
                        const Text(
                          'You two have exceptional conversational momentum. Both initiate conversations with matching enthusiasm.',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Locked Cards Preview
                  const Text('Included In Your Full Report:', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  _buildLockedFeatureTile(
                    'Red & Green Flags',
                    'Evidence-backed moments of connection and friction',
                    Icons.flag_rounded,
                    AppColors.accentRed,
                  ),
                  _buildLockedFeatureTile(
                    'Simp Score & Effort Gap',
                    'Who is investing more emotional energy into texting',
                    Icons.favorite_rounded,
                    AppColors.secondary,
                  ),
                  _buildLockedFeatureTile(
                    'Compatibility Score',
                    'Multi-factor conversational chemistry index',
                    Icons.auto_awesome_rounded,
                    AppColors.accentCyan,
                  ),
                  _buildLockedFeatureTile(
                    'Roast Mode (${widget.config.roastIntensity.toUpperCase()})',
                    'Witty, hilarious breakdown of your texting quirks',
                    Icons.local_fire_department_rounded,
                    AppColors.roastAccent,
                  ),
                  _buildLockedFeatureTile(
                    '1080x1920 Story Cards',
                    'Shareable Wrapped-style cards for Instagram and TikTok',
                    Icons.share_rounded,
                    AppColors.accentAmber,
                  ),

                  const SizedBox(height: 28),

                  // Plan Selection Cards
                  Row(
                    children: [
                      // Yearly Option (Best value)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isYearlySelected = true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isYearlySelected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isYearlySelected
                                    ? AppColors.primary
                                    : AppColors.surfaceBorder,
                                width: _isYearlySelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SAVE 87%',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text('Yearly Plan', style: AppTypography.titleMedium),
                                const SizedBox(height: 4),
                                const Text('\$39.99 / yr', style: AppTypography.titleLarge),
                                const SizedBox(height: 4),
                                const Text('\$0.77 / week', style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Weekly Option
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isYearlySelected = false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: !_isYearlySelected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: !_isYearlySelected
                                    ? AppColors.primary
                                    : AppColors.surfaceBorder,
                                width: !_isYearlySelected ? 2 : 1,
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20),
                                Text('Weekly Plan', style: AppTypography.titleMedium),
                                SizedBox(height: 4),
                                Text('\$5.99 / wk', style: AppTypography.titleLarge),
                                SizedBox(height: 4),
                                Text('Cancel anytime', style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.accentAmber, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handlePurchase,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
                          )
                        : Text(
                            _isYearlySelected
                                ? 'Start 3-Day Free Trial'
                                : 'Unlock Full AI Report',
                          ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Recurring billing. Cancel anytime in Google Play Store.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedFeatureTile(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
