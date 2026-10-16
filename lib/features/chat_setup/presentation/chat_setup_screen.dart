import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/roman_urdu.dart';
import '../../chat_parser/models/parse_result.dart';
import '../models/chat_setup_config.dart';
import '../../statistics/services/statistics_engine.dart';
import '../../statistics/presentation/statistics_dashboard_screen.dart';

/// Step 2 of 3: two quick questions (who are you, who are they), with
/// language and roast settings tucked under "More options".
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
  bool _showMore = false;

  static const Map<String, (String, String)> _relationshipLabels = {
    'crush': ('\u{1F60D}', 'Crush'),
    'partner': ('\u{2764}\u{FE0F}', 'Partner'),
    'ex': ('\u{1F494}', 'Ex'),
    'friend': ('\u{1F91D}', 'Friend'),
    'family': ('\u{1F3E0}', 'Family'),
    'group': ('\u{1F465}', 'Group'),
    'work': ('\u{1F4BC}', 'Work'),
  };

  static const Map<String, String> _roastLabels = {
    'gentle': '\u{1F642} Gentle',
    'spicy': '\u{1F336}\u{FE0F} Spicy',
    'savage': '\u{1F525} Savage',
  };

  @override
  void initState() {
    super.initState();
    final meta = widget.parseResult.metadata;
    // Default to the most active participant: usually the person who exported.
    final byCount = [...meta.participants]
      ..sort((a, b) => (meta.messageCountByParticipant[b] ?? 0).compareTo(meta.messageCountByParticipant[a] ?? 0));
    _selectedUser = byCount.isNotEmpty ? byCount.first : 'User';
    _relationshipType = meta.isGroupChat ? 'group' : 'crush';
    _adjustRoastForRelationship();

    // Roman Urdu chats are fully understood, but results stay in English by
    // default; the user can still pick Roman Urdu under "More options".
    _detectedRomanUrdu = RomanUrdu.isMostlyRomanUrdu(
      widget.parseResult.messages.map((m) => m.content),
    );
    _loadDefaultLanguage();
  }

  /// Uses the "Results language" chosen in Settings (English if never set).
  Future<void> _loadDefaultLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyAppLanguage);
    final known = AppConstants.supportedLanguages.any((l) => l['code'] == saved);
    if (saved != null && known && mounted) setState(() => _outputLanguage = saved);
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

  String get _languageName =>
      AppConstants.supportedLanguages.firstWhere(
        (l) => l['code'] == _outputLanguage,
        orElse: () => {'name': 'English'},
      )['name']!;

  @override
  Widget build(BuildContext context) {
    final meta = widget.parseResult.metadata;
    final participants = meta.participants;
    final types = meta.isGroupChat
        ? AppConstants.relationshipTypes
        : AppConstants.relationshipTypes.where((t) => t != 'group').toList();

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
                  const WrappedPill(label: 'STEP 2 OF 3'),
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
                            TextSpan(text: 'Which one\n'),
                            TextSpan(text: 'is you?', style: TextStyle(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeSlideIn.stagger(
                      1,
                      child: const Text(
                        'So we know whose replies are yours.',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn.stagger(
                      2,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final wide = participants.length <= 2;
                          final cardWidth = (c.maxWidth - 10) / 2;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (var i = 0; i < participants.length; i++)
                                _buildPersonCard(
                                  participants[i],
                                  meta.messageCountByParticipant[participants[i]] ?? 0,
                                  i,
                                  wide ? cardWidth : null,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeSlideIn.stagger(
                      3,
                      child: Text(
                        meta.isGroupChat ? 'What kind of group is this?' : 'And they are your…',
                        style: AppTypography.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn.stagger(
                      4,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final t in types) _buildRelationshipChip(t)],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn.stagger(5, child: _buildMoreOptions()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isCalculating ? null : _calculateStatisticsAndProceed,
                icon: _isCalculating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(_isCalculating ? 'Crunching your chat...' : 'See my stats'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Big card for 1:1 chats ([width] set), compact pill for groups.
  Widget _buildPersonCard(String name, int count, int index, double? width) {
    final selected = name == _selectedUser;
    final avatarColor = index.isEven ? AppColors.primary : AppColors.secondary;
    final wide = width != null;
    return Pressable(
      onTap: () => setState(() => _selectedUser = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: wide ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(6, 6, 16, 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(wide ? 26 : 40),
          border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceBorder, width: 1.5),
        ),
        child: wide
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _avatar(name, selected ? AppColors.onAccent : avatarColor, selected, 46),
                      const Spacer(),
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: selected ? AppColors.onAccent : AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: selected ? AppColors.onAccent : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${formatCount(count)} messages',
                    style: AppTypography.bodySmall.copyWith(
                      color: selected ? AppColors.onAccent.withValues(alpha: 0.7) : AppColors.textMuted,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _avatar(name, selected ? AppColors.onAccent : avatarColor, selected, 34),
                  const SizedBox(width: 10),
                  Text(
                    name,
                    style: AppTypography.labelLarge.copyWith(
                      color: selected ? AppColors.onAccent : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _avatar(String name, Color color, bool selected, double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initialsOf(name),
        style: AppTypography.labelLarge.copyWith(
          color: selected ? AppColors.primary : AppColors.onAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRelationshipChip(String type) {
    final selected = type == _relationshipType;
    final (emoji, label) = _relationshipLabels[type] ?? ('', type);
    return Pressable(
      onTap: () => setState(() {
        _relationshipType = type;
        _adjustRoastForRelationship();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: selected ? AppColors.secondary : AppColors.surfaceBorder, width: 1.5),
        ),
        child: Text(
          '$emoji  $label',
          style: AppTypography.labelLarge.copyWith(
            color: selected ? AppColors.onAccent : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOptions() {
    final roastSummary = _enableRoast ? _roastLabels[_roastIntensity]! : 'Roast off';
    return WrappedCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showMore = !_showMore),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('More options', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('$_languageName results · $roastSummary', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _showMore ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _showMore ? _buildMoreOptionsBody() : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreOptionsBody() {
    final roastLocked = _relationshipType == 'work';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text('RESULTS LANGUAGE', style: AppTypography.labelSmall),
        if (_detectedRomanUrdu) ...[
          const SizedBox(height: 6),
          Text(
            'Roman Urdu chat detected. We read it fully either way.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _outputLanguage,
              dropdownColor: AppColors.surfaceElevated,
              isExpanded: true,
              style: AppTypography.bodyLarge,
              items: [
                for (final lang in AppConstants.supportedLanguages)
                  DropdownMenuItem<String>(value: lang['code'], child: Text(lang['name']!)),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _outputLanguage = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Text('ROAST MODE \u{1F525}', style: AppTypography.labelSmall)),
            Switch(
              value: _enableRoast,
              onChanged: roastLocked ? null : (val) => setState(() => _enableRoast = val),
            ),
          ],
        ),
        Text(
          roastLocked ? 'Off for work chats.' : 'Playful jokes about texting habits only, never personal.',
          style: AppTypography.bodySmall,
        ),
        if (_enableRoast) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final intensity in AppConstants.roastIntensities)
                Pressable(
                  onTap: () => setState(() => _roastIntensity = intensity),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: intensity == _roastIntensity ? AppColors.secondary : AppColors.surface,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: intensity == _roastIntensity ? AppColors.secondary : AppColors.surfaceBorder,
                      ),
                    ),
                    child: Text(
                      _roastLabels[intensity] ?? intensity,
                      style: AppTypography.labelLarge.copyWith(
                        color: intensity == _roastIntensity ? AppColors.onAccent : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
