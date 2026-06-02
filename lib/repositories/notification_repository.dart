import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/notification_model.dart';
import '../utils/app_logger.dart';

class NotificationRepository {
  static const _tag = 'NotificationRepository';
  final ApiClient _apiClient;

  // Static ValueNotifier for real-time badge synchronization across Dashboard and screens
  static final unreadCountNotifier = ValueNotifier<int>(0);

  NotificationRepository(this._apiClient);

  /// Fetch user notifications from GET /v1/notifications
  Future<NotificationResponseModel> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.i('[$_tag] Notifications requested');
    AppLogger.i('[$_tag] Current page: $page');

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final res = await _apiClient.get('notifications', queryParams: queryParams);
    if (res.success && res.data != null) {
      final response = NotificationResponseModel.fromJson(res.data, res.pagination);
      
      AppLogger.i('[$_tag] Notifications loaded');
      AppLogger.i('[$_tag] Unread count: ${response.unreadCount}');
      
      // Update unread count notifier
      unreadCountNotifier.value = response.unreadCount;

      if (response.notifications.isEmpty) {
        AppLogger.i('[$_tag] Empty response');
      }

      return response;
    } else {
      AppLogger.e('[$_tag] API failures: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }

  /// Mark notifications as read using PUT /v1/notifications/mark-read
  Future<int> markNotificationsAsRead(List<String> ids) async {
    AppLogger.i('[$_tag] Mark read request started');
    AppLogger.i('[$_tag] IDs sent: $ids');

    final body = {
      'ids': ids,
    };

    final res = await _apiClient.put('notifications/mark-read', body: body);
    if (res.success && res.data != null) {
      final updatedUnreadCount = res.data['unreadCount'] as int? ?? 0;
      
      AppLogger.i('[$_tag] Request success');
      AppLogger.i('[$_tag] Updated unread count: $updatedUnreadCount');

      // Sync unreadCount notifier
      unreadCountNotifier.value = updatedUnreadCount;
      return updatedUnreadCount;
    } else {
      AppLogger.e('[$_tag] Request failure: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }

  /// Delete notification using DELETE /v1/notifications/{id}
  Future<bool> deleteNotification(String notificationId) async {
    AppLogger.i('[$_tag] Notification delete initiated');
    AppLogger.i('[$_tag] Notification ID: $notificationId');
    AppLogger.i('[$_tag] API request started');

    final res = await _apiClient.delete('notifications/$notificationId');
    if (res.success) {
      AppLogger.i('[$_tag] Delete success');
      return true;
    } else {
      AppLogger.e('[$_tag] Delete failure: ${res.errorMessage}');
      throw Exception(res.errorMessage);
    }
  }
}
