import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/local_storage_service.dart';
import '../core/api/api_client.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/senior_repository.dart';
import 'websocket_service.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // ─── Local Storage Service ─────────────────
  final prefs = await SharedPreferences.getInstance();
  final storageService = LocalStorageService(prefs);
  locator.registerSingleton<LocalStorageService>(storageService);

  // ─── API Client ───────────────────────────
  final apiClient = ApiClient(storageService);
  locator.registerSingleton<ApiClient>(apiClient);

  // ─── Subscription Repository ──────────────
  final subRepo = SubscriptionRepository(apiClient);
  locator.registerSingleton<SubscriptionRepository>(subRepo);

  // ─── Settings Repository ──────────────
  final settingsRepo = SettingsRepository(apiClient);
  locator.registerSingleton<SettingsRepository>(settingsRepo);

  // ─── Notification Repository ──────────
  final notificationRepo = NotificationRepository(apiClient);
  locator.registerSingleton<NotificationRepository>(notificationRepo);

  // ─── Senior Repository ─────────────────
  final seniorRepo = SeniorRepository(apiClient);
  locator.registerSingleton<SeniorRepository>(seniorRepo);

  // ─── Web Socket Service ────────────────────
  final webSocketService = WebSocketService();
  locator.registerSingleton<WebSocketService>(webSocketService);
}
