import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._storage)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read();
          if (token != null && token.isNotEmpty)
            options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _storage;
  final Dio dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _safe(() => dio.get(path, queryParameters: query));
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) =>
      _safe(() => dio.post(path, data: data));
  Future<dynamic> put(String path, {Map<String, dynamic>? data}) =>
      _safe(() => dio.put(path, data: data));
  Future<dynamic> patch(String path, {Map<String, dynamic>? data}) =>
      _safe(() => dio.patch(path, data: data));
  Future<dynamic> delete(String path) => _safe(() => dio.delete(path));

  Future<dynamic> _safe(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      _logResponse(response);
      if (response.statusCode == 204 || response.data == null) return null;
      final body = response.data;
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'];
      }
      if (body is List) return body;
      throw ApiException(
        'The server returned an invalid response. Please try again.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _logError(e);
      final body = e.response?.data;
      if (body is Map) {
        throw ApiException(
          body['message']?.toString() ?? 'Request failed',
          errors: Map<String, dynamic>.from(body['errors'] ?? {}),
          statusCode: e.response?.statusCode,
        );
      }
      throw ApiException(switch (e.type) {
        DioExceptionType.connectionTimeout =>
          'Connection timed out. Please try again.',
        DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout =>
          'The server took too long to respond. Please try again.',
        DioExceptionType.connectionError =>
          'Unable to connect. Check your internet connection and try again.',
        _ => 'Unable to complete the request. Please try again.',
      }, statusCode: e.response?.statusCode);
    }
  }

  void _logResponse(Response<dynamic> response) {
    if (!kDebugMode) return;
    debugPrint(
      '[API] ${response.requestOptions.method} ${response.requestOptions.uri} '
      '-> ${response.statusCode} body=${_redacted(response.data)}',
    );
  }

  void _logError(DioException error) {
    if (!kDebugMode) return;
    debugPrint(
      '[API] ${error.requestOptions.method} ${error.requestOptions.uri} '
      '-> ${error.response?.statusCode ?? 'network error'} '
      'body=${_redacted(error.response?.data)}',
    );
  }

  dynamic _redacted(dynamic value) {
    if (value is List) return value.map(_redacted).toList();
    if (value is! Map) return value;
    return value.map((key, item) {
      final normalized = key.toString().toLowerCase();
      const sensitiveKeys = {
        'token',
        'access_token',
        'authorization',
        'password',
        'password_confirmation',
      };
      return MapEntry(
        key,
        sensitiveKeys.contains(normalized) ? '[REDACTED]' : _redacted(item),
      );
    });
  }
}
