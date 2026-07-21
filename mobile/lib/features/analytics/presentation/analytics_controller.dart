import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/repositories.dart';
import '../domain/analytics_models.dart';
import '../domain/analytics_service.dart';

enum AnalyticsErrorKind {
  authentication,
  network,
  timeout,
  server,
  parsing,
  unexpected,
}

class AnalyticsController extends ChangeNotifier {
  AnalyticsController(this._repository, {AnalyticsService? service})
    : _service = service ?? const AnalyticsService();

  final ReportRepository _repository;
  final AnalyticsService _service;
  final Map<String, AnalyticsSnapshot> _cache = {};

  AnalyticsFilter filter = AnalyticsFilter.thisMonth();
  AnalyticsSnapshot? snapshot;
  bool loading = false;
  String? error;
  AnalyticsErrorKind? errorKind;
  int _transactionRevision = 0;
  int? _userId;
  int _requestId = 0;

  Future<void> load({AnalyticsFilter? filter, bool force = false}) async {
    AppLogger.debug('Reports controller initialized');
    if (filter != null) this.filter = filter;
    final key = _cacheKey(this.filter);
    if (!force && _cache[key] != null) {
      snapshot = _cache[key]!;
      error = null;
      errorKind = null;
      notifyListeners();
      return;
    }

    final requestId = ++_requestId;
    loading = true;
    error = null;
    errorKind = null;
    AppLogger.debug(
      'Reports request started',
      context: {'query_parameters': this.filter.toQuery()},
    );
    notifyListeners();
    try {
      final dataset = await _repository.analytics(this.filter);
      AppLogger.debug('Reports parsing started');
      if (requestId != _requestId) return;
      final calculated = _service.calculate(dataset, this.filter);
      AppLogger.debug('Reports parsing completed');
      _cache[key] = calculated;
      snapshot = calculated;
      AppLogger.debug(
        'Reports state updated',
        context: {
          'transaction_count': calculated.transactions.length,
          'empty': calculated.transactions.isEmpty,
        },
      );
    } on ApiException catch (exception) {
      if (requestId == _requestId) {
        errorKind = _kindFor(exception);
        error = _messageFor(errorKind!);
      }
      AppLogger.debug(
        'Reports request failed',
        context: {
          'status': exception.statusCode,
          'exception_type': exception.runtimeType.toString(),
          'message': exception.message,
        },
      );
    } on FormatException catch (exception, stackTrace) {
      if (requestId == _requestId) {
        errorKind = AnalyticsErrorKind.parsing;
        error = _messageFor(errorKind!);
      }
      AppLogger.debug(
        'Reports parsing failed',
        context: {
          'exception_type': exception.runtimeType.toString(),
          'message': exception.message,
        },
        error: exception,
        stackTrace: stackTrace,
      );
    } catch (exception, stackTrace) {
      if (requestId == _requestId) {
        errorKind = AnalyticsErrorKind.unexpected;
        error = _messageFor(errorKind!);
      }
      AppLogger.debug(
        'Reports unexpected UI error',
        context: {
          'exception_type': exception.runtimeType.toString(),
          'message': exception.toString(),
        },
        error: exception,
        stackTrace: stackTrace,
      );
    } finally {
      if (requestId == _requestId) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() => load(force: true);

  void synchronizeTransactionRevision(int revision) {
    if (_transactionRevision == revision) return;
    _transactionRevision = revision;
    _cache.clear();
    if (snapshot != null) Future.microtask(refresh);
  }

  void synchronizeUser(int? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _cache.clear();
    snapshot = null;
    error = null;
    errorKind = null;
  }

  void clear() {
    _cache.clear();
    snapshot = null;
    error = null;
    errorKind = null;
    notifyListeners();
  }

  String _cacheKey(AnalyticsFilter value) => [
    value.from.toIso8601String(),
    value.to.toIso8601String(),
    value.type,
    value.accountId,
    value.categoryId,
    value.paymentMethod,
  ].join('|');

  AnalyticsErrorKind _kindFor(ApiException exception) {
    final status = exception.statusCode;
    if (status == 401) return AnalyticsErrorKind.authentication;
    if (status == 408 ||
        exception.message.toLowerCase().contains('timed out')) {
      return AnalyticsErrorKind.timeout;
    }
    if (status != null && status >= 500) return AnalyticsErrorKind.server;
    if (exception.message.toLowerCase().contains('invalid response')) {
      return AnalyticsErrorKind.parsing;
    }
    return AnalyticsErrorKind.network;
  }

  String _messageFor(AnalyticsErrorKind kind) => switch (kind) {
    AnalyticsErrorKind.authentication =>
      'Your session has expired. Please sign in again.',
    AnalyticsErrorKind.timeout =>
      'Unable to load reports because the request timed out. Please try again.',
    AnalyticsErrorKind.network =>
      'Unable to load reports. Check your internet connection and try again.',
    AnalyticsErrorKind.server =>
      'The reports service is temporarily unavailable. Please try again.',
    AnalyticsErrorKind.parsing =>
      'The reports response could not be processed. Please try again.',
    AnalyticsErrorKind.unexpected =>
      'Reports could not be displayed. Please try again.',
  };
}
