/// Application-wide constants for AI Chat Analyser.
class AppConstants {
  static const String appName = 'AI Chat Analyser';
  static const String appVersion = '1.0.0';

  // File & Parsing Limits
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int maxDigestMessages = 1500; // Sample limit for AI digest to stay within token budget
  static const int minMessagesRequired = 10;

  // Subscriptions & Entitlements
  static const String entitlementPro = 'pro_access';
  static const String weeklyProductId = 'chat_analyser_weekly_599';
  static const String yearlyProductId = 'chat_analyser_yearly_3999';
  static const double draftWeeklyPriceUsd = 5.99;
  static const double draftYearlyPriceUsd = 39.99;
  static const int weeklyDeepAnalysisAllowance = 10;

  // Storage Keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keySavedReports = 'saved_reports_v1';
  static const String keyDigestCache = 'digest_cache_v1';
  static const String keyAppLanguage = 'app_language';
  static const String keyAnonymousUserId = 'anonymous_user_id';

  // Backend Function Names
  static const String functionAnalyseChat = 'analyse-chat';

  // Relationship Types
  static const List<String> relationshipTypes = [
    'crush',
    'partner',
    'ex',
    'friend',
    'family',
    'group',
    'work',
  ];

  // Roast Intensities
  static const List<String> roastIntensities = [
    'gentle',
    'spicy',
    'savage',
  ];

  // Supported Output Languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Spanish (Español)'},
    {'code': 'fr', 'name': 'French (Français)'},
    {'code': 'de', 'name': 'German (Deutsch)'},
    {'code': 'pt', 'name': 'Portuguese (Português)'},
    {'code': 'it', 'name': 'Italian (Italiano)'},
    {'code': 'ar', 'name': 'Arabic (العربية)'},
    {'code': 'hi', 'name': 'Hindi (हिन्दी)'},
  ];
}
