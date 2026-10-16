import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../subscriptions/services/subscription_service.dart';
import '../../saved_reports/services/local_report_storage.dart';
import '../../../services/analytics/analytics_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en';
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString(AppConstants.keyAppLanguage) ?? 'en';
    });
  }

  Future<void> _changeLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAppLanguage, code);
    setState(() => _selectedLanguage = code);
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isRestoring = true);
    try {
      final status = await SubscriptionService.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isProActive
                ? 'Purchases restored successfully!'
                : 'No active Pro subscriptions found.',
          ),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store running in development mode.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _confirmDeleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.accentRed),
            SizedBox(width: 8),
            Text('Delete All Data?'),
          ],
        ),
        content: const Text(
          'This will permanently remove all saved chat reports, cached digests, and settings from this device.\n\nNote: This deletes local device storage only. External AI requests processed in memory are discarded immediately upon request completion.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: AppColors.onAccent,
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await LocalReportStorage.deleteAllData();
      AnalyticsService.logEvent('delete_data');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All local reports and cached data have been erased.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content, style: AppTypography.bodyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static const String _exportHelp =
      '1. Open the chat in WhatsApp.\n'
      '2. Tap ⋮ (top right) › More › Export chat.\n'
      '3. Choose “Without media”.\n'
      '4. Pick Chat Wrapped from the share list, or save the file and import it from the Home screen.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          children: [
            Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Settings', style: AppTypography.displayLarge.copyWith(fontSize: 38)),
            const SizedBox(height: 24),

            _section('PREFERENCES'),
            WrappedCard(
              padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
              child: Row(
                children: [
                  const Text('\u{1F310}', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Language', style: AppTypography.titleMedium),
                        Text('For AI results', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      dropdownColor: AppColors.surfaceElevated,
                      style: AppTypography.labelLarge,
                      selectedItemBuilder: (context) => [
                        for (final lang in AppConstants.supportedLanguages)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(lang['name']!.split(' (').first, style: AppTypography.labelLarge),
                          ),
                      ],
                      items: [
                        for (final lang in AppConstants.supportedLanguages)
                          DropdownMenuItem<String>(value: lang['code'], child: Text(lang['name']!)),
                      ],
                      onChanged: (val) {
                        if (val != null) _changeLanguage(val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (SubscriptionService.isConfigured) ...[
              const SizedBox(height: 24),
              _section('SUBSCRIPTION'),
              _tile(
                emoji: '\u{1F504}',
                title: 'Restore purchases',
                subtitle: 'Bring back a subscription on this phone',
                onTap: _isRestoring ? null : _handleRestorePurchases,
                trailing: _isRestoring
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
            ],

            const SizedBox(height: 24),
            _section('HELP'),
            _tile(
              emoji: '\u{1F4E4}',
              title: 'How to export a chat',
              subtitle: 'From WhatsApp, in 4 taps',
              onTap: () => _showInfoDialog('How to export a chat', _exportHelp),
            ),
            const SizedBox(height: 8),
            _tile(
              emoji: '\u{2709}\u{FE0F}',
              title: 'Contact & support',
              subtitle: 'support@aichatanalyser.app',
              onTap: () => _showInfoDialog(
                'Support',
                'For questions, feedback, or support, contact:\n\nEmail: support@aichatanalyser.app\nWebsite: https://aichatanalyser.app',
              ),
            ),

            const SizedBox(height: 24),
            _section('PRIVACY'),
            _tile(
              emoji: '\u{1F512}',
              title: 'Privacy policy',
              subtitle: 'How your chats are handled',
              onTap: () => _showInfoDialog(
                'Privacy Policy',
                'AI Chat Analyser does not store or sell your conversations.\n\n'
                    '1. On-Device Processing: Free chat statistics (message counts, response times, emoji counters) are calculated locally in your device memory.\n\n'
                    '2. AI Pipeline Anonymization: When requesting an AI report, real participant names are replaced with neutral aliases ("User A", "User B").\n\n'
                    '3. Zero Server Retention: Our backend edge functions process conversation digests strictly in memory and discard the data immediately after returning the structured report.\n\n'
                    '4. Local Reports: Saved reports are stored exclusively on your device.',
              ),
            ),
            const SizedBox(height: 8),
            _tile(
              emoji: '\u{1F4C4}',
              title: 'Terms of service',
              subtitle: 'For entertainment only',
              onTap: () => _showInfoDialog(
                'Terms of Service',
                'AI Chat Analyser is an entertainment application designed to explore conversational patterns.\n\n'
                    'The insights, compatibility metrics, situationship assessments, and roast comments provided by the app are generated for entertainment and curiosity only. They do not constitute formal psychological diagnoses, relationship counseling, or legal advice.',
              ),
            ),
            const SizedBox(height: 8),
            _tile(
              emoji: '\u{1F5D1}\u{FE0F}',
              title: 'Delete all my data',
              subtitle: 'Erase saved reports and settings from this phone',
              danger: true,
              onTap: _confirmDeleteAllData,
            ),

            const SizedBox(height: 36),
            Center(
              child: Text(
                'Chat Wrapped v${AppConstants.appVersion}',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(label, style: AppTypography.labelSmall),
      );

  Widget _tile({
    required String emoji,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool danger = false,
  }) {
    return WrappedCard(
      onTap: onTap,
      borderColor: danger ? AppColors.accentRed.withValues(alpha: 0.5) : AppColors.surfaceBorder,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(color: danger ? AppColors.accentRed : null),
                ),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
