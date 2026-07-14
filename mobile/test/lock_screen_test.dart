import 'package:expense_tracker/core/security/app_lock_service.dart';
import 'package:expense_tracker/core/security/lock_screen.dart';
import 'package:expense_tracker/core/settings/app_settings_service.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnavailableAuthenticator implements DeviceAuthenticator {
  @override
  Future<DeviceAuthenticationResult> authenticate() async =>
      DeviceAuthenticationResult.unavailable;

  @override
  Future<bool> isAvailable() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppLockService> createService() async {
    SharedPreferences.setMockInitialValues({
      'app_lock_enabled': true,
      'biometric_enabled': false,
    });
    FlutterSecureStorage.setMockInitialValues({'app_lock_pin': '1234'});
    final preferences = await SharedPreferences.getInstance();
    final service = AppLockService(
      AppSettingsService(preferences),
      const FlutterSecureStorage(),
      authenticator: _UnavailableAuthenticator(),
    );
    await service.initialize();
    return service;
  }

  Future<void> pumpGate(WidgetTester tester, AppLockService service) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: service,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AppLockGate(child: Scaffold(body: Text('Main app'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('incorrect PIN stays locked and displays validation', (
    tester,
  ) async {
    final service = await createService();
    await pumpGate(tester, service);

    await tester.enterText(find.byType(TextFormField), '9999');
    await tester.tap(find.widgetWithText(TextButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect PIN.'), findsOneWidget);
    expect(find.text('App Locked'), findsOneWidget);
    expect(service.locked, isTrue);
  });

  testWidgets('correct PIN reveals existing app without replacing navigation', (
    tester,
  ) async {
    final service = await createService();
    await pumpGate(tester, service);

    await tester.enterText(find.byType(TextFormField), '1234');
    await tester.tap(find.widgetWithText(TextButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('App Locked'), findsNothing);
    expect(find.text('Main app'), findsOneWidget);
    expect(service.locked, isFalse);
  });
}
