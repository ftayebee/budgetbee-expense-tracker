import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF00A896);
  static const primaryDark = Color(0xFF087F8C);
  static const primaryDeep = Color(0xFF006A60);
  static const primarySoft = Color(0xFFE4F8F4);
  static const income = Color(0xFF20B764);
  static const incomeSoft = Color(0xFFEAF8EF);
  static const expense = Color(0xFFEF5A3C);
  static const expenseSoft = Color(0xFFFFEFEB);
  static const warning = Color(0xFFF4B73F);
  static const warningSoft = Color(0xFFFFF6DD);
  static const background = Color(0xFFF8FAFA);
  static const card = Colors.white;
  static const border = Color(0xFFE8EEF0);
  static const text = Color(0xFF1B2424);
  static const muted = Color(0xFF727A80);
  static const faint = Color(0xFFA9B0B5);
  static const darkStage = Color(0xFF111827);
  static const darkSurface = Color(0xFF182231);
  static const darkSurfaceHigh = Color(0xFF222E3D);
  static const darkBorder = Color(0xFF344252);
  static const darkText = Color(0xFFF2F5F7);
  static const darkMuted = Color(0xFFB3BDC7);
  static const darkFaint = Color(0xFF8995A3);

  static const categoryOrange = Color(0xFFE9A43A);
  static const categoryBlue = Color(0xFF2BA7C9);
  static const categoryPurple = Color(0xFF7566D9);
  static const categoryPink = Color(0xFFC95ABD);
}

extension AppColorContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => colors.surface;
  Color get appCard => colors.surfaceContainer;
  Color get appElevatedSurface => colors.surfaceContainerHigh;
  Color get appBorder => colors.outlineVariant;
  Color get appText => colors.onSurface;
  Color get appMuted => colors.onSurfaceVariant;
  Color get appFaint => colors.onSurfaceVariant.withValues(alpha: .72);
  Color get appPrimarySoft =>
      isDark ? AppColors.primary.withValues(alpha: .18) : AppColors.primarySoft;
  Color get appIncomeSoft =>
      isDark ? AppColors.income.withValues(alpha: .18) : AppColors.incomeSoft;
  Color get appExpenseSoft =>
      isDark ? AppColors.expense.withValues(alpha: .18) : AppColors.expenseSoft;
  Color get appWarningSoft =>
      isDark ? AppColors.warning.withValues(alpha: .18) : AppColors.warningSoft;
}
