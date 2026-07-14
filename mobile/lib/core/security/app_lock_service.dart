import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../settings/app_settings_service.dart';

enum DeviceAuthenticationResult {
  success,
  failed,
  cancelled,
  unavailable,
  error,
}

abstract interface class DeviceAuthenticator {
  Future<bool> isAvailable();
  Future<DeviceAuthenticationResult> authenticate();
}

class LocalDeviceAuthenticator implements DeviceAuthenticator {
  LocalDeviceAuthenticator([LocalAuthentication? localAuthentication])
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _localAuthentication.isDeviceSupported() ||
          await _localAuthentication.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<DeviceAuthenticationResult> authenticate() async {
    if (!await isAvailable()) return DeviceAuthenticationResult.unavailable;
    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Unlock BudgetBee',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      return authenticated
          ? DeviceAuthenticationResult.success
          : DeviceAuthenticationResult.cancelled;
    } on PlatformException catch (error) {
      const unavailableCodes = {
        'NotAvailable',
        'NotEnrolled',
        'PasscodeNotSet',
        'no_fragment_activity',
      };
      return unavailableCodes.contains(error.code)
          ? DeviceAuthenticationResult.unavailable
          : DeviceAuthenticationResult.error;
    }
  }
}

class AppLockService extends ChangeNotifier {
  AppLockService(
    this._settings,
    this._secureStorage, {
    DeviceAuthenticator? authenticator,
    DateTime Function()? now,
  }) : _authenticator = authenticator ?? LocalDeviceAuthenticator(),
       _now = now ?? DateTime.now;

  static const _legacyPinKey = 'app_lock_pin';
  static const _pinHashKey = 'app_lock_pin_hash';
  static const _pinSaltKey = 'app_lock_pin_salt';

  final AppSettingsService _settings;
  final FlutterSecureStorage _secureStorage;
  final DeviceAuthenticator _authenticator;
  final DateTime Function() _now;

  bool _initialized = false;
  bool _locked = false;
  bool _isAuthenticating = false;
  bool _hasAuthenticatedForCurrentSession = false;
  DateTime? _backgroundedAt;
  DeviceAuthenticationResult? _lastAuthenticationResult;

  bool get initialized => _initialized;
  bool get locked => _locked;
  bool get enabled => _settings.appLockEnabled;
  bool get biometricEnabled => _settings.biometricEnabled;
  bool get isAuthenticating => _isAuthenticating;
  bool get hasAuthenticatedForCurrentSession =>
      _hasAuthenticatedForCurrentSession;
  DateTime? get backgroundedAt => _backgroundedAt;
  Duration get lockTimeout =>
      Duration(seconds: _settings.appLockTimeoutSeconds);
  DeviceAuthenticationResult? get lastAuthenticationResult =>
      _lastAuthenticationResult;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _locked = enabled && await hasPin();
    _hasAuthenticatedForCurrentSession = !_locked;
    notifyListeners();
  }

  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    if (hash?.isNotEmpty == true) return true;
    return (await _secureStorage.read(key: _legacyPinKey))?.isNotEmpty == true;
  }

  Future<bool> canUseBiometrics() => _authenticator.isAvailable();

  Future<void> setEnabled(bool value) async {
    await _settings.setAppLockEnabled(value);
    _locked = false;
    _isAuthenticating = false;
    _hasAuthenticatedForCurrentSession = true;
    _backgroundedAt = null;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _settings.setBiometricEnabled(value);
    notifyListeners();
  }

  Future<void> setLockTimeout(Duration value) async {
    await _settings.setAppLockTimeoutSeconds(value.inSeconds);
    notifyListeners();
  }

  Future<void> savePin(String pin) async {
    final saltBytes = List<int>.generate(
      24,
      (_) => Random.secure().nextInt(256),
    );
    final salt = base64UrlEncode(saltBytes);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: _hashPin(pin, salt));
    await _secureStorage.delete(key: _legacyPinKey);
  }

  Future<bool> verifyPin(String pin) async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);
    if (hash != null && salt != null) {
      return _constantTimeEquals(hash, _hashPin(pin, salt));
    }

    final legacyPin = await _secureStorage.read(key: _legacyPinKey);
    if (legacyPin != pin) return false;
    await savePin(pin);
    return true;
  }

  Future<DeviceAuthenticationResult> unlockWithBiometric() async {
    if (_isAuthenticating) {
      return _lastAuthenticationResult ?? DeviceAuthenticationResult.failed;
    }
    if (!biometricEnabled) return DeviceAuthenticationResult.unavailable;

    _isAuthenticating = true;
    _lastAuthenticationResult = null;
    notifyListeners();
    try {
      final result = await _authenticator.authenticate();
      _lastAuthenticationResult = result;
      if (result == DeviceAuthenticationResult.success) {
        _completeUnlock();
      }
      return result;
    } catch (_) {
      _lastAuthenticationResult = DeviceAuthenticationResult.error;
      return DeviceAuthenticationResult.error;
    } finally {
      _isAuthenticating = false;
      _backgroundedAt = null;
      notifyListeners();
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    if (_isAuthenticating) return false;
    _isAuthenticating = true;
    notifyListeners();
    try {
      final valid = await verifyPin(pin);
      if (valid) _completeUnlock();
      return valid;
    } finally {
      _isAuthenticating = false;
      _backgroundedAt = null;
      notifyListeners();
    }
  }

  void handleLifecycleState(AppLifecycleState state) {
    if (!enabled || !_initialized || _isAuthenticating) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= _now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null || _locked) return;

    if (_now().difference(backgroundedAt) >= lockTimeout) {
      lock();
    }
  }

  void lock() {
    if (!enabled || _locked || _isAuthenticating) return;
    _locked = true;
    _hasAuthenticatedForCurrentSession = false;
    notifyListeners();
  }

  void _completeUnlock() {
    _locked = false;
    _hasAuthenticatedForCurrentSession = true;
    _backgroundedAt = null;
  }

  String _hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}
