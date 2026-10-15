import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
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

  String _currentStage = 'Initializing AI analysis...';
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
      _currentStage = 'Preparing conversation & anonymizing aliases...';
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
        onProgress: (stage, progress) {
          if (mounted) {
            setState(() {
              _currentStage = stage;
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
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      AnalyticsService.logEvent('analysis_failed', {'error_category': 'pipeline'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Glowing AI orb
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _hasError ? AppColors.roastGradient : AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: (_hasError ? AppColors.accentRed : AppColors.primary)
                          .withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  _hasError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
                  size: 60,
                  color: AppColors.onAccent,
                ),
              ),

              const SizedBox(height: 48),

              Text(
                _hasError ? 'Analysis Interrupted' : 'Analyzing Dynamics',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                _hasError ? (_errorMessage ?? 'An unexpected error occurred.') : _currentStage,
                style: AppTypography.bodyLarge.copyWith(
                  color: _hasError ? AppColors.accentRed : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // Progress Bar
              if (!_hasError) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: AppColors.surfaceElevated,
                    color: AppColors.primary,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_progressValue * 100).toInt()}%',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                ),
              ],

              const Spacer(),

              // Actions
              if (_hasError) ...[
                ElevatedButton(
                  onPressed: _startGeneration,
                  child: const Text('Retry Analysis'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Statistics'),
                ),
              ] else ...[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
