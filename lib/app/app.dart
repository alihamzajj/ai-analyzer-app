import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import '../features/onboarding/presentation/splash_screen.dart';

class AiChatAnalyserApp extends StatelessWidget {
  const AiChatAnalyserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe Check',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
