import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import '../../ai_analysis/models/analysis_report.dart';
import '../../chat_import/presentation/export_guide_screen.dart';
import '../../chat_import/presentation/import_screen.dart';
import '../../results/presentation/report_overview_screen.dart';
import '../../saved_reports/services/local_report_storage.dart';
import '../../saved_reports/services/sample_report.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../services/analytics/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AnalysisReport> _savedReports = [];
  bool _isLoadingReports = true;
  bool _showAllReports = false;
  StreamSubscription? _intentSub;

  static const int _collapsedReportCount = 3;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('app_open');
    _loadSavedReports();
    _listenToShareIntents();
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  void _listenToShareIntents() {
    // Listen to media/file sharing while the app is in memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      if (files.isNotEmpty && mounted) {
        final path = files.first.path;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ImportScreen(preloadedFilePath: path)),
        ).then((_) => _loadSavedReports());
      }
    });

    // Check if app was launched via share intent
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      if (files.isNotEmpty && mounted) {
        final path = files.first.path;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ImportScreen(preloadedFilePath: path)),
        ).then((_) => _loadSavedReports());
      }
    });
  }

  Future<void> _loadSavedReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final reports = await LocalReportStorage.getAllReports();
      if (mounted) {
        setState(() {
          _savedReports = reports;
          _isLoadingReports = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  void _openImportScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportScreen()),
    ).then((_) => _loadSavedReports());
  }

  void _openExportGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExportGuideScreen()),
    ).then((_) => _loadSavedReports());
  }

  /// First-run helper: most new users don't know how to export a chat.
  Widget _buildGuideBanner() {
    return WrappedCard(
      onTap: _openExportGuide,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: AppColors.onAccent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New here?', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const Text('Watch how to export a WhatsApp chat (20 sec)', style: AppTypography.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) => _loadSavedReports());
  }

  void _openReport(AnalysisReport report) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportOverviewScreen(report: report)),
    ).then((_) => _loadSavedReports());
  }

  /// Report featured in the bento cards: newest one with a score, else newest.
  AnalysisReport? get _latest {
    for (final r in _savedReports) {
      if (r.headlineScore != null) return r;
    }
    return _savedReports.isNotEmpty ? _savedReports.first : null;
  }

  late final AnalysisReport _sample = SampleReport.build();

  @override
  Widget build(BuildContext context) {
    final latest = _latest;
    final userName = latest?.userParticipant.split(' ').first ?? 'there';
    // Until the first import, the bento shows the sample report so it never looks empty.
    final featured = latest ?? _sample;
    final isSample = latest == null && !_isLoadingReports;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSavedReports,
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            children: [
              FadeSlideIn.stagger(0, child: _buildHeader(userName)),
              const SizedBox(height: 28),
              FadeSlideIn.stagger(1, child: Text.rich(
                TextSpan(
                  style: AppTypography.displayLarge,
                  children: const [
                    TextSpan(text: 'Your chats,\n'),
                    TextSpan(text: 'decoded.', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              )),
              const SizedBox(height: 22),
              FadeSlideIn.stagger(2, child: _buildBento(featured, isSample)),
              if (isSample) ...[
                const SizedBox(height: 12),
                FadeSlideIn.stagger(3, child: _buildGuideBanner()),
              ],
              const SizedBox(height: 28),
              FadeSlideIn.stagger(3, child: _buildDiscoverCarousel()),
              const SizedBox(height: 28),
              FadeSlideIn.stagger(4, child: _buildRecentReports()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Text(
            userName == 'there' ? '★' : initialsOf(userName).substring(0, 1),
            style: AppTypography.titleLarge.copyWith(color: AppColors.onAccent),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CHAT WRAPPED', style: AppTypography.labelSmall),
              const SizedBox(height: 4),
              Text(
                'Hey, $userName',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        CircleIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onPressed: _openSettings,
        ),
      ],
    );
  }

  Widget _buildBento(AnalysisReport latest, bool isSample) {
    return SizedBox(
      height: 390,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildImportCard()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: _buildInterestCard(latest, isSample)),
                const SizedBox(height: 12),
                Expanded(flex: 10, child: _buildReplyTimeCard(latest)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    return WrappedCard(
      color: AppColors.primary,
      borderColor: null,
      padding: const EdgeInsets.all(20),
      onTap: _openImportScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEW REPORT', style: AppTypography.labelSmall.copyWith(color: AppColors.onAccent)),
          const SizedBox(height: 14),
          Text(
            'Import\na chat',
            style: AppTypography.displayMedium.copyWith(color: AppColors.onAccent, fontSize: 32),
          ),
          const Spacer(),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              WrappedPill(label: '.txt', filled: false, color: AppColors.onAccent, compact: true),
              WrappedPill(label: '.zip', filled: false, color: AppColors.onAccent, compact: true),
            ],
          ),
          const SizedBox(height: 16),
          Pulse(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.onAccent, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestCard(AnalysisReport latest, bool isSample) {
    final score = latest.headlineScore;
    return WrappedCard(
      color: AppColors.secondary,
      borderColor: null,
      onTap: () => _openReport(latest),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('INTEREST METER', style: AppTypography.labelSmall.copyWith(color: AppColors.onAccent)),
          ),
          if (isSample) ...[
            const SizedBox(height: 8),
            const WrappedPill(label: 'SAMPLE', color: AppColors.onAccent, compact: true, textColor: AppColors.secondary),
          ],
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (score == null)
                  Text('\u2014', style: AppTypography.number(size: 72, color: AppColors.onAccent))
                else
                  CountUp(value: score, style: AppTypography.number(size: 72, color: AppColors.onAccent)),
                const SizedBox(width: 4),
                Text('/100', style: AppTypography.bodyLarge.copyWith(color: AppColors.onAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _discoverItems = [
    ('\u{1F6A9}', 'Red & green\nflags', AppColors.secondary),
    ('\u{1F525}', 'Roast\nmode', AppColors.primary),
    ('\u{1F634}', 'Dry texter\ndetector', AppColors.surfaceElevated),
    ('\u{1F4AC}', 'Double-text\nchampion', AppColors.primary),
    ('\u{1F9E0}', 'Texting\npersonality', AppColors.surfaceElevated),
    ('\u{1F498}', 'Compatibility\nscore', AppColors.secondary),
  ];

  Widget _buildDiscoverCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "What you'll find out",
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            GestureDetector(
              onTap: () => _openReport(_sample),
              child: Text(
                'See a sample',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: _discoverItems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (emoji, label, color) = _discoverItems[i];
              final onDark = color == AppColors.surfaceElevated;
              final ink = onDark ? AppColors.textPrimary : AppColors.onAccent;
              return SizedBox(
                width: 132,
                child: WrappedCard(
                  color: color,
                  borderColor: onDark ? AppColors.surfaceBorder : null,
                  radius: 24,
                  padding: const EdgeInsets.all(16),
                  onTap: () => _openReport(_sample),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 30)),
                      const Spacer(),
                      Text(
                        label,
                        style: AppTypography.labelLarge.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReplyTimeCard(AnalysisReport latest) {
    final reply = latest.statistics.medianResponseTimeMinutes;
    final rows = <(String, String, Color)>[
      (latest.userParticipant, formatMinutes(reply[latest.userParticipant]), AppColors.primary),
      for (final p in latest.otherParticipants.take(1))
        (p, formatMinutes(reply[p]), AppColors.secondary),
    ];

    return WrappedCard(
      onTap: () => _openReport(latest),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REPLY TIME', style: AppTypography.labelSmall),
          const Spacer(),
          if (rows.isEmpty)
            const Text('Import a chat to see who replies faster.', style: AppTypography.bodyMedium)
          else
            for (final (name, value, color) in rows)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.split(' ').first,
                        style: AppTypography.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(value, style: AppTypography.number(size: 28, color: color)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildRecentReports() {
    final visible = _showAllReports
        ? _savedReports
        : _savedReports.take(_collapsedReportCount).toList();

    return WrappedCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent reports',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_savedReports.length > _collapsedReportCount)
                GestureDetector(
                  onTap: () => setState(() => _showAllReports = !_showAllReports),
                  child: Text(
                    _showAllReports ? 'Show less' : 'See all',
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingReports)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_savedReports.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                'No reports yet. Export a chat from WhatsApp (Without Media) and tap Import, or peek at the sample:',
                style: AppTypography.bodyMedium,
              ),
            ),
            _buildReportRow(_sample),
          ]
          else
            for (final report in visible) _buildReportRow(report),
        ],
      ),
    );
  }

  Widget _buildReportRow(AnalysisReport report) {
    final stats = report.statistics;
    final others = report.otherParticipants;
    final title = report.isGroup
        ? '${others.take(2).join(', ')}${others.length > 2 ? ' +${others.length - 2}' : ''}'
        : '${report.userParticipant} & ${report.otherPerson}';
    final subtitle = report.isGroup
        ? '${report.participants.length} people · ${formatCount(stats.totalMessages)} msgs'
        : '${formatCount(stats.totalMessages)} msgs · ${stats.longestDailyStreakDays} day streak';
    final avatarColor = report.isGroup ? AppColors.primary : AppColors.secondary;
    final avatarLabel = report.isGroup
        ? '+${report.participants.length - 1}'
        : initialsOf(report.userParticipant)[0] + initialsOf(report.otherPerson)[0];
    final score = report.headlineScore;
    final isNew = DateTime.now().difference(report.createdAt).inHours < 24;
    final isSample = SampleReport.isSample(report);
    final trailing = isSample ? 'SAMPLE' : score != null ? '$score%' : (isNew ? 'NEW' : null);
    final row = _buildReportRowContent(report, title, subtitle, avatarColor, avatarLabel, trailing);
    if (isSample) return row;

    return Dismissible(
      key: Key(report.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete report?'),
            content: Text('Remove analysis for "$title"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await LocalReportStorage.deleteReport(report.id);
        _loadSavedReports();
      },
      child: row,
    );
  }

  Widget _buildReportRowContent(
    AnalysisReport report,
    String title,
    String subtitle,
    Color avatarColor,
    String avatarLabel,
    String? trailing,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openReport(report),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
              child: Text(
                avatarLabel,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              Text(
                trailing,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
