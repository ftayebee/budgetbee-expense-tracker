import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/security/app_lock_service.dart';
import 'core/settings/app_settings_service.dart';
import 'core/settings/theme_controller.dart';
import 'core/storage/token_storage.dart';
import 'data/repositories/repositories.dart';
import 'presentation/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final settingsService = AppSettingsService(preferences);
  final storage = TokenStorage();
  final apiClient = ApiClient(storage);
  final repositories = Repositories(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppSettingsController(settingsService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AppLockService(settingsService, const FlutterSecureStorage()),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repositories.auth, storage),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(repositories.dashboard),
        ),
        ChangeNotifierProvider(
          create: (_) => AccountProvider(repositories.accounts),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(repositories.categories),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(repositories.transactions),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(repositories.budgets),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(repositories.reports),
        ),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}
