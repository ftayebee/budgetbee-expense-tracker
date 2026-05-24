import 'package:flutter/material.dart';
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
        title: 'ExpenseTrack',
        debugShowCheckedModeBanner: false,
        themeMode: settings.themeMode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
        builder: (context, child) =>
            AppLockGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
