import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../chat_parser/models/parse_result.dart';
import '../../chat_parser/services/chat_parser.dart';
import '../../chat_parser/services/zip_extractor.dart';
import '../../chat_setup/presentation/chat_setup_screen.dart';
import '../../../services/analytics/analytics_service.dart';

class ImportScreen extends StatefulWidget {
  final String? preloadedFilePath;

  const ImportScreen({super.key, this.preloadedFilePath});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isProcessing = false;
  String? _statusText;
  String? _errorMessage;
  ParseResult? _parseResult;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedFilePath != null) {
      _processFilePath(widget.preloadedFilePath!);
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      AnalyticsService.logEvent('import_started');

      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'zip'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        final filePath = files.first.path!;
        _fileName = files.first.name;
        await _processFilePath(filePath);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access file picker: $e';
      });
      AnalyticsService.logEvent('import_failed', {'error_category': 'picker'});
    }
  }

  Future<void> _processFilePath(String filePath) async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Reading export file...';
      _errorMessage = null;
      _parseResult = null;
    });

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const ParsingException('Selected file does not exist.', code: 'FILE_MISSING');
      }

      final fileSize = await file.length();
      if (fileSize > AppConstants.maxFileSizeBytes) {
        throw const ParsingException(
          'File is larger than 50MB. Please export a chat without media.',
          code: 'FILE_TOO_LARGE',
        );
      }

      String chatText;
      if (filePath.toLowerCase().endsWith('.zip')) {
        setState(() => _statusText = 'Extracting chat text from ZIP...');
        chatText = await ZipExtractor.extractFromFile(filePath);
      } else {
        setState(() => _statusText = 'Reading text file...');
        chatText = await file.readAsString();
      }

      setState(() => _statusText = 'Parsing WhatsApp messages & dates...');
      await Future.delayed(const Duration(milliseconds: 100));

      final parseResult = ChatParser.parse(chatText);

      setState(() {
        _parseResult = parseResult;
        _isProcessing = false;
      });

      AnalyticsService.logEvent('import_success', {
        'size_bucket': AnalyticsService.getCoarseSizeBucket(parseResult.messages.length),
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e is AppException ? e.message : 'Failed to parse file: $e';
      });
      AnalyticsService.logEvent('import_failed', {'error_category': 'parsing'});
    }
  }

  void _proceedToSetup() {
    if (_parseResult == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatSetupScreen(parseResult: _parseResult!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _parseResult;
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
                  const WrappedPill(label: 'STEP 1 OF 3'),
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
                            TextSpan(text: 'Drop in\n'),
                            TextSpan(text: 'a chat.', style: TextStyle(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn.stagger(1, child: _buildPickerCard(result)),
                    const SizedBox(height: 12),
                    if (_isProcessing) _buildProcessingCard(),
                    if (_errorMessage != null) _buildErrorCard(),
                    if (result != null)
                      FadeSlideIn(child: _buildParsedSummaryCard(result))
                    else if (!_isProcessing)
                      FadeSlideIn.stagger(2, child: _buildHowToCard()),
                  ],
                ),
              ),
              if (result != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: result.isValid ? _proceedToSetup : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    result.isValid
                        ? 'Continue'
                        : 'Need at least ${AppConstants.minMessagesRequired} messages',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerCard(ParseResult? result) {
    final done = result != null;
    final ink = done ? AppColors.textPrimary : AppColors.onAccent;
    return WrappedCard(
      color: done ? AppColors.surfaceCard : AppColors.primary,
      borderColor: done ? AppColors.primary : null,
      onTap: _isProcessing ? null : _pickFile,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? 'FILE LOADED' : 'TAP TO CHOOSE',
                  style: AppTypography.labelSmall.copyWith(
                    color: done ? AppColors.primary : AppColors.onAccent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _fileName ?? (done ? 'Shared chat' : '.txt or .zip\nexport'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(color: ink, fontSize: 22),
                ),
                if (done) ...[
                  const SizedBox(height: 6),
                  const Text('Tap to pick a different file', style: AppTypography.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_isProcessing || done)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : AppColors.onAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.hourglass_top_rounded,
                color: done ? AppColors.onAccent : AppColors.primary,
                size: 30,
              ),
            )
          else
            Pulse(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: AppColors.onAccent, shape: BoxShape.circle),
                child: const Icon(Icons.upload_rounded, color: AppColors.primary, size: 30),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHowToCard() {
    const steps = [
      'Open the chat in WhatsApp',
      'Tap ⋮  ›  More  ›  Export chat',
      'Pick “Without media”',
      'Share to this app, or save it and choose it above',
    ];
    return WrappedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HOW TO EXPORT', style: AppTypography.labelSmall),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i.isEven ? AppColors.primary : AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(steps[i], style: AppTypography.bodyLarge)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Parsed on your phone. Nothing is uploaded at this step.',
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WrappedCard(
        child: Row(
          children: [
            const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 16),
            Expanded(child: Text(_statusText ?? 'Processing...', style: AppTypography.bodyLarge)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WrappedCard(
        borderColor: AppColors.accentRed,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.accentRed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Couldn't read that file",
                    style: AppTypography.labelLarge.copyWith(color: AppColors.accentRed),
                  ),
                  const SizedBox(height: 4),
                  Text(_errorMessage!, style: AppTypography.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedSummaryCard(ParseResult result) {
    final meta = result.metadata;
    final fmt = DateFormat('d MMM yyyy');
    final dateRangeStr = (meta.startDate != null && meta.endDate != null)
        ? '${fmt.format(meta.startDate!)} → ${fmt.format(meta.endDate!)}'
        : 'Unknown date range';

    return WrappedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('WE FOUND', style: AppTypography.labelSmall)),
              Text(
                '${result.parsingTimeMs}ms',
                style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CountUp(
                value: meta.totalMessages,
                style: AppTypography.number(size: 56, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text('messages', style: AppTypography.bodyLarge),
            ],
          ),
          const SizedBox(height: 6),
          Text(dateRangeStr, style: AppTypography.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: StatTile(value: '${meta.participants.length}', label: 'people')),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '${meta.totalMedia}',
                  label: 'media',
                  valueColor: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: StatTile(value: '${meta.totalDeleted}', label: 'deleted')),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < meta.participants.length; i++)
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: i.isEven ? AppColors.primary : AppColors.secondary,
                        child: Text(
                          initialsOf(meta.participants[i]),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onAccent,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${meta.participants[i]} · ${formatCount(meta.messageCountByParticipant[meta.participants[i]] ?? 0)}',
                        style: AppTypography.labelLarge,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (meta.warnings.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...meta.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.accentAmber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        w,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.accentAmber),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
