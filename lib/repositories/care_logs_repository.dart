import '../core/api/api_client.dart';
import '../models/care_logs_response.dart';
import '../models/care_log_today_response.dart';
import '../utils/app_logger.dart';

class CareLogsRepository {
  static const _tag = 'CareLogsRepository';
  final ApiClient _apiClient;

  CareLogsRepository(this._apiClient);

  /// Fetch care logs from GET /v1/care-logs
  Future<CareLogsResponse> getCareLogs({
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.i('[$_tag] Care logs request started');
    AppLogger.i('[$_tag] Current page: $page');

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final res = await _apiClient.get('care-logs', queryParams: queryParams);
    if (res.success) {
      AppLogger.i('[$_tag] Care logs fetched successfully');
      final response = CareLogsResponse.fromJson(res.data, res.pagination);
      AppLogger.i('[$_tag] Parsing success. Loaded ${response.logs.length} logs');
      return response;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Fetch care logs failed / Parsing failure: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Fetch today's care logs from GET /v1/care-logs/today/:seniorId
  Future<CareLogTodayResponse> getTodayCareLogs({
    required String seniorId,
  }) async {
    AppLogger.i('[$_tag] Today care logs requested');
    AppLogger.i('[$_tag] seniorId used: $seniorId');

    final res = await _apiClient.get('care-logs/today/$seniorId');
    if (res.success) {
      AppLogger.i('[$_tag] API success');
      final response = CareLogTodayResponse.fromJson({
        'success': true,
        'message': res.message ?? 'Success',
        'data': res.data,
      });
      final logsCount = response.data?.logs.length ?? 0;
      AppLogger.i('[$_tag] Logs count loaded: $logsCount');
      if (response.data?.summary != null) {
        AppLogger.i('[$_tag] Summary loaded');
      }
      if (logsCount == 0) {
        AppLogger.i('[$_tag] Empty response');
      }
      return response;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] API failure: $errMsg');
      throw Exception(errMsg);
    }
  }
}
