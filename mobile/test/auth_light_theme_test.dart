import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/settings/app_settings_service.dart';
import 'package:expense_tracker/core/settings/theme_controller.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/theme/auth_theme.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/presentation/providers/app_providers.dart';
import 'package:expense_tracker/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'no saved theme defaults to light and survives an app restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final first = AppSettingsController(AppSettingsService(preferences));
      final restarted = AppSettingsController(
        AppSettingsService(await SharedPreferences.getInstance()),
      );

      expect(first.appThemeMode, AppThemeMode.light);
      expect(first.themeMode, ThemeMode.light);
      expect(restarted.themeMode, ThemeMode.light);
    },
  );

  test(
    'an explicitly saved dark preference remains dark for the app',
    () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final controller = AppSettingsController(
        AppSettingsService(await SharedPreferences.getInstance()),
      );

      expect(controller.appThemeMode, AppThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
    },
  );

  Future<void> pumpAuthApp(WidgetTester tester) async {
    final storage = TokenStorage();
    final auth = AuthProvider(AuthRepository(ApiClient(storage)), storage);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          initialRoute: AppRoutes.login,
          onGenerateInitialRoutes: (route) => [
            AppRoutes.onGenerateRoute(
              const RouteSettings(name: AppRoutes.login),
            )!,
          ],
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login stays light when the application and device are dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpAuthApp(tester);

    final context = tester.element(find.text('Welcome Back'));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(Theme.of(context).scaffoldBackgroundColor, AuthTheme.background);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AuthTheme.background,
    );
    final card = tester.widget<Container>(
      find.byKey(const ValueKey('auth-card-surface')),
    );
    expect((card.decoration! as BoxDecoration).color, AuthTheme.surface);
    final overlay = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .last;
    expect(overlay.value.statusBarIconBrightness, Brightness.dark);
    expect(overlay.value.systemNavigationBarColor, AuthTheme.background);
  });

  testWidgets('sign-up and forgot password share the light auth surfaces', (
    tester,
  ) async {
    await pumpAuthApp(tester);

    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Your Account'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Create Your Account'))).brightness,
      Brightness.light,
    );
    expect(
      find.text('Start tracking your money with BudgetBee.'),
      findsOneWidget,
    );

    Navigator.of(tester.element(find.text('Create Your Account'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Your Password'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Reset Your Password'))).brightness,
      Brightness.light,
    );
  });

  testWidgets(
    'login and sign-up remain scrollable on a small keyboard screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await pumpAuthApp(tester);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
