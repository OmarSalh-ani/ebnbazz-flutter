import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable id for this app install, sent with FCM registration so the server
/// can drop older tokens from the same phone.
class PushInstallationId {
  static const _key = 'push_installation_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = const Uuid().v4();
    await prefs.setString(_key, id);
    return id;
  }
}
