import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/roman_urdu.dart';
import '../../chat_parser/models/parse_result.dart';
import '../models/chat_setup_config.dart';
import '../../statistics/services/statistics_engine.dart';
import '../../statistics/presentation/statistics_dashboard_screen.dart';

class ChatSetupScreen extends StatefulWidget {
  final ParseResult parseResult;

  const ChatSetupScreen({super.key, required this.parseResult});

  @override
  State<ChatSetupScreen> createState() => _ChatSetupScreenState();
}

class _ChatSetupScreenState extends State<ChatSetupScreen> {
  late String _selectedUser;
  late String _relationshipType;
  String _outputLanguage = 'en';
  bool _detectedRomanUrdu = false;
  String _roastIntensity = 'spicy';
  bool _enableRoast = true;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    final participants = widget.parseResult.metadata.participants;
    _selectedUser = participants.isNotEmpty ? participants.first : 'User';
    _relationshipType = widget.parseResult.metadata.isGroupChat ? 'group' : 'crush';
    _adjustRoastForRelationship();

    // Pakistani chats are usually typed in Roman Urdu; answer in the same style.
    _detectedRomanUrdu = RomanUrdu.isMostlyRomanUrdu(
      widget.parseResult.messages.map((m) => m.content),
    );
    if (_detectedRomanUrdu) _outputLanguage = RomanUrdu.languageCode;
  }

  void _adjustRoastForRelationship() {
    if (_relationshipType == 'work') {
      _enableRoast = false;
    }
  }

  Future<void> _calculateStatisticsAndProceed() async {
    setState(() => _isCalculating = true);

    final config = ChatSetupConfig(
      userParticipantName: _selectedUser,
      relationshipType: _relationshipType,
      outputLanguage: _outputLanguage,
      roastIntensity: _roastIntensity,
      enableRoast: _enableRoast,
    );

    // Calculate free statistics in background isolate
    final stats = await StatisticsEngine.calculateAsync(widget.parseResult.messages);

    if (!mounted) return;
    setState(() => _isCalculating = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatisticsDashboardScreen(
          parseResult: widget.parseResult,
          statistics: stats,
          config: config,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participants = widget.parseResult.metadata.participants;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat Setup', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Question 1: Who are you?
                    const Text('Which participant are you?', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'Used to calculate your personal response times, double-texts, and balance.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: participants.map((p) {
                        final isSelected = p == _selectedUser;
                        return ChoiceChip(
                          label: Text(p),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceCard,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.onAccent : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedUser = p);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // Question 2: Relationship type
                    const Text('Relationship Type', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.relationshipTypes.map((type) {
                        final isSelected = type == _relationshipType;
                        return ChoiceChip(
                          label: Text(type[0].toUpperCase() + type.substring(1)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceCard,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.onAccent : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _relationshipType = type;
                                _adjustRoastForRelationship();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // Question 3: Output language
                    const Text('Output Language', style: AppTypography.titleMedium),
                    if (_detectedRomanUrdu) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Roman Urdu chat detected, so results will be in Roman Urdu. You can change this.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _outputLanguage,
                          dropdownColor: AppColors.surfaceElevated,
                          isExpanded: true,
                          items: AppConstants.supportedLanguages.map((lang) {
                            return DropdownMenuItem<String>(
                              value: lang['code'],
                              child: Text(
                                lang['name']!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _outputLanguage = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Question 4: Roast Mode
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _enableRoast
                              ? AppColors.roastAccent.withValues(alpha: 0.5)
                              : AppColors.surfaceBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    color: _enableRoast
                                        ? AppColors.roastAccent
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Roast Mode', style: AppTypography.titleMedium),
                                ],
                              ),
                              Switch(
                                value: _enableRoast,
                                activeThumbColor: AppColors.roastAccent,
                                onChanged: _relationshipType == 'work'
                                    ? null
                                    : (val) => setState(() => _enableRoast = val),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _relationshipType == 'work'
                                ? 'Roast mode is disabled for professional/work relationships.'
                                : 'Playfully roasts your texting quirks, response lags, and typing habits.',
                            style: AppTypography.bodySmall,
                          ),
                          if (_enableRoast) ...[
                            const SizedBox(height: 16),
                            const Text('Roast Intensity', style: AppTypography.bodySmall),
                            const SizedBox(height: 8),
                            Row(
                              children: AppConstants.roastIntensities.map((intensity) {
                                final isSelected = intensity == _roastIntensity;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: isSelected
                                            ? AppColors.roastAccent.withValues(alpha: 0.2)
                                            : AppColors.surfaceElevated,
                                        side: BorderSide(
                                          color: isSelected
                                              ? AppColors.roastAccent
                                              : AppColors.surfaceBorder,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () =>
                                          setState(() => _roastIntensity = intensity),
                                      child: Text(
                                        intensity[0].toUpperCase() + intensity.substring(1),
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.roastAccent
                                              : AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              ElevatedButton(
                onPressed: _isCalculating ? null : _calculateStatisticsAndProceed,
                child: _isCalculating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
                      )
                    : const Text('Calculate Free Statistics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
