import 'package:get/get.dart';
import 'dart:async';
import '../repositories/care_logs_repository.dart';
import '../models/mock_data.dart';
import '../models/care_log_today_response.dart';
import '../services/dependency_injection.dart';
import '../services/websocket_service.dart';
import '../utils/app_logger.dart';

enum CareLogsState { loading, success, error, empty }

class CareLogsController extends GetxController {
  final CareLogsRepository _repository = locator<CareLogsRepository>();

  final Rx<CareLogsState> state = CareLogsState.loading.obs;
  final RxList<CareLog> logs = <CareLog>[].obs;
  final Rx<CareLogSummary> summary = CareLogSummary(total: 0, completed: 0, active: 0, pending: 0, missed: 0).obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedSeniorId = 'SR001'.obs;

  StreamSubscription? _wsSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchCareLogs();
    _setupWebSocketListener();
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    super.onClose();
  }

  void _setupWebSocketListener() {
    final ws = locator<WebSocketService>();
    _wsSubscription = ws.onCareLogUpdate.listen((_) {
      AppLogger.i('[CareLogsController] WebSocket update received, refreshing');
      fetchCareLogs(isSilent: true);
    });
  }

  void setSeniorId(String id) {
    if (selectedSeniorId.value != id) {
      AppLogger.i('[CareLogsController] Senior switched from ${selectedSeniorId.value} to $id');
      selectedSeniorId.value = id;
      // Clear stale data immediately on switch
      logs.clear();
      summary.value = CareLogSummary(total: 0, completed: 0, active: 0, pending: 0, missed: 0);
      fetchCareLogs();
    }
  }

  Future<void> fetchCareLogs({bool isSilent = false}) async {
    AppLogger.i('[CareLogsController] Controller fetch start. seniorId: ${selectedSeniorId.value}');
    if (!isSilent) {
      state.value = CareLogsState.loading;
    }
    try {
      final response = await _repository.getTodayCareLogs(seniorId: selectedSeniorId.value);
      if (response.data != null) {
        logs.value = response.data!.logs;
        summary.value = response.data!.summary;
      } else {
        logs.clear();
        summary.value = CareLogSummary(total: 0, completed: 0, active: 0, pending: 0, missed: 0);
      }

      if (logs.isEmpty) {
        state.value = CareLogsState.empty;
      } else {
        state.value = CareLogsState.success;
      }
      AppLogger.i('[CareLogsController] Controller fetch success. Loaded ${logs.length} logs');
    } catch (e, stack) {
      AppLogger.e('[CareLogsController] Controller fetch failure', e, stack);
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('timeoutexception') ||
          errStr.contains('network') ||
          errStr.contains('connect') ||
          errStr.contains('internet')) {
        errorMessage.value = "Unable to load today's care logs";
      } else {
        errorMessage.value = "Something went wrong";
      }
      state.value = CareLogsState.error;
    }
  }
}
