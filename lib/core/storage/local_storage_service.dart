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

  Future<bool> saveUserId(String id) async {
    return await setString('user_id', id);
  }

  String? getUserId() {
    return getString('user_id');
  }

  Future<bool> saveUserName(String name) async {
    return await setString('user_name', name);
  }

  String? getUserName() {
    return getString('user_name');
  }

  Future<bool> saveUserEmail(String email) async {
    return await setString('user_email', email);
  }

  String? getUserEmail() {
    return getString('user_email');
  }

  Future<bool> saveUserPhone(String phone) async {
    return await setString('user_phone', phone);
  }

  String? getUserPhone() {
    return getString('user_phone');
  }

  Future<bool> saveUserAvatar(String avatar) async {
    return await setString('user_avatar', avatar);
  }

  String? getUserAvatar() {
    return getString('user_avatar');
  }

  Future<bool> saveRememberMe(bool value) async {
    return await setBool('remember_me', value);
  }

  bool getRememberMe() {
    return getBool('remember_me') ?? false;
  }

  Future<bool> saveIsLoggedIn(bool value) async {
    return await setBool('is_logged_in', value);
  }

  bool getIsLoggedIn() {
    return getBool('is_logged_in') ?? false;
  }

  Future<void> clearSession() async {
    await remove('auth_token');
    await remove('refresh_token');
    await remove('user_data');
    await remove('user_role');
    await remove('user_id');
    await remove('user_name');
    await remove('user_email');
    await remove('user_phone');
    await remove('user_avatar');
    await remove('is_logged_in');
    await remove('remember_me');
    await remove('user_country');
    await remove('user_timezone');
    await remove('user_language');
    await remove('user_status');
  }

  Future<bool> saveUserCountry(String? country) async {
    return country != null ? await setString('user_country', country) : await remove('user_country');
  }

  String? getUserCountry() {
    return getString('user_country');
  }

  Future<bool> saveUserTimezone(String? timezone) async {
    return timezone != null ? await setString('user_timezone', timezone) : await remove('user_timezone');
  }

  String? getUserTimezone() {
    return getString('user_timezone');
  }

  Future<bool> saveUserLanguage(String? language) async {
    return language != null ? await setString('user_language', language) : await remove('user_language');
  }

  String? getUserLanguage() {
    return getString('user_language');
  }

  Future<bool> saveUserStatus(String? status) async {
    return status != null ? await setString('user_status', status) : await remove('user_status');
  }

  String? getUserStatus() {
    return getString('user_status');
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
