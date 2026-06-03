import 'package:get/get.dart';
import '../repositories/medicines_repository.dart';
import '../models/medicine.dart';
import '../services/dependency_injection.dart';
import '../utils/app_logger.dart';

enum MedicinesState { loading, success, error, empty }

class MedicinesController extends GetxController {
  final MedicinesRepository _repository = locator<MedicinesRepository>();

  final Rx<MedicinesState> state = MedicinesState.loading.obs;
  final RxList<Medicine> medicines = <Medicine>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMedicines();
  }

  Future<void> fetchMedicines({bool isSilent = false}) async {
    AppLogger.i('[MedicinesController] Medicines requested');
    if (!isSilent) {
      state.value = MedicinesState.loading;
    }
    try {
      final response = await _repository.getMedicines();
      
      // Sort medicines by scheduledTime ascending (e.g. "08:00", "13:00", "21:00")
      final List<Medicine> sortedList = List.from(response.medicines);
      sortedList.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      
      medicines.value = sortedList;
      if (medicines.isEmpty) {
        state.value = MedicinesState.empty;
        AppLogger.i('[MedicinesController] Empty response');
      } else {
        state.value = MedicinesState.success;
        AppLogger.i('[MedicinesController] Medicines response received. Medicines loaded count: ${medicines.length}');
      }
    } catch (e, stack) {
      AppLogger.e('[MedicinesController] API failures', e, stack);
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('timeoutexception') ||
          errStr.contains('network') ||
          errStr.contains('connect') ||
          errStr.contains('internet')) {
        errorMessage.value = "Unable to load medicines";
      } else {
        errorMessage.value = "Something went wrong";
      }
      state.value = MedicinesState.error;
    }
  }

  Future<void> toggleMedicineTaken(String id, bool currentTakenVal) async {
    AppLogger.i('[MedicinesController] Toggle medicine taken status for ID: $id');
    try {
      final success = await _repository.markAsTaken(id, !currentTakenVal);
      if (success) {
        // Refresh list automatically after status change
        await fetchMedicines(isSilent: true);
      }
    } catch (e, stack) {
      AppLogger.e('[MedicinesController] Failed to toggle medicine status', e, stack);
    }
  }
}
