import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

/// Random per-install ID sent to the backend for fair-use rate limiting.
/// Not linked to the user's name, phone number or chats.
class AnonymousId {
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(AppConstants.keyAnonymousUserId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(AppConstants.keyAnonymousUserId, id);
    }
    return _cached = id;
  }
}
