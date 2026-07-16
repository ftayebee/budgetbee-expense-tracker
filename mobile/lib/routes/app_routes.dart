import 'package:flutter/material.dart';
import '../core/navigation/app_page_transitions.dart';

import '../presentation/screens/budgets/safe_add_budget_screen.dart';
import '../presentation/screens/categories/safe_add_category_screen.dart';
import '../presentation/screens/goals/goals_screen.dart';
import '../presentation/screens/main/main_shell.dart';
import '../presentation/screens/settings/safe_settings_screens.dart';
import '../presentation/screens/settings/about_app_screen.dart';
import '../presentation/screens/settings/privacy_policy_screen.dart';
import '../presentation/screens/transactions/compact_add_transaction_screen.dart';
import '../presentation/screens/auth/premium_auth_screens.dart';
import '../presentation/screens/auth/light_auth_form_screens.dart';
import '../core/theme/auth_theme.dart';
import '../presentation/screens/all_screens.dart';
import '../data/models/transaction_model.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const forgotPassword = '/forgot-password';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const transactions = '/transactions';
  static const addTransaction = '/transactions/add';
  static const editTransaction = '/transactions/edit';
  static const transactionDetails = '/transactions/detail';
  static const accounts = '/accounts';
  static const addAccount = '/accounts/add';
  static const categories = '/categories';
  static const addCategory = '/categories/add';
  static const budgets = '/budgets';
  static const addBudget = '/budgets/add';
  static const reports = '/reports';
  static const goals = '/goals';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
  static const about = '/settings/about';
  static const privacyPolicy = '/settings/privacy-policy';

  static Map<String, WidgetBuilder> get _builders => {
    splash: (_) => const PremiumSplashScreen(),
    onboarding: (_) => const PremiumOnboardingScreen(),
    login: (_) => const PremiumLoginScreen(),
    forgotPassword: (_) => const LightForgotPasswordScreen(),
    register: (_) => const LightRegisterScreen(),
    dashboard: (_) => const MainShell(initialIndex: 0),
    transactions: (_) => const MainShell(initialIndex: 1),
    addTransaction: (_) => const CompactAddTransactionScreen(),
    transactionDetails: (_) => const TransactionDetailsScreen(),
    accounts: (_) => const AccountsScreen(),
    addAccount: (_) => const AddAccountScreen(),
    categories: (_) => const CategoriesScreen(),
    addCategory: (_) => const SafeAddCategoryScreen(),
    budgets: (_) => const BudgetsScreen(),
    addBudget: (_) => const SafeAddBudgetScreen(),
    reports: (_) => const MainShell(initialIndex: 2),
    goals: (_) => const GoalsScreen(),
    profile: (_) => const SafeProfileScreen(),
    editProfile: (_) => const SafeEditProfileScreen(),
    settings: (_) => const MainShell(initialIndex: 3),
    about: (_) => const AboutAppScreen(),
    privacyPolicy: (_) => const PrivacyPolicyScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
    if (routeSettings.name == editTransaction) {
      final transaction = routeSettings.arguments;
      if (transaction is! TransactionModel || transaction.id <= 0) return null;
      return AppPageTransitions.route<bool>(
        builder: (_) => CompactAddTransactionScreen(transaction: transaction),
        settings: routeSettings,
        style: AppTransitionStyle.modal,
      );
    }
    final builder = _builders[routeSettings.name];
    if (builder == null) return null;
    final style = switch (routeSettings.name) {
      splash ||
      onboarding ||
      login ||
      register ||
      forgotPassword ||
      dashboard => AppTransitionStyle.authentication,
      addTransaction ||
      editTransaction ||
      addAccount ||
      addCategory ||
      addBudget => AppTransitionStyle.modal,
      transactions || reports || settings => AppTransitionStyle.tab,
      _ => AppTransitionStyle.forward,
    };
    final isAuthRoute = {
      onboarding,
      login,
      register,
      forgotPassword,
    }.contains(routeSettings.name);
    return AppPageTransitions.route(
      builder: isAuthRoute
          ? (context) => AuthRouteTheme(child: builder(context))
          : builder,
      settings: routeSettings,
      style: style,
      transitionBackgroundColor: isAuthRoute ? AuthTheme.background : null,
    );
  }
}
