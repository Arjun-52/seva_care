import 'package:get/get.dart';
import '../repositories/senior_repository.dart';
import '../models/video_schedule_response.dart';
import '../models/instant_video_call_response.dart';
import '../models/video_calls_response.dart';
import '../models/end_video_call_response.dart';
import '../services/dependency_injection.dart';
import '../utils/app_logger.dart';

enum VideoState { idle, loading, success, error }

class VideoController extends GetxController {
  final SeniorRepository _repository = locator<SeniorRepository>();

  final Rx<VideoState> state = VideoState.idle.obs;
  final RxBool submitting = false.obs;
  final RxString errorMessage = ''.obs;

  // Stored state for scheduled calls
  final Rxn<ScheduledVideoCall> scheduledCall = Rxn<ScheduledVideoCall>();
  
  // Stored state for active instant calls
  final Rxn<ActiveVideoCall> activeCall = Rxn<ActiveVideoCall>();
  final RxString activeCallId = ''.obs;

  // Video calls lists
  final RxList<VideoCall> videoCalls = <VideoCall>[].obs;
  final RxList<VideoCall> activeCalls = <VideoCall>[].obs;
  final RxList<VideoCall> scheduledCalls = <VideoCall>[].obs;

  // Shared state
  final RxString meetUrl = ''.obs;
  final RxString callStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVideoCalls();
  }

  Future<void> fetchVideoCalls({bool isRefresh = false}) async {
    if (state.value == VideoState.loading && !isRefresh) return;

    if (!isRefresh) {
      state.value = VideoState.loading;
    }
    errorMessage.value = '';

    AppLogger.i('[VideoController] Fetching video calls. isRefresh: $isRefresh');

    try {
      final response = await _repository.getVideoCalls();
      final allCalls = response.videoCalls;

      AppLogger.i('[VideoController] Video calls fetched successfully. Total count: ${allCalls.length}');

      // Filter and sort active calls (newest active first)
      final active = allCalls.where((c) => c.status.toLowerCase() == 'active').toList();
      active.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      // Filter and sort scheduled calls (ascending by startedAt)
      final scheduled = allCalls.where((c) => c.status.toLowerCase() == 'scheduled').toList();
      scheduled.sort((a, b) => a.startedAt.compareTo(b.startedAt));

      // Filter and sort other/completed calls (newest completed first)
      final completed = allCalls.where((c) {
        final status = c.status.toLowerCase();
        return status != 'active' && status != 'scheduled';
      }).toList();
      completed.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      // Combine in priority order
      final sorted = <VideoCall>[];
      sorted.addAll(active);
      sorted.addAll(scheduled);
      sorted.addAll(completed);

      videoCalls.assignAll(sorted);
      activeCalls.assignAll(active);
      scheduledCalls.assignAll(scheduled);

      state.value = VideoState.success;
    } catch (e, stack) {
      AppLogger.e('[VideoController] Failed to fetch video calls', e, stack);
      errorMessage.value = 'Failed to load video calls';
      state.value = VideoState.error;
    }
  }

  Future<bool> scheduleCall({
    required String seniorId,
    required DateTime scheduledAt,
  }) async {
    if (submitting.value) return false;

    if (seniorId.isEmpty) {
      errorMessage.value = 'Please select a senior';
      AppLogger.i('[VideoController] Validation failed: seniorId is empty');
      return false;
    }

    if (scheduledAt.isBefore(DateTime.now())) {
      errorMessage.value = 'Scheduled time must be in the future';
      AppLogger.i('[VideoController] Validation failed: scheduledAt is in the past ($scheduledAt)');
      return false;
    }

    submitting.value = true;
    state.value = VideoState.loading;
    errorMessage.value = '';

    AppLogger.i('[VideoController] Video scheduling initiated. Senior: $seniorId, Datetime: $scheduledAt');

    try {
      final response = await _repository.scheduleVideoCall(
        seniorId: seniorId,
        scheduledAt: scheduledAt,
      );

      scheduledCall.value = response.data;
      if (response.data != null) {
        meetUrl.value = response.data!.meetUrl;
        callStatus.value = response.data!.status;
        AppLogger.i('[VideoController] Request success. Meeting URL: ${meetUrl.value}, Status: ${callStatus.value}');
      }

      await fetchVideoCalls(isRefresh: true);
      state.value = VideoState.success;
      return true;
    } catch (e, stack) {
      AppLogger.e('[VideoController] API failures', e, stack);
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('timeoutexception') ||
          errStr.contains('network') ||
          errStr.contains('connect') ||
          errStr.contains('internet')) {
        errorMessage.value = 'Unable to schedule video call';
      } else {
        errorMessage.value = 'Something went wrong';
      }
      state.value = VideoState.error;
      return false;
    } finally {
      submitting.value = false;
    }
  }

  Future<bool> startInstantCall({
    required String seniorId,
  }) async {
    if (submitting.value) return false;

    if (seniorId.isEmpty) {
      errorMessage.value = 'Please select a senior';
      AppLogger.i('[VideoController] Validation failed: seniorId is empty');
      return false;
    }

    submitting.value = true;
    state.value = VideoState.loading;
    errorMessage.value = '';

    AppLogger.i('[VideoController] Instant call initiated. seniorId: $seniorId');

    try {
      final response = await _repository.startInstantVideoCall(seniorId: seniorId);
      
      activeCall.value = response.data;
      if (response.data != null) {
        activeCallId.value = response.data!.id;
        meetUrl.value = response.data!.meetUrl;
        callStatus.value = response.data!.status;
        AppLogger.i('[VideoController] Request success. Call ID: ${activeCallId.value}, Meeting URL: ${meetUrl.value}, Status: ${callStatus.value}');
      }
      
      await fetchVideoCalls(isRefresh: true);
      state.value = VideoState.success;
      return true;
    } catch (e, stack) {
      AppLogger.e('[VideoController] API failures', e, stack);
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('timeoutexception') ||
          errStr.contains('network') ||
          errStr.contains('connect') ||
          errStr.contains('internet')) {
        errorMessage.value = 'Unable to start video call';
      } else {
        errorMessage.value = 'Something went wrong';
      }
      state.value = VideoState.error;
      return false;
    } finally {
      submitting.value = false;
    }
  }

  Future<bool> endCall({
    required String callId,
  }) async {
    if (submitting.value) return false;

    if (callId.isEmpty) {
      errorMessage.value = 'Call ID is required';
      AppLogger.i('[VideoController] Validation failures: callId is empty');
      return false;
    }

    submitting.value = true;
    state.value = VideoState.loading;
    errorMessage.value = '';

    AppLogger.i('[VideoController] End call initiated. Call ID used: $callId. Request started');

    try {
      final response = await _repository.endVideoCall(callId: callId);
      
      if (response.data != null) {
        callStatus.value = response.data!.status;
        AppLogger.i('[VideoController] Request success. Call ended successfully. Updated status received: ${callStatus.value}, endedAt received: ${response.data!.endedAt}');
        
        // Reset active call states if it matches
        if (activeCallId.value == callId) {
          activeCallId.value = '';
          activeCall.value = null;
        }
      }

      await fetchVideoCalls(isRefresh: true);
      state.value = VideoState.success;
      return true;
    } catch (e, stack) {
      AppLogger.e('[VideoController] API failures', e, stack);
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('timeoutexception') ||
          errStr.contains('network') ||
          errStr.contains('connect') ||
          errStr.contains('internet')) {
        errorMessage.value = 'Unable to end video call';
      } else {
        errorMessage.value = e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.value.isEmpty || errorMessage.value.contains('Unknown')) {
          errorMessage.value = 'Something went wrong';
        }
      }
      state.value = VideoState.error;
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
