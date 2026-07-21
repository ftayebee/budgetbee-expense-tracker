import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../logging/app_logger.dart';
import '../storage/token_storage.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._storage)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
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
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-Client-Platform'] = _platformDescription;
          _log(
            'API request',
            context: {
              'method': options.method,
              'url': _safeUri(options.uri).toString(),
              'payload': AppLogger.sanitize(options.data),
              'query': AppLogger.sanitize(options.queryParameters),
              'mode': kDebugMode ? 'debug' : 'release',
              'platform': _platformDescription,
            },
          );
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.clear();
          }
          handler.next(error);
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
    if (!ApiConstants.hasValidBaseUrl) {
      throw ApiException(
        'The API address is invalid. Please update the app configuration.',
      );
    }
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
      throw ApiErrorMapper.fromDio(e);
    } on FormatException catch (e, stackTrace) {
      _log(
        'API parsing failure',
        context: {
          'exception_type': e.runtimeType.toString(),
          'message': e.message,
          'mode': kDebugMode ? 'debug' : 'release',
        },
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        'The server returned an invalid response. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log(
        'API unexpected failure',
        context: {
          'exception_type': e.runtimeType.toString(),
          'message': e.toString(),
          'mode': kDebugMode ? 'debug' : 'release',
        },
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        e is ArgumentError
            ? 'The API address is invalid. Please update the app configuration.'
            : 'The request could not be completed. Please try again.',
      );
    }
  }

  void _logResponse(Response<dynamic> response) {
    _log(
      'API response',
      context: {
        'method': response.requestOptions.method,
        'url': _safeUri(response.requestOptions.uri).toString(),
        'status': response.statusCode,
        'raw_response': AppLogger.sanitize(response.data),
        'parsed_response': AppLogger.sanitize(response.data),
        'mode': kDebugMode ? 'debug' : 'release',
        'platform': _platformDescription,
      },
    );
  }

  void _logError(DioException error) {
    _log(
      'API failure',
      context: {
        'method': error.requestOptions.method,
        'url': _safeUri(error.requestOptions.uri).toString(),
        'status': error.response?.statusCode ?? 'network',
        'raw_response': AppLogger.sanitize(error.response?.data),
        'exception_type': (error.error?.runtimeType ?? error.runtimeType)
            .toString(),
        'message': error.message ?? error.error?.toString() ?? 'unknown',
        'mode': kDebugMode ? 'debug' : 'release',
        'platform': _platformDescription,
      },
      error: error,
      stackTrace: error.stackTrace,
    );
  }

  String get _platformDescription {
    try {
      return Platform.isAndroid
          ? Platform.operatingSystemVersion
          : Platform.operatingSystem;
    } catch (_) {
      return 'unavailable';
    }
  }

  Uri _safeUri(Uri uri) {
    const sensitive = {
      'token',
      'access_token',
      'authorization',
      'password',
      'password_confirmation',
    };
    if (uri.queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: uri.queryParameters.map(
        (key, value) => MapEntry(
          key,
          sensitive.contains(key.toLowerCase()) ? '[REDACTED]' : value,
        ),
      ),
    );
  }

  void _log(
    String event, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger.debug(
      event,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
