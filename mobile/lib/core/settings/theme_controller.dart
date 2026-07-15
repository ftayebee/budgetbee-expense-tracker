import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';
import 'app_settings_service.dart';

enum AppThemeMode { system, light, dark }

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._service) {
    _themeMode = _parseThemeMode(_service.themeMode);
    _currencyCode = _service.currencyCode;
    CurrencyFormatter.currentCode = _currencyCode;
  }

  final AppSettingsService _service;
  late AppThemeMode _themeMode;
  late String _currencyCode;

  AppThemeMode get appThemeMode => _themeMode;
  String get currencyCode => _currencyCode;
  bool get hasCompletedOnboarding => _service.hasCompletedOnboarding;

  ThemeMode get themeMode => switch (_themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _service.setThemeMode(mode.name);
    notifyListeners();
  }

  Future<void> setCurrencyCode(String code) async {
    _currencyCode = code;
    CurrencyFormatter.currentCode = code;
    await _service.setCurrencyCode(code);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _service.completeOnboarding();
    notifyListeners();
  }

  AppThemeMode _parseThemeMode(String value) => AppThemeMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AppThemeMode.system,
  );
}
