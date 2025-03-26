import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  // Guardar el userId en SharedPreferences
  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userId', userId);
  }

  // Obtener el userId desde SharedPreferences
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Limpiar la sesión (por ejemplo, al hacer logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userId');
  }
}