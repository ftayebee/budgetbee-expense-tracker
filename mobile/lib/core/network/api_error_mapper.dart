import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiErrorMapper {
  ApiErrorMapper._();

  static ApiException fromDio(DioException exception) {
    final status = exception.response?.statusCode;
    final body = exception.response?.data;
    final errors = _validationErrors(body);
    final serverMessage = _serverMessage(body);

    return ApiException(
      _messageFor(
        status: status,
        type: exception.type,
        serverMessage: serverMessage,
        errors: errors,
      ),
      errors: errors,
      statusCode: status,
    );
  }

  static Map<String, dynamic> _validationErrors(dynamic body) {
    if (body is! Map || body['errors'] is! Map) return const {};
    return Map<String, dynamic>.from(body['errors'] as Map);
  }

  static String? _serverMessage(dynamic body) {
    if (body is! Map) return null;
    final value = body['message']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String _messageFor({
    required int? status,
    required DioExceptionType type,
    required String? serverMessage,
    required Map<String, dynamic> errors,
  }) {
    if (status == null) {
      return switch (type) {
        DioExceptionType.connectionTimeout =>
          'Connection timed out. Please try again.',
        DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout =>
          'The server took too long to respond. Please try again.',
        DioExceptionType.connectionError =>
          'Unable to connect. Check your internet connection and try again.',
        _ => 'Unable to complete the request. Please try again.',
      };
    }

    return switch (status) {
      401 => 'Your session has expired. Please sign in again.',
      403 => serverMessage ?? 'You do not have permission to do that.',
      404 => serverMessage ?? 'This transaction could not be found.',
      405 => 'This operation is not supported by the server.',
      422 =>
        _firstValidationMessage(errors) ??
            serverMessage ??
            'Please check the transaction details and try again.',
      >= 500 => 'The server could not complete the request. Please try again.',
      _ => serverMessage ?? 'The request could not be completed.',
    };
  }

  static String? _firstValidationMessage(Map<String, dynamic> errors) {
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}
