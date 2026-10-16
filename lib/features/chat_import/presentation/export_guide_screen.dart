import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/wrapped_widgets.dart';
import 'import_screen.dart';

/// Animated walkthrough of exporting a WhatsApp chat. A drawn phone mockup
/// plays each step with a pulsing tap target; Android and iPhone flows differ.
class ExportGuideScreen extends StatefulWidget {
  /// Show a "pick the file" button that continues to the import screen.
  final bool showImportButton;

  const ExportGuideScreen({super.key, this.showImportButton = true});

  @override
  State<ExportGuideScreen> createState() => _ExportGuideScreenState();
}

enum _Platform { android, iphone }

class _GuideStep {
  final String title;
  final String caption;
  final Widget Function() screen;

  /// Tap target in mockup pixels (240 x 480), or null for no tap.
  final Offset? tap;

  const _GuideStep(this.title, this.caption, this.screen, this.tap);
}

class _ExportGuideScreenState extends State<ExportGuideScreen> {
  static const _stepDuration = Duration(milliseconds: 2800);

  _Platform _platform = _Platform.android;
  int _step = 0;
  bool _autoPlay = true;
  Timer? _timer;

  List<_GuideStep> get _steps => _platform == _Platform.android ? _androidSteps : _iphoneSteps;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_autoPlay) return;
    _timer = Timer.periodic(_stepDuration, (_) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % _steps.length);
    });
  }

  void _goTo(int step) {
    setState(() {
      _step = step.clamp(0, _steps.length - 1);
      _autoPlay = false;
    });
    _startTimer();
  }

  void _togglePlay() {
    setState(() {
      _autoPlay = !_autoPlay;
      if (_autoPlay && _step == _steps.length - 1) _step = 0;
    });
    _startTimer();
  }

  void _setPlatform(_Platform p) {
    if (p == _platform) return;
    setState(() {
      _platform = p;
      _step = 0;
      _autoPlay = true;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final current = steps[_step];

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
                  _PlatformToggle(value: _platform, onChanged: _setPlatform),
                ],
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  style: AppTypography.displayMedium.copyWith(fontSize: 28),
                  children: const [
                    TextSpan(text: 'Export a chat '),
                    TextSpan(text: 'in 4 taps', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => _goTo(_step == steps.length - 1 ? 0 : _step + 1),
                    child: AspectRatio(
                      aspectRatio: 240 / 480,
                      child: _PhoneFrame(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(
                              scale: Tween(begin: 0.97, end: 1.0).animate(anim),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey('${_platform.name}-$_step'),
                            child: Stack(
                              children: [
                                Positioned.fill(child: current.screen()),
                                if (current.tap != null) _TapHint(at: current.tap!),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'STEP ${_step + 1} OF ${steps.length}',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                  ),
                  const Spacer(),
                  for (var i = 0; i < steps.length; i++)
                    GestureDetector(
                      onTap: () => _goTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(left: 5),
                        width: i == _step ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _step ? AppColors.primary : AppColors.surfaceBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, ?current],
                ),
                child: Column(
                  key: ValueKey('caption-${_platform.name}-$_step'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current.title, style: AppTypography.titleLarge),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 40,
                      child: Text(current.caption, style: AppTypography.bodyMedium, maxLines: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _RoundButton(icon: Icons.chevron_left_rounded, onTap: _step > 0 ? () => _goTo(_step - 1) : null),
                  const SizedBox(width: 8),
                  _RoundButton(
                    icon: _autoPlay ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onTap: _togglePlay,
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _step < steps.length - 1 ? () => _goTo(_step + 1) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.showImportButton) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const ImportScreen()),
                          );
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                      child: Text(widget.showImportButton ? 'Pick my file' : 'Got it'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step definitions (mockup coordinates are 240 x 480).

  static final List<_GuideStep> _androidSteps = [
    _GuideStep(
      'Open the chat',
      'Open the WhatsApp chat you want to analyse, then tap ⋮ at the top right.',
      () => const _AndroidChat(),
      const Offset(229, 42),
    ),
    _GuideStep(
      'Tap “More”',
      'It’s the last option in the menu.',
      () => const _AndroidChat(overlay: _AndroidMenu(items: _androidMenu1)),
      const Offset(196, 225),
    ),
    _GuideStep(
      'Tap “Export chat”',
      'This creates a text copy of your messages.',
      () => const _AndroidChat(overlay: _AndroidMenu(items: _androidMenu2, highlight: 3)),
      const Offset(196, 135),
    ),
    _GuideStep(
      'Choose “Without media”',
      'Photos and videos aren’t needed. The file stays small and private.',
      () => const _AndroidChat(overlay: _AndroidExportDialog()),
      const Offset(206, 256),
    ),
    _GuideStep(
      'Pick Chat Wrapped',
      'Choose Chat Wrapped in the share list. It opens with your chat ready.',
      () => const _AndroidChat(overlay: _ShareSheet(ios: false)),
      const Offset(40, 344),
    ),
    _GuideStep(
      'That’s it!',
      'Your chat is loaded. Tap continue to see your stats and AI insights.',
      () => const _SuccessScreen(),
      null,
    ),
  ];

  static final List<_GuideStep> _iphoneSteps = [
    _GuideStep(
      'Open the chat',
      'Open the WhatsApp chat, then tap the person’s name at the top.',
      () => const _IosChat(),
      const Offset(120, 40),
    ),
    _GuideStep(
      'Tap “Export Chat”',
      'Scroll down on the contact info page and tap Export Chat.',
      () => const _IosContactInfo(),
      const Offset(150, 351),
    ),
    _GuideStep(
      'Choose “Without Media”',
      'Photos and videos aren’t needed. The file stays small and private.',
      () => const _IosChat(overlay: _IosActionSheet()),
      const Offset(178, 410),
    ),
    _GuideStep(
      'Pick Chat Wrapped',
      'Choose Chat Wrapped in the share sheet. It opens with your chat ready.',
      () => const _IosChat(overlay: _ShareSheet(ios: true)),
      const Offset(40, 344),
    ),
    _GuideStep(
      'That’s it!',
      'Your chat is loaded. Tap continue to see your stats and AI insights.',
      () => const _SuccessScreen(),
      null,
    ),
  ];

  static const _androidMenu1 = [
    'View contact',
    'Media, links, and docs',
    'Search',
    'Mute notifications',
    'Disappearing messages',
    'Wallpaper',
    'More  ›',
  ];

  static const _androidMenu2 = ['Report', 'Block', 'Clear chat', 'Export chat', 'Add shortcut'];
}

// -----------------------------------------------------------------------------
// Chrome around the mockup.

class _PlatformToggle extends StatelessWidget {
  final _Platform value;
  final ValueChanged<_Platform> onChanged;

  const _PlatformToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(_Platform p, String label) {
      final selected = p == value;
      return Pressable(
        onTap: () => onChanged(p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: selected ? AppColors.onAccent : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option(_Platform.android, 'Android'), option(_Platform.iphone, 'iPhone')],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, color: onTap == null ? AppColors.textDisabled : AppColors.textPrimary),
      ),
    );
  }
}

/// Rounded phone body. Content is laid out at 240 x 480 and scaled to fit.
class _PhoneFrame extends StatelessWidget {
  final Widget child;

  const _PhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF05090A),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(width: 240, height: 480, child: child),
        ),
      ),
    );
  }
}

/// Pulsing finger marker at a mockup coordinate.
class _TapHint extends StatelessWidget {
  final Offset at;

  const _TapHint({required this.at});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - 22,
      top: at.dy - 22,
      child: IgnorePointer(
        child: FadeSlideIn(
          delay: const Duration(milliseconds: 450),
          offset: const Offset(18, 26),
          child: Pulse(
            maxScale: 1.18,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.45),
                border: Border.all(color: AppColors.primary, width: 2.5),
              ),
              child: const Icon(Icons.touch_app_rounded, color: AppColors.onAccent, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Mock screens. A neutral messenger look (no third-party logos).

const _waGreen = Color(0xFF0B6E5F);
const _waWallpaper = Color(0xFFECE5DD);
const _waOut = Color(0xFFD9FDD3);
const _ink = Color(0xFF111B21);
const _subInk = Color(0xFF667781);

TextStyle _t(double size, {Color color = _ink, FontWeight weight = FontWeight.w400}) =>
    TextStyle(fontFamily: AppTypography.sans, fontSize: size, color: color, fontWeight: weight, height: 1.25);

class _StatusBar extends StatelessWidget {
  final Color color;
  final Color ink;

  const _StatusBar({required this.color, this.ink = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('9:41', style: _t(8, color: ink, weight: FontWeight.w700)),
          const Spacer(),
          Icon(Icons.signal_cellular_alt_rounded, size: 9, color: ink),
          const SizedBox(width: 3),
          Icon(Icons.battery_full_rounded, size: 10, color: ink),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool mine;

  const _Bubble(this.text, {this.mine = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 170),
        decoration: BoxDecoration(
          color: mine ? _waOut : Colors.white,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(text, style: _t(9.5)),
      ),
    );
  }
}

const _chatBubbles = [
  _Bubble('kya kar rahe ho?'),
  _Bubble('kuch nahi yaar, tum batao \u{1F604}', mine: true),
  _Bubble('kal cricket? 6 baje'),
  _Bubble('done! late mat hona', mine: true),
  _Bubble('hahaha ok ok'),
];

class _ChatBody extends StatelessWidget {
  const _ChatBody();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: _waWallpaper,
        child: Column(
          children: [
            const SizedBox(height: 10),
            ..._chatBubbles,
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(8),
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              alignment: Alignment.centerLeft,
              child: Text('Message', style: _t(9, color: _subInk)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final double size;

  const _Avatar({this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
      child: Text('S', style: _t(size * 0.45, color: AppColors.onAccent, weight: FontWeight.w700)),
    );
  }
}

class _AndroidChat extends StatelessWidget {
  final Widget? overlay;

  const _AndroidChat({this.overlay});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const _StatusBar(color: _waGreen),
            Container(
              height: 48,
              color: _waGreen,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  const _Avatar(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sam', style: _t(11, color: Colors.white, weight: FontWeight.w700)),
                        Text('online', style: _t(8, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.videocam, size: 14, color: Colors.white),
                  const SizedBox(width: 10),
                  const Icon(Icons.call, size: 13, color: Colors.white),
                  const SizedBox(width: 8),
                  const Icon(Icons.more_vert, size: 15, color: Colors.white),
                ],
              ),
            ),
            const _ChatBody(),
          ],
        ),
        if (overlay != null) Positioned.fill(child: overlay!),
      ],
    );
  }
}

class _AndroidMenu extends StatelessWidget {
  final List<String> items;
  final int? highlight;

  const _AndroidMenu({required this.items, this.highlight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 6,
          top: 22,
          width: 150,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++)
                  Container(
                    height: 30,
                    color: i == highlight || (highlight == null && i == items.length - 1)
                        ? const Color(0xFFE9EDEF)
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    child: Text(items[i], style: _t(9.5)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dim extends StatelessWidget {
  final Widget child;

  const _Dim({required this.child});

  @override
  Widget build(BuildContext context) => Container(color: const Color(0x66000000), child: child);
}

class _AndroidExportDialog extends StatelessWidget {
  const _AndroidExportDialog();

  @override
  Widget build(BuildContext context) {
    return _Dim(
      child: Stack(
        children: [
          Positioned(
            left: 20,
            right: 20,
            top: 168,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export chat', style: _t(12, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'Including media will increase the size of the chat export.',
                    style: _t(9, color: _subInk),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _waGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('WITHOUT MEDIA', style: _t(9, color: _waGreen, weight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text('INCLUDE MEDIA', style: _t(9, color: _waGreen, weight: FontWeight.w700)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text('CANCEL', style: _t(9, color: _waGreen, weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final bool ios;

  const _ShareSheet({required this.ios});

  @override
  Widget build(BuildContext context) {
    final apps = [
      ('Chat\nWrapped', AppColors.primary, true),
      ('Gmail', const Color(0xFFEA4335), false),
      ('Drive', const Color(0xFF34A853), false),
      ('Bluetooth', const Color(0xFF1E88E5), false),
      ('Messages', const Color(0xFF43A047), false),
      ('Files', const Color(0xFF5C6BC0), false),
      ('Telegram', const Color(0xFF29B6F6), false),
      ('More', const Color(0xFF9E9E9E), false),
    ];
    return _Dim(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 210,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: ios ? const Color(0xFFF2F2F7) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(color: const Color(0xFFBDBDBD), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 10),
              Text(ios ? 'WhatsApp Chat - Sam.zip' : 'Share chat via', style: _t(10, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 4,
                runSpacing: 10,
                children: [
                  for (final (label, color, ours) in apps)
                    SizedBox(
                      width: 50,
                      child: Column(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(ios ? 9 : 17),
                              border: ours ? Border.all(color: AppColors.onAccent, width: 2) : null,
                            ),
                            alignment: Alignment.center,
                            child: ours
                                ? const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.onAccent)
                                : Text(label[0], style: _t(12, color: Colors.white, weight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: _t(7.5, weight: ours ? FontWeight.w700 : FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IosChat extends StatelessWidget {
  final Widget? overlay;

  const _IosChat({this.overlay});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const _StatusBar(color: Color(0xFFF6F6F6), ink: _ink),
            Container(
              height: 46,
              color: const Color(0xFFF6F6F6),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_new, size: 12, color: Color(0xFF007AFF)),
                  const SizedBox(width: 6),
                  const _Avatar(size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sam', style: _t(11, weight: FontWeight.w700)),
                        Text('tap here for contact info', style: _t(7.5, color: _subInk)),
                      ],
                    ),
                  ),
                  const Icon(Icons.videocam_outlined, size: 15, color: Color(0xFF007AFF)),
                  const SizedBox(width: 10),
                  const Icon(Icons.call_outlined, size: 13, color: Color(0xFF007AFF)),
                ],
              ),
            ),
            const _ChatBody(),
          ],
        ),
        if (overlay != null) Positioned.fill(child: overlay!),
      ],
    );
  }
}

class _IosContactInfo extends StatelessWidget {
  const _IosContactInfo();

  @override
  Widget build(BuildContext context) {
    Widget row(String label, {Color color = _ink, bool highlight = false}) => Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFE5F0FF) : Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
          ),
          child: Text(label, style: _t(9.5, color: color, weight: highlight ? FontWeight.w700 : FontWeight.w400)),
        );

    return Container(
      color: const Color(0xFFF2F2F7),
      child: Column(
        children: [
          const _StatusBar(color: Color(0xFFF2F2F7), ink: _ink),
          const SizedBox(height: 10),
          const _Avatar(size: 52),
          const SizedBox(height: 6),
          Text('Sam', style: _t(13, weight: FontWeight.w700)),
          Text('+92 300 0000000', style: _t(8, color: _subInk)),
          const SizedBox(height: 14),
          row('Media, Links, and Docs'),
          row('Starred Messages'),
          row('Notifications'),
          row('Wallpaper & Sound'),
          const SizedBox(height: 12),
          row('Disappearing Messages'),
          row('Chat Lock'),
          const SizedBox(height: 12),
          row('Export Chat', color: const Color(0xFF007AFF), highlight: true),
          row('Clear Chat', color: const Color(0xFFFF3B30)),
          row('Block Sam', color: const Color(0xFFFF3B30)),
        ],
      ),
    );
  }
}

class _IosActionSheet extends StatelessWidget {
  const _IosActionSheet();

  @override
  Widget build(BuildContext context) {
    Widget option(String label, {bool bold = false, bool highlight = false}) => Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFE5F0FF) : Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
          ),
          child: Text(
            label,
            style: _t(10.5, color: const Color(0xFF007AFF), weight: bold || highlight ? FontWeight.w700 : FontWeight.w400),
          ),
        );

    return _Dim(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    option('Attach Media'),
                    option('Without Media', highlight: true),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(12), child: option('Cancel', bold: true)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text('FILE LOADED', style: AppTypography.labelSmall.copyWith(fontSize: 8, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: AppTypography.displayMedium.copyWith(fontSize: 24),
              children: const [
                TextSpan(text: 'Chat\n'),
                TextSpan(text: 'decoded.', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WE FOUND', style: AppTypography.labelSmall.copyWith(fontSize: 7, color: AppColors.onAccent)),
                      CountUp(value: 1248, style: AppTypography.number(size: 30, color: AppColors.onAccent)),
                      Text('messages', style: _t(9, color: AppColors.onAccent)),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(color: AppColors.onAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniTile('41d', 'streak', AppColors.secondary)),
              const SizedBox(width: 8),
              Expanded(child: _miniTile('4m', 'reply', AppColors.primary)),
            ],
          ),
          const Spacer(),
          Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(17)),
            child: Text('Continue', style: _t(10, color: AppColors.onAccent, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static Widget _miniTile(String value, String label, Color color) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.number(size: 18, color: color)),
            Text(label, style: _t(8, color: AppColors.textSecondary)),
          ],
        ),
      );
}
