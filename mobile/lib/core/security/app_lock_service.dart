import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../settings/app_settings_service.dart';

class AppLockService extends ChangeNotifier {
  AppLockService(this._settings, this._secureStorage);

  static const _pinKey = 'app_lock_pin';

  final AppSettingsService _settings;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _locked = false;

  bool get locked => _locked;
  bool get enabled => _settings.appLockEnabled;
  bool get biometricEnabled => _settings.biometricEnabled;

  Future<void> initialize() async {
    _locked = enabled && await hasPin();
    notifyListeners();
  }

  Future<bool> hasPin() async =>
      (await _secureStorage.read(key: _pinKey))?.isNotEmpty == true;

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    await _settings.setAppLockEnabled(value);
    _locked = false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _settings.setBiometricEnabled(value);
    notifyListeners();
  }

  Future<void> savePin(String pin) =>
      _secureStorage.write(key: _pinKey, value: pin);

  Future<bool> verifyPin(String pin) async =>
      await _secureStorage.read(key: _pinKey) == pin;

  Future<bool> unlockWithBiometric() async {
    if (!biometricEnabled || !await canUseBiometrics()) return false;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock ExpenseTrack',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) unlock();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await verifyPin(pin);
    if (ok) unlock();
    return ok;
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }

  void lock() {
    if (!enabled) return;
    Future.microtask(() async {
      if (!await hasPin()) return;
      _locked = true;
      notifyListeners();
    });
  }
}
