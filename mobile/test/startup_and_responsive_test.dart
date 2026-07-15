import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/settings/app_settings_service.dart';
import 'package:expense_tracker/core/settings/theme_controller.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/presentation/providers/app_providers.dart';
import 'package:expense_tracker/presentation/screens/auth/premium_auth_screens.dart';
import 'package:expense_tracker/presentation/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup decision separates onboarding, login, and dashboard', () {
    expect(
      resolveStartupDestination(
        hasCompletedOnboarding: false,
        isAuthenticated: false,
      ),
      StartupDestination.onboarding,
    );
    expect(
      resolveStartupDestination(
        hasCompletedOnboarding: true,
        isAuthenticated: false,
      ),
      StartupDestination.login,
    );
    expect(
      resolveStartupDestination(
        hasCompletedOnboarding: false,
        isAuthenticated: true,
      ),
      StartupDestination.dashboard,
    );
  });

  test(
    'onboarding completion persists independently of logout state',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = AppSettingsService(preferences);
      expect(service.hasCompletedOnboarding, isFalse);

      await service.completeOnboarding();
      final restartedService = AppSettingsService(
        await SharedPreferences.getInstance(),
      );
      expect(restartedService.hasCompletedOnboarding, isTrue);
      expect(preferences.getBool('has_completed_onboarding'), isTrue);
    },
  );

  testWidgets('Skip completes onboarding and opens login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettingsController(
      AppSettingsService(await SharedPreferences.getInstance()),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const PremiumOnboardingScreen(),
          routes: {'/login': (_) => const Scaffold(body: Text('Login route'))},
        ),
      ),
    );

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(settings.hasCompletedOnboarding, isTrue);
    expect(find.text('Login route'), findsOneWidget);
  });

  testWidgets('Get Started completes all three onboarding pages', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettingsController(
      AppSettingsService(await SharedPreferences.getInstance()),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const PremiumOnboardingScreen(),
          routes: {'/login': (_) => const Scaffold(body: Text('Login route'))},
        ),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(settings.hasCompletedOnboarding, isTrue);
    expect(find.text('Login route'), findsOneWidget);
  });

  testWidgets('premium login scrolls without overflow on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final storage = TokenStorage();
    final auth = AuthProvider(AuthRepository(ApiClient(storage)), storage);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const PremiumLoginScreen(),
          routes: {
            '/forgot-password': (_) => const SizedBox(),
            '/register': (_) => const SizedBox(),
          },
        ),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom app bar stays below the status bar inset', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 40)),
          child: Scaffold(
            appBar: PrototypeTopBar(title: 'Add Transaction', onBack: () {}),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byIcon(Icons.arrow_back_rounded)).dy,
      greaterThanOrEqualTo(40),
    );
    expect(find.text('Add Transaction'), findsOneWidget);
  });
}
