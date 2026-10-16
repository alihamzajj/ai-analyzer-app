import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/config/backend_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Real AI runs through the Supabase Edge Function; without config the app
  // falls back to the offline demo report.
  if (BackendConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: BackendConfig.supabaseUrl,
        publishableKey: BackendConfig.supabaseAnonKey,
      );
      // Silent per-install login used for fair-use limits; never blocks startup.
      final auth = Supabase.instance.client.auth;
      if (auth.currentSession == null) {
        auth.signInAnonymously().catchError((Object e) {
          debugPrint('[main] Anonymous sign-in deferred: $e');
          return AuthResponse();
        });
      }
    } catch (e) {
      debugPrint('[main] Supabase init failed, using offline demo AI: $e');
    }
  }

  runApp(const AiChatAnalyserApp());
}
