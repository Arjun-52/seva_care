import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // ─── Core Key/Value Operations ────────────────

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clear() async {
    return await _prefs.clear();
  }

  // ─── App Specific Helper Methods ──────────────

  Future<bool> saveAuthToken(String token) async {
    return await setString('auth_token', token);
  }

  String? getAuthToken() {
    return getString('auth_token');
  }

  Future<bool> saveRefreshToken(String token) async {
    return await setString('refresh_token', token);
  }

  String? getRefreshToken() {
    return getString('refresh_token');
  }

  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    return await setString('user_data', jsonEncode(userData));
  }

  Map<String, dynamic>? getUserData() {
    final raw = getString('user_data');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveUserRole(String role) async {
    return await setString('user_role', role);
  }

  String? getUserRole() {
    return getString('user_role');
  }

  Future<bool> saveLanguageCode(String code) async {
    return await setString('language_code', code);
  }

  String? getLanguageCode() {
    return getString('language_code');
  }

  Future<bool> saveDarkTheme(bool isDark) async {
    return await setBool('dark_theme', isDark);
  }

  bool getDarkTheme() {
    return getBool('dark_theme') ?? false;
  }
}
