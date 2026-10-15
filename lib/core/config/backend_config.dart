/// Supabase connection settings for the AI backend.
///
/// The anon/publishable key is designed to ship inside apps (access is
/// controlled by Row Level Security and the Edge Function), so it is safe to
/// keep here. Never put the service_role key, the database password or the
/// Gemini key in the app; the Gemini key lives in Supabase secrets.
///
/// Values can be overridden at build time:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class BackendConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// False until both values are set; the app then uses the offline demo AI.
  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
