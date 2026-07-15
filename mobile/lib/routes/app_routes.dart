import 'package:flutter/material.dart';

import '../presentation/screens/budgets/safe_add_budget_screen.dart';
import '../presentation/screens/categories/safe_add_category_screen.dart';
import '../presentation/screens/goals/goals_screen.dart';
import '../presentation/screens/settings/safe_settings_screens.dart';
import '../presentation/screens/settings/about_app_screen.dart';
import '../presentation/screens/transactions/compact_add_transaction_screen.dart';
import '../presentation/screens/auth/premium_auth_screens.dart';
import '../presentation/screens/all_screens.dart';

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

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const PremiumSplashScreen(),
    onboarding: (_) => const PremiumOnboardingScreen(),
    login: (_) => const PremiumLoginScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    register: (_) => const RegisterScreen(),
    dashboard: (_) => const DashboardScreen(),
    transactions: (_) => const TransactionsScreen(),
    addTransaction: (_) => const CompactAddTransactionScreen(),
    editTransaction: (context) => CompactAddTransactionScreen(
      transaction: ModalRoute.of(context)!.settings.arguments as dynamic,
    ),
    transactionDetails: (_) => const TransactionDetailsScreen(),
    accounts: (_) => const AccountsScreen(),
    addAccount: (_) => const AddAccountScreen(),
    categories: (_) => const CategoriesScreen(),
    addCategory: (_) => const SafeAddCategoryScreen(),
    budgets: (_) => const BudgetsScreen(),
    addBudget: (_) => const SafeAddBudgetScreen(),
    reports: (_) => const ReportsScreen(),
    goals: (_) => const GoalsScreen(),
    profile: (_) => const SafeProfileScreen(),
    editProfile: (_) => const SafeEditProfileScreen(),
    settings: (_) => const SafeSettingsScreen(),
    about: (_) => const AboutAppScreen(),
  };
}
