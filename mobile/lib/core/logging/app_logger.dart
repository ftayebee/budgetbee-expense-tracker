import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void debug(
    String event, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    developer.log(
      '$event ${_encode(_sanitize(context))}',
      name: 'BudgetBee',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static dynamic sanitize(dynamic value) => _sanitize(value);

  static dynamic _sanitize(dynamic value) {
    if (value is List) return value.map(_sanitize).toList(growable: false);
    if (value is! Map) return value;
    return value.map((key, item) {
      final normalized = key.toString().toLowerCase();
      return MapEntry(
        key,
        _sensitiveKeys.contains(normalized) ? '[REDACTED]' : _sanitize(item),
      );
    });
  }

  static String _encode(dynamic value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      return value?.toString() ?? 'null';
    }
  }

  static const _sensitiveKeys = {
    'authorization',
    'token',
    'access_token',
    'password',
    'password_confirmation',
    'name',
    'email',
    'phone',
    'user',
  };
}
