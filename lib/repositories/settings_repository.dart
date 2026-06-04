import '../core/api/api_client.dart';
import '../models/settings_model.dart';
import '../models/google_auth_url_model.dart';
import '../utils/app_logger.dart';

class SettingsRepository {
  static const _tag = 'SettingsRepository';
  final ApiClient _apiClient;

  SettingsRepository(this._apiClient);

  /// Fetch user settings from GET /v1/settings
  Future<SettingsModel> getUserSettings() async {
    AppLogger.i('[$_tag] Settings requested');
    final res = await _apiClient.get('settings');
    if (res.success && res.data != null) {
      final settings = SettingsModel.fromJson(res.data as Map<String, dynamic>);
      AppLogger.i('[$_tag] Settings loaded');
      AppLogger.i('[$_tag] Timezone received: ${settings.settings.timezone}');
      AppLogger.i('[$_tag] Language received: ${settings.settings.language}');
      AppLogger.i('[$_tag] Google Calendar status: ${settings.integrations.googleCalendar}');
      return settings;
    } else {
      AppLogger.e('[$_tag] API failures: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }

  /// Get Google Calendar Auth URL from GET /v1/settings/google/auth
  Future<GoogleAuthUrlModel> getGoogleCalendarAuthUrl() async {
    AppLogger.i('[$_tag] Google Calendar connect requested');
    final res = await _apiClient.get('settings/google/auth');
    if (res.success && res.data != null) {
      final authUrlModel = GoogleAuthUrlModel.fromJson(res.data as Map<String, dynamic>);
      AppLogger.i('[$_tag] Auth URL fetched successfully');
      return authUrlModel;
    } else {
      AppLogger.e('[$_tag] API failures: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }

  /// Disconnect Google Calendar using DELETE /v1/settings/google/disconnect
  Future<bool> disconnectGoogleCalendar() async {
    AppLogger.i('[$_tag] Disconnect requested');
    AppLogger.i('[$_tag] API called');
    final res = await _apiClient.delete('settings/google/disconnect');
    if (res.success) {
      AppLogger.i('[$_tag] Disconnect successful');
      return true;
    } else {
      AppLogger.e('[$_tag] API failures: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }
}
