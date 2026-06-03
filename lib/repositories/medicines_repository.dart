import '../core/api/api_client.dart';
import '../models/medicine.dart';
import '../utils/app_logger.dart';

class MedicinesRepository {
  static const _tag = 'MedicinesRepository';
  final ApiClient _apiClient;

  MedicinesRepository(this._apiClient);

  /// Fetch medicines list from GET /v1/medicines
  Future<MedicinesResponse> getMedicines() async {
    AppLogger.i('[$_tag] Medicines requested');

    final res = await _apiClient.get('medicines');
    if (res.success) {
      AppLogger.i('[$_tag] Medicines response received');
      final response = MedicinesResponse.fromJson({
        'success': true,
        'message': res.message ?? 'Success',
        'data': res.data,
      });
      AppLogger.i('[$_tag] Medicines loaded count: ${response.medicines.length}');
      if (response.medicines.isEmpty) {
        AppLogger.i('[$_tag] Empty response');
      }
      return response;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] API failures / Parsing failures: $errMsg');
      throw Exception(errMsg);
    }
  }

  /// Mark medicine as taken by updating status
  Future<bool> markAsTaken(String medicineId, bool taken) async {
    AppLogger.i('[$_tag] Updating medicine taken status. ID: $medicineId to $taken');
    final res = await _apiClient.put('medicines/$medicineId', body: {'taken': taken});
    if (res.success) {
      AppLogger.i('[$_tag] Medicine updated successfully');
      return true;
    } else {
      final errMsg = res.errorMessage;
      AppLogger.e('[$_tag] Update medicine taken failed: $errMsg');
      throw Exception(errMsg);
    }
  }
}
