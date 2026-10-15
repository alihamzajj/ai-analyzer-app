import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
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
        backgroundColor: AppColors.surfaceElevated,
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
        backgroundColor: AppColors.surfaceElevated,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Preferences
          const Text('Preferences', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: AppColors.primaryLight),
              title: const Text('Language', style: AppTypography.titleMedium),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  dropdownColor: AppColors.surfaceElevated,
                  items: AppConstants.supportedLanguages.map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang['code'],
                      child: Text(lang['name']!, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _changeLanguage(val);
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Section 2: Subscriptions
          const Text('Subscription', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: ListTile(
              leading: const Icon(Icons.restore_rounded, color: AppColors.accentCyan),
              title: const Text('Restore Purchases', style: AppTypography.titleMedium),
              subtitle: const Text('Restore previously purchased subscriptions', style: AppTypography.bodySmall),
              trailing: _isRestoring
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: _isRestoring ? null : _handleRestorePurchases,
            ),
          ),

          const SizedBox(height: 28),

          // Section 3: Legal & Privacy
          const Text('Legal & Privacy', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.accentGreen),
                  title: const Text('Privacy Policy', style: AppTypography.titleMedium),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () => _showInfoDialog(
                    'Privacy Policy',
                    'AI Chat Analyser does not store or sell your conversations.\n\n'
                    '1. On-Device Processing: Free chat statistics (message counts, response times, emoji counters) are calculated locally in your device memory.\n\n'
                    '2. AI Pipeline Anonymization: When requesting an AI report, real participant names are replaced with neutral aliases ("User A", "User B").\n\n'
                    '3. Zero Server Retention: Our backend edge functions process conversation digests strictly in memory and discard the data immediately after returning the structured report.\n\n'
                    '4. Local Reports: Saved reports are stored exclusively on your device.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.secondary),
                  title: const Text('Terms of Service', style: AppTypography.titleMedium),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () => _showInfoDialog(
                    'Terms of Service',
                    'AI Chat Analyser is an entertainment application designed to explore conversational patterns.\n\n'
                    'The insights, compatibility metrics, situationship assessments, and roast comments provided by the app are generated for entertainment and curiosity only. They do not constitute formal psychological diagnoses, relationship counseling, or legal advice.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded, color: AppColors.accentAmber),
                  title: const Text('Contact & Support', style: AppTypography.titleMedium),
                  subtitle: const Text('support@aichatanalyser.app', style: AppTypography.bodySmall),
                  onTap: () => _showInfoDialog(
                    'Support Information',
                    'For questions, feedback, or support inquiries, contact:\n\nEmail: support@aichatanalyser.app\nWebsite: https://aichatanalyser.app',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 4: Danger Zone
          const Text('Data Management', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: AppColors.accentRed),
              title: const Text('Delete All Data', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
              subtitle: const Text('Erase all saved reports, digests, and settings', style: AppTypography.bodySmall),
              onTap: _confirmDeleteAllData,
            ),
          ),

          const SizedBox(height: 36),

          // App Diagnostics Footer
          Center(
            child: Column(
              children: [
                Text(
                  'AI Chat Analyser v${AppConstants.appVersion}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Flutter 3.47.5 • Android-first build',
                  style: TextStyle(fontSize: 10, color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
