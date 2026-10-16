import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import '../../../core/errors/app_exception.dart';
import '../../chat_parser/models/parse_result.dart';
import '../../chat_setup/models/chat_setup_config.dart';
import '../../statistics/models/chat_statistics.dart';
import '../services/ai_pipeline_service.dart';
import '../../saved_reports/services/local_report_storage.dart';
import '../../results/presentation/report_overview_screen.dart';
import '../../../services/analytics/analytics_service.dart';

class AiGenerationScreen extends StatefulWidget {
  final ParseResult parseResult;
  final ChatStatistics statistics;
  final ChatSetupConfig config;

  const AiGenerationScreen({
    super.key,
    required this.parseResult,
    required this.statistics,
    required this.config,
  });

  @override
  State<AiGenerationScreen> createState() => _AiGenerationScreenState();
}

class _AiGenerationScreenState extends State<AiGenerationScreen> {
  final AiPipelineService _pipelineService = AiPipelineService.fromConfig();

  double _progressValue = 0.05;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  Future<void> _startGeneration() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _progressValue = 0.1;
    });

    AnalyticsService.logEvent('analysis_started', {
      'relationship_type': widget.config.relationshipType,
      'roast_intensity': widget.config.roastIntensity,
    });

    try {
      final report = await _pipelineService.generateReport(
        messages: widget.parseResult.messages,
        statistics: widget.statistics,
        config: widget.config,
        conversationHash: widget.parseResult.conversationHash,
        onProgress: (_, progress) {
          if (mounted) {
            setState(() {
              _progressValue = progress;
            });
          }
        },
      );

      // Save report to encrypted local storage
      await LocalReportStorage.saveReport(report);

      AnalyticsService.logEvent('analysis_completed', {
        'cards_count': report.cards.length,
      });

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReportOverviewScreen(
            report: report,
            sourceMessages: widget.parseResult.messages,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e is AppException ? e.message : 'Something went wrong. Please try again.';
      });
      AnalyticsService.logEvent('analysis_failed', {'error_category': 'pipeline'});
    }
  }

  static const _steps = [
    ('\u{1F512}', 'Hiding names for privacy', 0.35),
    ('\u{1F4D6}', 'Picking the moments that matter', 0.60),
    ('\u{1F9E0}', 'AI is reading the vibe', 0.85),
    ('\u{1F9FE}', 'Checking every receipt', 1.01),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Pulse(
                  maxScale: _hasError ? 1.0 : 1.08,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError ? AppColors.secondary : AppColors.primary,
                    ),
                    child: Icon(
                      _hasError ? Icons.wifi_off_rounded : Icons.auto_awesome_rounded,
                      size: 52,
                      color: AppColors.onAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text.rich(
                TextSpan(
                  style: AppTypography.displayMedium.copyWith(fontSize: 32),
                  children: _hasError
                      ? const [
                          TextSpan(text: 'That didn’t\n'),
                          TextSpan(text: 'work out.', style: TextStyle(color: AppColors.secondary)),
                        ]
                      : const [
                          TextSpan(text: 'Reading\n'),
                          TextSpan(text: 'your chat…', style: TextStyle(color: AppColors.primary)),
                        ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _hasError
                    ? (_errorMessage ?? 'Something went wrong. Please try again.')
                    : 'This takes about 30 seconds. Keep the app open.',
                style: AppTypography.bodyLarge.copyWith(
                  color: _hasError ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (!_hasError)
                WrappedCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < _steps.length; i++) _buildStep(i),
                    ],
                  ),
                ),
              const Spacer(),
              if (_hasError) ...[
                ElevatedButton.icon(
                  onPressed: _startGeneration,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to my stats'),
                ),
              ] else
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int i) {
    final (emoji, label, doneAt) = _steps[i];
    final previousDoneAt = i == 0 ? 0.0 : _steps[i - 1].$3;
    final done = _progressValue >= doneAt;
    final active = !done && _progressValue >= previousDoneAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done || active ? 1 : 0.4,
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            SizedBox(
              width: 22,
              height: 22,
              child: done
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                  : active
                      ? const CircularProgressIndicator(strokeWidth: 2.5)
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
