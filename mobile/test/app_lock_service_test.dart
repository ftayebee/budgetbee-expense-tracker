import 'dart:async';

import 'package:expense_tracker/core/security/app_lock_service.dart';
import 'package:expense_tracker/core/settings/app_settings_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthenticator implements DeviceAuthenticator {
  bool available = true;
  DeviceAuthenticationResult result = DeviceAuthenticationResult.success;
  int calls = 0;

  @override
  Future<DeviceAuthenticationResult> authenticate() async {
    calls++;
    return result;
  }

  @override
  Future<bool> isAvailable() async => available;
}

class _PendingAuthenticator implements DeviceAuthenticator {
  final result = Completer<DeviceAuthenticationResult>();
  int calls = 0;

  @override
  Future<DeviceAuthenticationResult> authenticate() {
    calls++;
    return result.future;
  }

  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late AppSettingsService settings;
  late FlutterSecureStorage storage;
  late _FakeAuthenticator authenticator;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_lock_enabled': true,
      'biometric_enabled': true,
      'app_lock_timeout_seconds': 30,
    });
    FlutterSecureStorage.setMockInitialValues({'app_lock_pin': '1234'});
    settings = AppSettingsService(await SharedPreferences.getInstance());
    storage = const FlutterSecureStorage();
    authenticator = _FakeAuthenticator();
    now = DateTime(2026, 7, 15, 12);
  });

  AppLockService createService() => AppLockService(
    settings,
    storage,
    authenticator: authenticator,
    now: () => now,
  );

  test('fresh launch starts locked when lock and PIN are configured', () async {
    final service = createService();

    await service.initialize();

    expect(service.locked, isTrue);
    expect(service.hasAuthenticatedForCurrentSession, isFalse);
  });

  test('biometric lifecycle transitions do not relock after success', () async {
    final service = createService();
    await service.initialize();

    final authentication = service.unlockWithBiometric();
    service.handleLifecycleState(AppLifecycleState.inactive);
    service.handleLifecycleState(AppLifecycleState.paused);
    service.handleLifecycleState(AppLifecycleState.resumed);
    expect(await authentication, DeviceAuthenticationResult.success);

    expect(service.locked, isFalse);
    expect(service.isAuthenticating, isFalse);
    expect(service.backgroundedAt, isNull);
    expect(service.hasAuthenticatedForCurrentSession, isTrue);
    expect(authenticator.calls, 1);
  });

  test('brief background transition preserves unlocked session', () async {
    final service = createService();
    await service.initialize();
    expect(await service.unlockWithPin('1234'), isTrue);

    service.handleLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 20));
    service.handleLifecycleState(AppLifecycleState.resumed);

    expect(service.locked, isFalse);
    expect(service.backgroundedAt, isNull);
  });

  test('temporary inactive state from system UI does not lock', () async {
    final service = createService();
    await service.initialize();
    expect(await service.unlockWithPin('1234'), isTrue);

    service.handleLifecycleState(AppLifecycleState.inactive);
    now = now.add(const Duration(minutes: 5));
    service.handleLifecycleState(AppLifecycleState.resumed);

    expect(service.locked, isFalse);
    expect(service.backgroundedAt, isNull);
  });

  test('background transition beyond timeout locks once', () async {
    final service = createService();
    await service.initialize();
    expect(await service.unlockWithPin('1234'), isTrue);

    service.handleLifecycleState(AppLifecycleState.hidden);
    now = now.add(const Duration(seconds: 31));
    service.handleLifecycleState(AppLifecycleState.resumed);

    expect(service.locked, isTrue);
    expect(service.hasAuthenticatedForCurrentSession, isFalse);
  });

  test('cancelled biometric attempt stays locked without retrying', () async {
    authenticator.result = DeviceAuthenticationResult.cancelled;
    final service = createService();
    await service.initialize();

    expect(
      await service.unlockWithBiometric(),
      DeviceAuthenticationResult.cancelled,
    );
    service.handleLifecycleState(AppLifecycleState.resumed);

    expect(service.locked, isTrue);
    expect(service.isAuthenticating, isFalse);
    expect(authenticator.calls, 1);
  });

  test('unavailable and failed device authentication remain locked', () async {
    final service = createService();
    await service.initialize();

    authenticator.result = DeviceAuthenticationResult.unavailable;
    expect(
      await service.unlockWithBiometric(),
      DeviceAuthenticationResult.unavailable,
    );
    expect(service.locked, isTrue);

    authenticator.result = DeviceAuthenticationResult.failed;
    expect(
      await service.unlockWithBiometric(),
      DeviceAuthenticationResult.failed,
    );
    expect(service.locked, isTrue);
  });

  test('concurrent device authentication requests are deduplicated', () async {
    final pending = _PendingAuthenticator();
    final service = AppLockService(
      settings,
      storage,
      authenticator: pending,
      now: () => now,
    );
    await service.initialize();

    final first = service.unlockWithBiometric();
    final duplicate = await service.unlockWithBiometric();
    expect(duplicate, DeviceAuthenticationResult.failed);
    expect(pending.calls, 1);

    pending.result.complete(DeviceAuthenticationResult.success);
    expect(await first, DeviceAuthenticationResult.success);
    expect(service.locked, isFalse);
  });

  test('valid legacy PIN is migrated to a salted hash', () async {
    final service = createService();
    await service.initialize();

    expect(await service.unlockWithPin('1234'), isTrue);
    expect(await storage.read(key: 'app_lock_pin'), isNull);
    expect(await storage.read(key: 'app_lock_pin_hash'), isNotEmpty);
    expect(await storage.read(key: 'app_lock_pin_salt'), isNotEmpty);
    expect(await service.verifyPin('0000'), isFalse);
    expect(await service.verifyPin('1234'), isTrue);
  });

  test('reinitializing after a development rebuild preserves unlock', () async {
    final service = createService();
    await service.initialize();
    expect(await service.unlockWithPin('1234'), isTrue);

    await service.initialize();

    expect(service.locked, isFalse);
    expect(service.hasAuthenticatedForCurrentSession, isTrue);
  });
}
