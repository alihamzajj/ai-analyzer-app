import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/vibe_logo.dart';
import '../../../core/constants/app_constants.dart';
import 'onboarding_screen.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 2100));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingDone = prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => onboardingDone ? const HomeScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              const _Bubble(
                text: 'did you see my msg?? 👀',
                color: AppColors.surfaceElevated,
                textColor: AppColors.textPrimary,
                delay: 100,
                alignRight: false,
              ),
              const SizedBox(height: 10),
              const _Bubble(
                text: 'haha ok',
                color: AppColors.secondary,
                textColor: AppColors.onAccent,
                delay: 420,
                alignRight: true,
              ),
              const SizedBox(height: 10),
              const _Bubble(
                text: 'so… what does that mean 😭',
                color: AppColors.primary,
                textColor: AppColors.onAccent,
                delay: 740,
                alignRight: false,
              ),
              const SizedBox(height: 44),
              FadeSlideIn(
                delay: const Duration(milliseconds: 1100),
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.displayLarge.copyWith(fontSize: 46),
                    children: const [
                      TextSpan(text: 'Your chats,\n'),
                      TextSpan(text: 'decoded.', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 4),
              FadeSlideIn(
                delay: const Duration(milliseconds: 1400),
                child: Row(
                  children: [
                    const VibeLogo(size: 30),
                    const SizedBox(width: 10),
                    Text(
                      'VIBE CHECK · PRIVATE BY DESIGN',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final int delay;
  final bool alignRight;

  const _Bubble({
    required this.text,
    required this.color,
    required this.textColor,
    required this.delay,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: FadeSlideIn(
        delay: Duration(milliseconds: delay),
        offset: Offset(alignRight ? 30 : -30, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(alignRight ? 22 : 6),
              bottomRight: Radius.circular(alignRight ? 6 : 22),
            ),
          ),
          child: Text(text, style: AppTypography.bodyLarge.copyWith(color: textColor)),
        ),
      ),
    );
  }
}
