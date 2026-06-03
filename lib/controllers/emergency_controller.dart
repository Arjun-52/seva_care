import 'package:get/get.dart';
import '../repositories/senior_repository.dart';
import '../models/sos_response.dart';
import '../models/vital_alert_model.dart';
import '../models/emergency_alerts_response.dart';
import '../services/dependency_injection.dart';
import '../utils/app_logger.dart';

enum EmergencyState { idle, loading, success, error }

class EmergencyController extends GetxController {
  final SeniorRepository _repository = locator<SeniorRepository>();

  final Rx<EmergencyState> state = EmergencyState.idle.obs;
  final RxBool submitting = false.obs;
  final RxString errorMessage = ''.obs;

  // Stored state
  final Rxn<SosResponse> sosResponse = Rxn<SosResponse>();
  final RxString alertId = ''.obs;
  final RxString alertStatus = ''.obs;
  final RxString emergencyNumber = ''.obs;

  final RxList<VitalAlertModel> alerts = <VitalAlertModel>[].obs;

  // Paginated Emergency Alerts list and status
  final RxList<EmergencyAlert> emergencyAlerts = <EmergencyAlert>[].obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool loadingMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAlerts();
    fetchEmergencyAlerts(isRefresh: true);
  }

  Future<void> fetchAlerts({bool isSilent = false}) async {
    if (!isSilent) {
      state.value = EmergencyState.loading;
    }
    AppLogger.i('[EmergencyController] Fetch vital alerts requested');
    try {
      final List<VitalAlertModel> fetchedAlerts = await _repository.getVitalAlerts();
      alerts.value = fetchedAlerts;
      state.value = EmergencyState.success;
      AppLogger.i('[EmergencyController] Fetch vital alerts success. Count: ${fetchedAlerts.length}');
    } catch (e, stack) {
      AppLogger.e('[EmergencyController] Fetch vital alerts failure', e, stack);
      errorMessage.value = 'Unable to load alerts';
      state.value = EmergencyState.error;
    }
  }

  Future<void> fetchEmergencyAlerts({bool isRefresh = false}) async {
    if (isRefresh) {
      AppLogger.i('[EmergencyController] Refresh triggered');
      currentPage.value = 1;
      totalPages.value = 1;
    }

    if (state.value == EmergencyState.loading || loadingMore.value) {
      AppLogger.i('[EmergencyController] Fetch ignored: already loading');
      return;
    }

    if (!isRefresh && currentPage.value > totalPages.value) {
      AppLogger.i('[EmergencyController] Fetch ignored: reached end of pages (${currentPage.value} > ${totalPages.value})');
      return;
    }

    if (isRefresh) {
      state.value = EmergencyState.loading;
    } else if (currentPage.value > 1) {
      loadingMore.value = true;
      AppLogger.i('[EmergencyController] Pagination triggered. Page: ${currentPage.value}');
    } else {
      state.value = EmergencyState.loading;
    }

    AppLogger.i('[EmergencyController] Emergency alerts requested. Current page: ${currentPage.value}');

    try {
      final res = await _repository.getEmergencyAlerts(page: currentPage.value, limit: 20);
      
      final newAlerts = res.alerts;
      // Sort newest alerts first based on createdAt descending
      newAlerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (isRefresh) {
        emergencyAlerts.value = newAlerts;
      } else {
        emergencyAlerts.addAll(newAlerts);
      }

      totalPages.value = res.pagination.totalPages;
      currentPage.value = res.pagination.page + 1;
      
      state.value = EmergencyState.success;
      AppLogger.i('[EmergencyController] Alerts loaded count: ${emergencyAlerts.length}');
      
      if (emergencyAlerts.isEmpty) {
        AppLogger.i('[EmergencyController] Empty response');
      }
    } catch (e, stack) {
      AppLogger.e('[EmergencyController] API failures', e, stack);
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('timeoutexception') ||
          errStr.contains('network') ||
          errStr.contains('connect') ||
          errStr.contains('internet')) {
        errorMessage.value = 'Unable to load emergency alerts';
      } else {
        errorMessage.value = 'Something went wrong';
      }
      state.value = EmergencyState.error;
    } finally {
      loadingMore.value = false;
    }
  }

  Future<bool> triggerSOS({required String seniorId}) async {
    if (submitting.value) return false;

    submitting.value = true;
    state.value = EmergencyState.loading;
    errorMessage.value = '';

    AppLogger.i('[EmergencyController] SOS triggered. seniorId used: $seniorId');

    try {
      final response = await _repository.triggerSOS(seniorId: seniorId);
      
      sosResponse.value = response;
      if (response.data != null) {
        alertId.value = response.data!.alertId;
        alertStatus.value = response.data!.status;
        emergencyNumber.value = response.data!.emergencyNumber;
      }
      
      state.value = EmergencyState.success;
      AppLogger.i('[EmergencyController] SOS success. Alert ID: ${alertId.value}, Status: ${alertStatus.value}');
      
      // State Synchronization: Refresh relevant emergency data after SOS successfully created
      await fetchAlerts(isSilent: true);
      await fetchEmergencyAlerts(isRefresh: true);
      
      return true;
    } catch (e, stack) {
      AppLogger.e('[EmergencyController] SOS failure', e, stack);
      
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('timeoutexception') ||
          errStr.contains('network') ||
          errStr.contains('connect') ||
          errStr.contains('internet')) {
        errorMessage.value = 'Unable to send emergency alert';
      } else {
        errorMessage.value = 'Something went wrong';
      }
      
      state.value = EmergencyState.error;
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
