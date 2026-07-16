import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../presentation/widgets/app_widgets.dart';
import '../constants/app_colors.dart';
import 'app_theme.dart';

class AuthTheme {
  AuthTheme._();

  static const background = Color(0xFFFFF8F3);
  static const surface = Colors.white;
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const textPrimary = Color(0xFF1C1917);
  static const textSecondary = Color(0xFF78716C);
  static const border = Color(0xFFE7E5E4);
  static const inputFill = Color(0xFFFAFAF9);

  static const systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: border,
    systemNavigationBarContrastEnforced: false,
  );

  static ThemeData get data {
    final base = AppTheme.light();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        surface: background,
        surfaceContainer: surface,
        surfaceContainerHigh: inputFill,
        outlineVariant: border,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: background,
        foregroundColor: textPrimary,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: inputFill,
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: _border(border),
        enabledBorder: _border(border),
        focusedBorder: _border(primary, width: 1.6),
        errorBorder: _border(AppColors.expense),
        focusedErrorBorder: _border(AppColors.expense, width: 1.6),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}

class AuthRouteTheme extends StatelessWidget {
  const AuthRouteTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: AuthTheme.data,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: AuthTheme.systemUiOverlayStyle,
      child: ColoredBox(color: AuthTheme.background, child: child),
    ),
  );
}

class AuthFormPage extends StatelessWidget {
  const AuthFormPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    this.footer,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AuthTheme.background,
    resizeToAvoidBottomInset: true,
    body: Stack(
      children: [
        Positioned(
          top: -190,
          left: -130,
          right: -130,
          child: IgnorePointer(
            child: Container(
              height: 410,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AuthTheme.primary.withValues(alpha: .13),
                    AuthTheme.background.withValues(alpha: 0),
                  ],
                  stops: const [0, .72],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 36,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onBack != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Back',
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    const Center(
                      child: AppLogo(
                        width: 230,
                        height: 82,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AuthTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AuthTheme.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    AuthCard(child: form),
                    if (footer != null) ...[
                      const SizedBox(height: 14),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('auth-card-surface'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AuthTheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AuthTheme.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}
