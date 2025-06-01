import 'package:shared_preferences/shared_preferences.dart';

class PrefHelper {
  static Future<void> setString(String key, String value) async {
    // Implementation for setting a string in preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> remove(String key) async {
    // Implementation for removing a key from preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<String?> getString(String key) async {
    // Implementation for getting a string from preferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
