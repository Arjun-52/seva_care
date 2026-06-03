import '../core/api/api_client.dart';
import '../models/mock_data.dart';
import '../models/senior_details_model.dart';
import '../models/senior_vital_history_model.dart';
import '../models/latest_vitals_model.dart';
import '../models/vital_alert_model.dart';
import '../models/sos_response.dart';
import '../models/emergency_alerts_response.dart' as ear;
import '../utils/app_logger.dart';

class SeniorsResponse {
  final List<Senior> seniors;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  SeniorsResponse({
    required this.seniors,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class SeniorRepository {
  final ApiClient _apiClient;
  static const String _tag = 'SeniorRepository';

  SeniorRepository(this._apiClient);

  /// Fetch all seniors records with pagination.
  ///
  /// Calls GET /v1/seniors.
  /// Returns a strongly typed [SeniorsResponse].
  /// Throws with backend error message on failure.
  Future<SeniorsResponse> getSeniors({int page = 1}) async {
    AppLogger.i('[$_tag] Fetch seniors request started for page: $page');
    final res = await _apiClient.get('seniors', queryParams: {
      'page': page.toString(),
      'limit': '20',
    });

    if (res.success) {
      final List<dynamic> dataList = res.data as List<dynamic>? ?? [];
      
      // Parse pagination metadata safely from response meta
      int limitVal = 20;
      int totalVal = dataList.length;
      int totalPagesVal = 1;

      final meta = res.pagination; // From ApiResult pagination
      if (meta != null) {
        limitVal = meta['limit'] as int? ?? 20;
        totalVal = meta['total'] as int? ?? dataList.length;
        totalPagesVal = meta['totalPages'] as int? ?? 1;
      }

      final seniorsList = dataList.map((e) => Senior.fromJson(e as Map<String, dynamic>)).toList();
      AppLogger.i('[$_tag] Seniors fetched successfully. Count: ${seniorsList.length}');

      return SeniorsResponse(
        seniors: seniorsList,
        page: page,
        limit: limitVal,
        total: totalVal,
        totalPages: totalPagesVal,
      );
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Fetch seniors failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Create a senior record.
  ///
  /// Calls POST /v1/seniors.
  /// Returns the newly created [Senior] object.
  Future<Senior> createSenior({required Map<String, dynamic> data}) async {
    AppLogger.i('[$_tag] Create senior request started with data: $data');
    final res = await _apiClient.post('seniors', body: data);

    if (res.success) {
      if (res.data == null) {
        throw Exception('Received null data from server');
      }
      final senior = Senior.fromJson(res.data as Map<String, dynamic>);
      AppLogger.i('[$_tag] Senior created successfully. ID: ${senior.id}');
      return senior;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Create senior failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Fetch full senior details including relations, vitals and collections.
  ///
  /// Calls GET /v1/seniors/{id}.
  /// Returns a strongly typed [SeniorDetailsModel].
  Future<SeniorDetailsModel> getSeniorById(String seniorId) async {
    AppLogger.i('[$_tag] Fetch senior details started for ID: $seniorId');
    final res = await _apiClient.get('seniors/$seniorId');

    if (res.success) {
      if (res.data == null) {
        throw Exception('Received null senior details from server');
      }
      final details = SeniorDetailsModel.fromJson(res.data as Map<String, dynamic>);
      AppLogger.i('[$_tag] Senior details loaded successfully. ID: ${details.id}');
      return details;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Fetch senior details failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Update a senior record.
  ///
  /// Calls PUT /v1/seniors/{id}.
  /// Returns a strongly typed [SeniorDetailsModel].
  Future<SeniorDetailsModel> updateSenior(String seniorId, Map<String, dynamic> data) async {
    AppLogger.i('[$_tag] Update senior request started for ID: $seniorId with data: $data');
    final res = await _apiClient.put('seniors/$seniorId', body: data);

    if (res.success) {
      if (res.data == null) {
        throw Exception('Received null data from server');
      }
      final details = SeniorDetailsModel.fromJson(res.data as Map<String, dynamic>);
      AppLogger.i('[$_tag] Senior updated successfully. ID: ${details.id}');
      return details;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Update senior failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Remove a senior record.
  ///
  /// Calls DELETE /v1/seniors/{id}.
  /// Returns success status message or throws on failure.
  Future<String> deleteSenior(String seniorId) async {
    AppLogger.i('[$_tag] Delete senior request started for ID: $seniorId');
    final res = await _apiClient.delete('seniors/$seniorId');

    if (res.success) {
      final msg = res.message ?? 'Senior removed successfully';
      AppLogger.i('[$_tag] Senior deleted successfully. ID: $seniorId');
      return msg;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Delete senior failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Fetch senior vitals history records.
  ///
  /// Calls GET /v1/seniors/{id}/vitals/history.
  /// Returns a list of [SeniorVitalHistoryModel] sorted by recordedAt descending.
  Future<List<SeniorVitalHistoryModel>> getSeniorVitalsHistory(String seniorId) async {
    AppLogger.i('[$_tag] Fetch senior vitals history started for ID: $seniorId');
    final res = await _apiClient.get('seniors/$seniorId/vitals/history');

    if (res.success) {
      final List<dynamic> dataList = res.data as List<dynamic>? ?? [];
      final list = dataList.map((e) => SeniorVitalHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
      
      // Sort newest records first based on recordedAt descending
      list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      
      AppLogger.i('[$_tag] Senior vitals history loaded. Count: ${list.length}');
      return list;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Fetch senior vitals history failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Fetch the latest recorded vitals for a senior.
  ///
  /// Calls GET /v1/vitals/latest/{seniorId}.
  /// Returns a strongly typed [LatestVitalsModel] or null if vitals are unavailable.
  Future<LatestVitalsModel?> getLatestVitals(String seniorId) async {
    AppLogger.i('[$_tag] Fetch latest vitals started for ID: $seniorId');
    final res = await _apiClient.get('vitals/latest/$seniorId');

    if (res.success) {
      if (res.data == null) {
        AppLogger.i('[$_tag] Latest vitals is null / unavailable for ID: $seniorId');
        return null;
      }
      final vitals = LatestVitalsModel.fromJson(res.data as Map<String, dynamic>);
      AppLogger.i('[$_tag] Latest vitals loaded successfully for ID: $seniorId. BP: ${vitals.bpSystolic}/${vitals.bpDiastolic}');
      return vitals;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Fetch latest vitals failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Fetch all active and past vital alerts.
  ///
  /// Calls GET /v1/vitals/alerts.
  /// Returns a list of [VitalAlertModel].
  Future<List<VitalAlertModel>> getVitalAlerts() async {
    AppLogger.i('[$_tag] Fetch vital alerts started');
    final res = await _apiClient.get('vitals/alerts');

    if (res.success) {
      final List<dynamic> dataList = res.data as List<dynamic>? ?? [];
      final list = dataList.map((e) => VitalAlertModel.fromJson(e as Map<String, dynamic>)).toList();
      AppLogger.i('[$_tag] Vital alerts loaded successfully. Count: ${list.length}');
      return list;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Fetch vital alerts failed: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Trigger emergency SOS alert for selected senior citizen.
  ///
  /// Calls POST /v1/emergency/sos.
  Future<SosResponse> triggerSOS({required String seniorId}) async {
    AppLogger.i('[$_tag] SOS triggered. seniorId used: $seniorId. Request started');
    
    final payload = {
      'seniorId': seniorId,
      'triggeredBy': 'family',
    };

    final res = await _apiClient.post('emergency/sos', body: payload);

    if (res.success) {
      if (res.data == null) {
        AppLogger.e('[$_tag] triggerSOS request returned success but null data');
        throw Exception('Received null data from server');
      }
      final response = SosResponse.fromJson({
        'success': true,
        'message': res.message ?? 'Created',
        'data': res.data,
      });

      final alert = response.data;
      if (alert != null) {
        AppLogger.i('[$_tag] Request success. Alert ID received: ${alert.alertId}, Alert status received: ${alert.status}, Emergency number received: ${alert.emergencyNumber}');
      }
      return response;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] API failure: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Fetch emergency alerts records with pagination.
  ///
  /// Calls GET /v1/emergency/alerts.
  Future<ear.EmergencyAlertsResponse> getEmergencyAlerts({
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.i('[$_tag] Fetch emergency alerts started for page: $page');
    final res = await _apiClient.get('emergency/alerts', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    if (res.success) {
      final response = ear.EmergencyAlertsResponse.fromJson({
        'success': true,
        'message': res.message ?? 'Success',
        'data': res.data,
        'errors': const [],
        'meta': {
          'pagination': res.pagination,
        },
      });
      AppLogger.i('[$_tag] Emergency alerts loaded. Count: ${response.alerts.length}');
      return response;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Fetch emergency alerts failed: $errMsg');
      throw Exception(errMsg);
    }
  }
}

