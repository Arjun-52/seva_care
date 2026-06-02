import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/env.dart';
import '../storage/local_storage_service.dart';
import '../errors/failure.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import '../../config/routes.dart';

class ApiResult<T> {
  final bool success;
  final T? data;
  final Map<String, dynamic>? pagination;
  final Failure? failure;
  /// Top-level message from the API response body (present on both success and error).
  final String? message;

  ApiResult({
    required this.success,
    this.data,
    this.pagination,
    this.failure,
    this.message,
  });

  factory ApiResult.success(T data, {Map<String, dynamic>? pagination, String? message}) {
    return ApiResult(success: true, data: data, pagination: pagination, message: message);
  }

  factory ApiResult.error(Failure failure, {String? message}) {
    return ApiResult(success: false, failure: failure, message: message);
  }

  String get errorMessage => failure?.message ?? 'Unknown error occurred';
}

class ApiClient {
  final LocalStorageService _storageService;
  final http.Client _client;
  Future<bool>? _refreshFuture;

  ApiClient(this._storageService, {http.Client? client})
      : _client = client ?? http.Client();

  String get baseUrl => Env.apiBaseUrl;

  Future<bool> _handleTokenRefresh() async {
    final refreshToken = _storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      AppLogger.e('Refresh token is missing or empty');
      return false;
    }

    if (_refreshFuture != null) {
      AppLogger.i('Refresh request already in progress, deduplicating...');
      return _refreshFuture!;
    }

    _refreshFuture = _performRefresh(refreshToken);
    final success = await _refreshFuture!;
    _refreshFuture = null;
    return success;
  }

  Future<bool> _performRefresh(String refreshToken) async {
    AppLogger.i('Refresh token request started');
    try {
      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(Duration(milliseconds: Env.receiveTimeout));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final newData = body['data'];
          final newAccessToken = newData['token'] as String;
          final newRefreshToken = newData['refreshToken'] as String;

          // Save securely
          await _storageService.saveAuthToken(newAccessToken);
          await _storageService.saveRefreshToken(newRefreshToken);
          
          // Sync with ApiService
          ApiService.setTokens(access: newAccessToken, refresh: newRefreshToken);

          AppLogger.i('Refresh successful, tokens updated');
          return true;
        }
      }
      AppLogger.e('Refresh request returned status: ${response.statusCode}');
      return false;
    } catch (e, stack) {
      AppLogger.e('Refresh request failed due to error', e, stack);
      final errStr = e.toString();
      if (errStr.contains('SocketException') || errStr.contains('HandshakeException') || errStr.contains('TimeoutException')) {
        rethrow; // Rethrow network errors so we don't log out!
      }
      return false;
    }
  }

  void _logoutAndRedirect() {
    AppLogger.e('Session expired, logging out user and redirecting to login');
    _storageService.clearSession();
    ApiService.clearTokens();
    AppRoutes.router.go('/login');
  }

  // ─── Headers Injection ──────────────────────

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = _storageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ─── GET ───────────────────────────────────

  Future<ApiResult<dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    return _executeWithRetry('GET', endpoint, queryParams: queryParams);
  }

  // ─── POST ──────────────────────────────────

  Future<ApiResult<dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _executeWithRetry('POST', endpoint, body: body);
  }

  // ─── PUT ───────────────────────────────────

  Future<ApiResult<dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _executeWithRetry('PUT', endpoint, body: body);
  }

  // ─── DELETE ────────────────────────────────

  Future<ApiResult<dynamic>> delete(String endpoint) async {
    return _executeWithRetry('DELETE', endpoint);
  }

  // ─── File Upload ───────────────────────────

  Future<ApiResult<dynamic>> upload(
    String endpoint,
    File file, {
    Map<String, String>? fields,
  }) async {
    return _executeWithRetry('MULTIPART', endpoint, file: file, fields: fields);
  }

  // ─── Request with Silent Auto-Refresh & Retry ───

  Future<ApiResult<dynamic>> _executeWithRetry(
    String method,
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
    File? file,
    Map<String, String>? fields,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final isAuthEndpoint = endpoint.contains('auth/');

    try {
      final headers = _buildHeaders();
      http.Response response;

      if (method == 'GET') {
        _logRequest('GET', uri, headers, null);
        response = await _client.get(uri, headers: headers).timeout(
              Duration(milliseconds: Env.receiveTimeout),
            );
      } else if (method == 'POST') {
        final encodedBody = body != null ? jsonEncode(body) : null;
        _logRequest('POST', uri, headers, encodedBody);
        response = await _client.post(uri, headers: headers, body: encodedBody).timeout(
              Duration(milliseconds: Env.receiveTimeout),
            );
      } else if (method == 'PUT') {
        final encodedBody = body != null ? jsonEncode(body) : null;
        _logRequest('PUT', uri, headers, encodedBody);
        response = await _client.put(uri, headers: headers, body: encodedBody).timeout(
              Duration(milliseconds: Env.receiveTimeout),
            );
      } else if (method == 'DELETE') {
        _logRequest('DELETE', uri, headers, null);
        response = await _client.delete(uri, headers: headers).timeout(
              Duration(milliseconds: Env.receiveTimeout),
            );
      } else if (method == 'MULTIPART') {
        final request = http.MultipartRequest('POST', uri);
        final token = _storageService.getAuthToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        if (file != null) {
          request.files.add(await http.MultipartFile.fromPath('file', file.path));
        }
        if (fields != null) {
          request.fields.addAll(fields);
        }
        _logRequest('MULTIPART', uri, request.headers, 'Fields: $fields, File: ${file?.path}');
        final streamedResponse = await request.send().timeout(
              Duration(milliseconds: Env.receiveTimeout),
            );
        response = await http.Response.fromStream(streamedResponse);
      } else {
        throw UnsupportedError('Unsupported HTTP method: $method');
      }

      _logResponse(method, uri, response);

      // Check for 401 Unauthorized (invalid/expired access token)
      if (response.statusCode == 401 && !isAuthEndpoint) {
        AppLogger.i('Access token expired (401 received). Starting refresh token request...');
        try {
          final refreshed = await _handleTokenRefresh();
          if (refreshed) {
            AppLogger.i('Original request retried after successful refresh');
            final retryHeaders = _buildHeaders();
            http.Response retryResponse;

            if (method == 'GET') {
              retryResponse = await _client.get(uri, headers: retryHeaders).timeout(
                    Duration(milliseconds: Env.receiveTimeout),
                  );
            } else if (method == 'POST') {
              retryResponse = await _client.post(uri, headers: retryHeaders, body: body != null ? jsonEncode(body) : null).timeout(
                    Duration(milliseconds: Env.receiveTimeout),
                  );
            } else if (method == 'PUT') {
              retryResponse = await _client.put(uri, headers: retryHeaders, body: body != null ? jsonEncode(body) : null).timeout(
                    Duration(milliseconds: Env.receiveTimeout),
                  );
            } else if (method == 'DELETE') {
              retryResponse = await _client.delete(uri, headers: retryHeaders).timeout(
                    Duration(milliseconds: Env.receiveTimeout),
                  );
            } else if (method == 'MULTIPART') {
              final request = http.MultipartRequest('POST', uri);
              final token = _storageService.getAuthToken();
              if (token != null && token.isNotEmpty) {
                request.headers['Authorization'] = 'Bearer $token';
              }
              if (file != null) {
                request.files.add(await http.MultipartFile.fromPath('file', file.path));
              }
              if (fields != null) {
                request.fields.addAll(fields);
              }
              final streamedResponse = await request.send().timeout(
                    Duration(milliseconds: Env.receiveTimeout),
                  );
              retryResponse = await http.Response.fromStream(streamedResponse);
            } else {
              throw UnsupportedError('Unsupported retry method');
            }

            _logResponse('$method (RETRY)', uri, retryResponse);
            return _handleResponse(retryResponse);
          } else {
            AppLogger.e('Refresh failed, logging out user');
            _logoutAndRedirect();
            return ApiResult.error(AuthFailure('Session expired. Please login again.'));
          }
        } catch (refreshErr) {
          AppLogger.e('Refresh token request failed due to network error');
          return ApiResult.error(const NetworkFailure('Unable to connect. Please check internet connection.'));
        }
      }

      return _handleResponse(response);
    } catch (e, stack) {
      AppLogger.e('ApiClient request failed with exception', e, stack);
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── Helpers & Parsers ─────────────────────

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final base = '$baseUrl/$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(base).replace(queryParameters: queryParams);
    }
    return Uri.parse(base);
  }

  ApiResult<dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final bodyMessage = body['message'] as String?;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(
          body['data'],
          pagination: body['pagination'],
          message: bodyMessage,
        );
      }

      // Try multiple message locations to match different API error shapes
      final errorText = body['error']?['message']
          ?? bodyMessage
          ?? (body['errors'] is List && (body['errors'] as List).isNotEmpty
              ? (body['errors'] as List).first.toString()
              : null)
          ?? 'Request failed (${response.statusCode})';

      AppLogger.e('[ApiClient] HTTP ${response.statusCode}: $errorText');

      if (response.statusCode == 401) {
        return ApiResult.error(AuthFailure(errorText), message: bodyMessage);
      }
      if (response.statusCode == 400) {
        return ApiResult.error(ValidationFailure(errorText), message: bodyMessage);
      }
      return ApiResult.error(ServerFailure(errorText), message: bodyMessage);
    } catch (e) {
      return ApiResult.error(ServerFailure('Failed to parse response from server. Status: ${response.statusCode}'));
    }
  }

  Failure _parseError(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return const NetworkFailure('Connection timed out. Please check your internet connection.');
    }
    if (error.toString().contains('SocketException') || error.toString().contains('HandshakeException')) {
      return const NetworkFailure('Cannot connect to server. Please check your internet connection.');
    }
    return UnknownFailure(error.toString());
  }

  void _logRequest(String method, Uri uri, Map<String, String> headers, String? body) {
    // A clean console output, ready for expansion/integration with analytics/monitoring
    print('[API REQUEST] $method -> $uri');
    print('[API HEADERS] $headers');
    if (body != null) {
      print('[API BODY] $body');
    }
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    print('[API RESPONSE] $method -> $uri [Status: ${response.statusCode}]');
    print('[API RESPONSE BODY] ${response.body}');
  }
}
