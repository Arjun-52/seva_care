import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/env.dart';
import '../storage/local_storage_service.dart';
import '../errors/failure.dart';

class ApiResult<T> {
  final bool success;
  final T? data;
  final Map<String, dynamic>? pagination;
  final Failure? failure;

  ApiResult({
    required this.success,
    this.data,
    this.pagination,
    this.failure,
  });

  factory ApiResult.success(T data, {Map<String, dynamic>? pagination}) {
    return ApiResult(success: true, data: data, pagination: pagination);
  }

  factory ApiResult.error(Failure failure) {
    return ApiResult(success: false, failure: failure);
  }

  String get errorMessage => failure?.message ?? 'Unknown error occurred';
}

class ApiClient {
  final LocalStorageService _storageService;
  final http.Client _client;

  ApiClient(this._storageService, {http.Client? client})
      : _client = client ?? http.Client();

  String get baseUrl => Env.apiBaseUrl;

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
    try {
      final uri = _buildUri(endpoint, queryParams);
      final headers = _buildHeaders();

      // Simple Request Interceptor logger
      _logRequest('GET', uri, headers, null);

      final response = await _client.get(uri, headers: headers).timeout(
            Duration(milliseconds: Env.receiveTimeout),
          );

      // Simple Response Interceptor logger
      _logResponse('GET', uri, response);

      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── POST ──────────────────────────────────

  Future<ApiResult<dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = _buildHeaders();
      final encodedBody = body != null ? jsonEncode(body) : null;

      _logRequest('POST', uri, headers, encodedBody);

      final response = await _client
          .post(uri, headers: headers, body: encodedBody)
          .timeout(Duration(milliseconds: Env.receiveTimeout));

      _logResponse('POST', uri, response);

      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── PUT ───────────────────────────────────

  Future<ApiResult<dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = _buildHeaders();
      final encodedBody = body != null ? jsonEncode(body) : null;

      _logRequest('PUT', uri, headers, encodedBody);

      final response = await _client
          .put(uri, headers: headers, body: encodedBody)
          .timeout(Duration(milliseconds: Env.receiveTimeout));

      _logResponse('PUT', uri, response);

      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── DELETE ────────────────────────────────

  Future<ApiResult<dynamic>> delete(String endpoint) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = _buildHeaders();

      _logRequest('DELETE', uri, headers, null);

      final response = await _client.delete(uri, headers: headers).timeout(
            Duration(milliseconds: Env.receiveTimeout),
          );

      _logResponse('DELETE', uri, response);

      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error(_parseError(e));
    }
  }

  // ─── File Upload ───────────────────────────

  Future<ApiResult<dynamic>> upload(
    String endpoint,
    File file, {
    Map<String, String>? fields,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);

      final token = _storageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      if (fields != null) {
        request.fields.addAll(fields);
      }

      _logRequest('MULTIPART', uri, request.headers, 'Fields: $fields, File: ${file.path}');

      final streamedResponse = await request.send().timeout(
            Duration(milliseconds: Env.receiveTimeout),
          );
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse('MULTIPART', uri, response);

      return _handleResponse(response);
    } catch (e) {
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
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(
          body['data'],
          pagination: body['pagination'],
        );
      }

      final message = body['error']?['message'] ?? 'Request failed (${response.statusCode})';
      if (response.statusCode == 401) {
        return ApiResult.error(AuthFailure(message));
      }
      if (response.statusCode == 400) {
        return ApiResult.error(ValidationFailure(message));
      }
      return ApiResult.error(ServerFailure(message));
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
