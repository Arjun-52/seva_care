import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../core/storage/local_storage_service.dart';
import 'dependency_injection.dart';
import '../utils/app_logger.dart';

/// Central API service for all backend communication.
///
/// Usage:
///   final result = await ApiService.get('seniors');
///   final result = await ApiService.post('vitals', body: {...});
///   final result = await ApiService.upload('documents/upload', file, fields: {...});
class ApiService {
  static String? _accessToken;
  static String? _refreshToken;

  // ─── Token Management ──────────────────────

  static void setTokens({required String access, required String refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  static bool get isAuthenticated => _accessToken != null;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ─── GET ───────────────────────────────────

  static Future<ApiResult> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response =
          await http.get(uri, headers: _headers).timeout(
                Duration(milliseconds: Env.receiveTimeout),
              );
      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── POST ──────────────────────────────────

  static Future<ApiResult> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(Duration(milliseconds: Env.receiveTimeout));
      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── PUT ───────────────────────────────────

  static Future<ApiResult> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(Duration(milliseconds: Env.receiveTimeout));
      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── DELETE ────────────────────────────────

  static Future<ApiResult> delete(String endpoint) async {
    try {
      final uri = _buildUri(endpoint);
      final response =
          await http.delete(uri, headers: _headers).timeout(
                Duration(milliseconds: Env.receiveTimeout),
              );
      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── File Upload ───────────────────────────

  static Future<ApiResult> upload(
    String endpoint,
    File file, {
    Map<String, String>? fields,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }
      request.files
          .add(await http.MultipartFile.fromPath('file', file.path));
      if (fields != null) request.fields.addAll(fields);

      final streamedResponse = await request.send().timeout(
            Duration(milliseconds: Env.receiveTimeout),
          );
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── Auth Endpoints ────────────────────────

  static Future<ApiResult> login({
    String? email,
    String? phone,
    required String password,
    required String role,
  }) async {
    final result = await post('auth/login', body: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'password': password,
      'role': role,
    });

    if (result.success && result.data != null) {
      setTokens(
        access: result.data!['token'],
        refresh: result.data!['refreshToken'],
      );
    }
    return result;
  }

  static Future<ApiResult> sendOtp(String phone) async {
    return post('auth/send-otp', body: {'phone': phone});
  }

  static Future<ApiResult> verifyOtp(String phone, String otp) async {
    final result =
        await post('auth/verify-otp', body: {'phone': phone, 'otp': otp});
    if (result.success && result.data != null) {
      setTokens(
        access: result.data!['token'],
        refresh: result.data!['refreshToken'],
      );
    }
    return result;
  }

  static Future<void> logout() async {
    try {
      await post('auth/logout');
    } catch (_) {}
    clearTokens();
  }

  static Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    AppLogger.i('Refresh token request started (via ApiService)');
    try {
      final uri = _buildUri('auth/refresh');
      final response = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': _refreshToken})).timeout(
            Duration(milliseconds: Env.receiveTimeout),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        final access = data['token'] as String;
        final refresh = data['refreshToken'] as String;
        
        // Update in secure local storage
        final storage = locator<LocalStorageService>();
        await storage.saveAuthToken(access);
        await storage.saveRefreshToken(refresh);

        // Update in ApiService
        setTokens(access: access, refresh: refresh);
        
        AppLogger.i('Refresh successful, tokens updated (via ApiService)');
        return true;
      }
      AppLogger.e('Refresh token failed with status code: ${response.statusCode} (via ApiService)');
    } catch (e, stack) {
      AppLogger.e('Refresh token failed due to network/unknown error (via ApiService)', e, stack);
      final errStr = e.toString();
      if (errStr.contains('SocketException') || errStr.contains('HandshakeException') || errStr.contains('TimeoutException')) {
        rethrow; // Rethrow network error so we don't log out!
      }
    }
    clearTokens();
    return false;
  }

  // ─── Helpers ───────────────────────────────

  static Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final base = '${Env.apiBaseUrl}/$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(base).replace(queryParameters: queryParams);
    }
    return Uri.parse(base);
  }

  static ApiResult _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode == 401 && _refreshToken != null) {
      // Token expired — could auto-refresh here
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult(
        success: true,
        data: body['data'],
        pagination: body['pagination'],
      );
    }

    return ApiResult.error(
      body['error']?['message'] ?? 'Request failed (${response.statusCode})',
    );
  }

  static String _parseError(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Connection timed out. Please check your internet.';
    }
    if (error.toString().contains('SocketException')) {
      return 'Cannot connect to server. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }
}

/// API response wrapper
class ApiResult {
  final bool success;
  final dynamic data;
  final Map<String, dynamic>? pagination;
  final String? errorMessage;

  ApiResult({
    required this.success,
    this.data,
    this.pagination,
    this.errorMessage,
  });

  factory ApiResult.error(String message) {
    return ApiResult(success: false, errorMessage: message);
  }
}
