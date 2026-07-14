import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/repositories/repositories.dart';
import '../domain/analytics_models.dart';
import '../domain/analytics_service.dart';

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
  int _transactionRevision = 0;
  int? _userId;
  int _requestId = 0;

  Future<void> load({AnalyticsFilter? filter, bool force = false}) async {
    if (filter != null) this.filter = filter;
    final key = _cacheKey(this.filter);
    if (!force && _cache[key] != null) {
      snapshot = _cache[key]!;
      error = null;
      notifyListeners();
      return;
    }

    final requestId = ++_requestId;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final dataset = await _repository.analytics(this.filter);
      if (requestId != _requestId) return;
      final calculated = _service.calculate(dataset, this.filter);
      _cache[key] = calculated;
      snapshot = calculated;
    } on ApiException catch (exception) {
      if (requestId == _requestId) error = exception.message;
    } catch (_) {
      if (requestId == _requestId) {
        error = 'Analytics could not be calculated. Pull to refresh and retry.';
      }
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
  }

  void clear() {
    _cache.clear();
    snapshot = null;
    error = null;
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
}
