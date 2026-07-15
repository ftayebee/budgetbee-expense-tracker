import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService(this._preferences);

  static const _themeModeKey = 'theme_mode';
  static const _currencyKey = 'currency_code';
  static const _appLockEnabledKey = 'app_lock_enabled';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _appLockTimeoutSecondsKey = 'app_lock_timeout_seconds';
  static const _onboardingCompletedKey = 'has_completed_onboarding';

  final SharedPreferences _preferences;

  String get themeMode => _preferences.getString(_themeModeKey) ?? 'system';
  Future<void> setThemeMode(String value) =>
      _preferences.setString(_themeModeKey, value);

  String get currencyCode => _preferences.getString(_currencyKey) ?? 'BDT';
  Future<void> setCurrencyCode(String value) =>
      _preferences.setString(_currencyKey, value);

  bool get appLockEnabled => _preferences.getBool(_appLockEnabledKey) ?? false;
  Future<void> setAppLockEnabled(bool value) =>
      _preferences.setBool(_appLockEnabledKey, value);

  bool get biometricEnabled =>
      _preferences.getBool(_biometricEnabledKey) ?? false;
  Future<void> setBiometricEnabled(bool value) =>
      _preferences.setBool(_biometricEnabledKey, value);

  int get appLockTimeoutSeconds =>
      _preferences.getInt(_appLockTimeoutSecondsKey) ?? 30;
  Future<void> setAppLockTimeoutSeconds(int value) =>
      _preferences.setInt(_appLockTimeoutSecondsKey, value);

  bool get hasCompletedOnboarding =>
      _preferences.getBool(_onboardingCompletedKey) ?? false;
  Future<void> completeOnboarding() =>
      _preferences.setBool(_onboardingCompletedKey, true);
}
