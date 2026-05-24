import 'package:dio/dio.dart';

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
  Future<dynamic> delete(String path) => _safe(() => dio.delete(path));

  Future<dynamic> _safe(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data['data'];
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map) {
        throw ApiException(
          body['message']?.toString() ?? 'Request failed',
          errors: Map<String, dynamic>.from(body['errors'] ?? {}),
          statusCode: e.response?.statusCode,
        );
      }
      throw ApiException(
        e.type == DioExceptionType.connectionTimeout
            ? 'Connection timeout'
            : 'Unable to connect to the API',
      );
    }
  }
}
