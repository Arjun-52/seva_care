import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/local_storage_service.dart';
import '../core/api/api_client.dart';
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

  // ─── Web Socket Service ────────────────────
  final webSocketService = WebSocketService();
  locator.registerSingleton<WebSocketService>(webSocketService);
}
