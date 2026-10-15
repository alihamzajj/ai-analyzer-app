import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../home/presentation/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageStyle(bg: AppColors.background, ink: AppColors.textPrimary, accent: AppColors.primary),
    _PageStyle(bg: AppColors.primary, ink: AppColors.onAccent, accent: AppColors.onAccent),
    _PageStyle(bg: AppColors.secondary, ink: AppColors.onAccent, accent: AppColors.onAccent),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);
    AnalyticsService.logEvent('onboarding_complete');

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      color: style.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                child: Row(
                  children: [
                    Text(
                      '0${_currentPage + 1} / 0${_pages.length}',
                      style: AppTypography.labelSmall.copyWith(color: style.ink),
                    ),
                    const Spacer(),
                    if (!isLast)
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: AppTypography.labelLarge.copyWith(color: style.ink),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  children: const [_InsightsPage(), _RoastPage(), _PrivacyPage()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(_pages.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? style.ink : style.ink.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    Pressable(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 60,
                        padding: EdgeInsets.symmetric(horizontal: isLast ? 28 : 0),
                        width: isLast ? null : 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: style.bg == AppColors.background ? AppColors.primary : AppColors.onAccent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: isLast
                            ? Text(
                                "Let's go",
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              )
                            : Icon(
                                Icons.arrow_forward_rounded,
                                color: style.bg == AppColors.background
                                    ? AppColors.onAccent
                                    : AppColors.primary,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageStyle {
  final Color bg;
  final Color ink;
  final Color accent;
  const _PageStyle({required this.bg, required this.ink, required this.accent});
}

/// Shared layout: decorative stage on top, big headline + body below.
class _PageLayout extends StatelessWidget {
  final Widget stage;
  final InlineSpan headline;
  final String body;
  final Color ink;

  const _PageLayout({required this.stage, required this.headline, required this.body, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: stage),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Text.rich(
              headline,
              style: AppTypography.displayLarge.copyWith(color: ink, fontSize: 42),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: Text(
              body,
              style: AppTypography.bodyLarge.copyWith(color: ink.withValues(alpha: 0.75), fontSize: 16),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _InsightsPage extends StatelessWidget {
  const _InsightsPage();

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      ink: AppColors.textPrimary,
      headline: const TextSpan(
        children: [
          TextSpan(text: 'Who likes\nwho '),
          TextSpan(text: 'more?', style: TextStyle(color: AppColors.primary)),
        ],
      ),
      body: 'Interest scores, reply speed, who texts first and who double-texts. All from your WhatsApp export.',
      stage: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned(
              left: 0,
              top: c.maxHeight * 0.12,
              child: Floating(
                angle: -0.08,
                child: _MockCard(
                  color: AppColors.secondary,
                  width: 170,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INTEREST', style: AppTypography.labelSmall.copyWith(color: AppColors.onAccent)),
                      const SizedBox(height: 18),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            CountUp(value: 72, style: AppTypography.number(size: 58, color: AppColors.onAccent)),
                            Text('/100', style: AppTypography.bodyMedium.copyWith(color: AppColors.onAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: c.maxHeight * 0.02,
              child: Floating(
                angle: 0.07,
                phase: 0.35,
                child: _MockCard(
                  color: AppColors.surfaceElevated,
                  border: true,
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REPLY TIME', style: AppTypography.labelSmall),
                      const SizedBox(height: 12),
                      _row('You', '4m', AppColors.primary),
                      const SizedBox(height: 6),
                      _row('Them', '23m', AppColors.secondary),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: c.maxHeight * 0.52,
              child: Floating(
                angle: -0.04,
                phase: 0.7,
                child: _MockCard(
                  color: AppColors.primary,
                  width: 180,
                  child: Text(
                    '🚩 3 red flags\n💚 5 green flags',
                    style: AppTypography.titleMedium.copyWith(color: AppColors.onAccent, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _row(String name, String value, Color color) => Row(
        children: [
          Expanded(child: Text(name, style: AppTypography.bodyMedium)),
          Text(value, style: AppTypography.number(size: 24, color: color)),
        ],
      );
}

class _RoastPage extends StatelessWidget {
  const _RoastPage();

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      ink: AppColors.onAccent,
      headline: const TextSpan(text: 'Roasts.\nReceipts included.'),
      body: 'AI reads the vibe, then shows you the exact messages behind every claim. No made-up drama.',
      stage: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned(
              left: 0,
              top: c.maxHeight * 0.08,
              child: const Floating(
                angle: -0.05,
                child: _ChatBubble(text: 'i\'m not even mad lol', dark: true),
              ),
            ),
            Positioned(
              right: 0,
              top: c.maxHeight * 0.30,
              child: const Floating(
                angle: 0.05,
                phase: 0.4,
                child: _ChatBubble(text: 'k.', dark: false),
              ),
            ),
            Positioned(
              left: 24,
              bottom: c.maxHeight * 0.06,
              child: Floating(
                angle: 0.03,
                phase: 0.75,
                child: _MockCard(
                  color: AppColors.onAccent,
                  width: 230,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ROAST MODE · SPICY 🔥', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
                      const SizedBox(height: 10),
                      Text(
                        'Replies in 4 min, then pretends to be busy.',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Open a chat in WhatsApp'),
      ('2', 'More  ›  Export chat'),
      ('3', 'Without media  ›  share here'),
    ];
    return _PageLayout(
      ink: AppColors.onAccent,
      headline: const TextSpan(text: 'Private.\n3 taps to start.'),
      body: 'Stats run 100% on your phone. For AI reports, names become aliases and chats are never stored.',
      stage: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < steps.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 150 + i * 140),
              offset: const Offset(40, 0),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.onAccent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                      child: Text(steps[i].$1, style: AppTypography.titleMedium.copyWith(color: AppColors.onAccent)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(steps[i].$2, style: AppTypography.bodyLarge)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  final Color color;
  final double width;
  final bool border;
  final Widget child;

  const _MockCard({required this.color, required this.width, required this.child, this.border = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        border: border ? Border.all(color: AppColors.surfaceBorder) : null,
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: child,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool dark;

  const _ChatBubble({required this.text, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: dark ? AppColors.onAccent : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Text(
        text,
        style: AppTypography.titleMedium.copyWith(color: dark ? AppColors.textPrimary : AppColors.onAccent),
      ),
    );
  }
}
