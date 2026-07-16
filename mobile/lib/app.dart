import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/security/lock_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/theme_controller.dart';
import 'routes/app_routes.dart';

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsController>(
      builder: (_, settings, __) => MaterialApp(
        title: 'BudgetBee',
        debugShowCheckedModeBanner: false,
        themeMode: settings.themeMode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        builder: (context, child) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: theme.colorScheme.surfaceContainer,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarDividerColor: theme.colorScheme.outlineVariant,
              systemNavigationBarContrastEnforced: false,
            ),
            child: AppLockGate(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
