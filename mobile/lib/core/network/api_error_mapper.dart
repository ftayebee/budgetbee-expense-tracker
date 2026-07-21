import 'dart:io';

import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiErrorMapper {
  ApiErrorMapper._();

  static ApiException fromDio(DioException exception) {
    final status = exception.response?.statusCode;
    final body = exception.response?.data;
    final errors = _validationErrors(body);
    final serverMessage = _serverMessage(body);

    if (exception.error is HandshakeException) {
      return ApiException(
        'A secure connection to the server could not be established. '
        'Please update Android or contact support.',
      );
    }
    if (exception.error is SocketException) {
      return ApiException(
        'Unable to connect to the server. Please check your internet connection.',
      );
    }
    if (exception.error is FormatException) {
      return ApiException(
        'The server returned an invalid response. Please try again.',
        statusCode: status,
      );
    }

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
          'The request timed out. Please try again.',
        DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout =>
          'The request timed out. Please try again.',
        DioExceptionType.connectionError =>
          'Unable to connect to the server. Please check your internet connection.',
        DioExceptionType.cancel =>
          'The request was cancelled. Please try again.',
        _ => 'The request could not be completed. Please try again.',
      };
    }

    return switch (status) {
      401 => 'Your session has expired. Please sign in again.',
      403 => serverMessage ?? 'You do not have permission to do that.',
      404 => serverMessage ?? 'This transaction could not be found.',
      405 => 'This operation is not supported by the server.',
      409 =>
        _duplicateMessage(errors, serverMessage) ??
            'The request conflicts with an existing record.',
      422 =>
        _firstValidationMessage(errors) ??
            serverMessage ??
            'Please check the submitted details and try again.',
      429 => 'Too many attempts. Please wait a moment and try again.',
      >= 500 => 'The server could not complete the request. Please try again.',
      _ => serverMessage ?? 'The request could not be completed.',
    };
  }

  static String? _duplicateMessage(
    Map<String, dynamic> errors,
    String? serverMessage,
  ) {
    if (errors.containsKey('email') ||
        (serverMessage?.toLowerCase().contains('email') ?? false)) {
      return 'This email address is already registered.';
    }
    if (errors.containsKey('phone') ||
        (serverMessage?.toLowerCase().contains('phone') ?? false)) {
      return 'This phone number is already registered.';
    }
    return serverMessage;
  }

  static String? _firstValidationMessage(Map<String, dynamic> errors) {
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}
