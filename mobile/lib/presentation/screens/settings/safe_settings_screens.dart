import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/security/pin_setup_screen.dart';
import '../../../core/services/app_actions.dart';
import '../../../core/settings/app_currency.dart';
import '../../../core/settings/theme_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_routes.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

class SafeProfileScreen extends StatelessWidget {
  const SafeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Profile',
      onBack: () => Navigator.pop(context),
    ),
    body: SafeArea(
      child: Consumer2<AuthProvider, AppSettingsController>(
        builder: (_, auth, settings, __) {
          final user = auth.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PrototypeCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name.isNotEmpty == true ? user!.name[0] : 'A')
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Alex Johnson',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            user?.email ?? 'alex@email.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrototypeCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: '👤',
                      label: 'Edit Profile',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.editProfile),
                    ),
                    _SettingsRow(
                      icon: '💱',
                      label: 'Currency',
                      value: settings.currencyCode,
                    ),
                    _SettingsRow(
                      icon: '🌙',
                      label: 'Theme',
                      value: settings.appThemeMode.name,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrototypeButton(
                label: 'Sign Out',
                variant: ButtonVariant.expense,
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted)
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    );
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}

class SafeEditProfileScreen extends StatefulWidget {
  const SafeEditProfileScreen({super.key});

  @override
  State<SafeEditProfileScreen> createState() => _SafeEditProfileScreenState();
}

class _SafeEditProfileScreenState extends State<SafeEditProfileScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController phone;
  late String currency;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    name = TextEditingController(text: user?.name);
    email = TextEditingController(text: user?.email);
    phone = TextEditingController(text: user?.phone);
    currency = context.read<AppSettingsController>().currencyCode;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    appBar: PrototypeTopBar(
      title: 'Edit Profile',
      onBack: () => Navigator.pop(context),
    ),
    body: SafeArea(
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) => Form(
          key: form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            children: [
              PrototypeInput(
                controller: name,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: Validators.required,
              ),
              const SizedBox(height: 14),
              PrototypeInput(
                controller: email,
                label: 'Email',
                icon: Icons.mail_outline,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              PrototypeInput(
                controller: phone,
                label: 'Phone',
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 14),
              CustomDropdown<String>(
                value: currency,
                label: 'Currency',
                onChanged: (v) => setState(() => currency = v ?? 'BDT'),
                items: AppCurrency.supported
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.code,
                        child: Text('${c.code} - ${c.symbol}'),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              if (auth.error != null)
                Text(auth.error!, style: TextStyle(color: AppColors.expense)),
              PrototypeButton(
                label: auth.loading ? 'Saving...' : 'Save Profile',
                onPressed: auth.loading
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        await context
                            .read<AppSettingsController>()
                            .setCurrencyCode(currency);
                        final ok = await auth.updateProfile({
                          'name': name.text,
                          'email': email.text,
                          'phone': phone.text,
                          'currency': currency,
                        });
                        if (mounted && ok) Navigator.pop(context);
                      },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SafeSettingsScreen extends StatelessWidget {
  const SafeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const PrototypeBottomNav(active: AppRoutes.settings),
    body: SafeArea(
      bottom: false,
      child: Consumer3<AuthProvider, AppSettingsController, AppLockService>(
        builder: (_, auth, settings, lock, __) {
          final user = auth.user;
          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: context.appCard,
                  border: Border(bottom: BorderSide(color: context.appBorder)),
                ),
                child: Text(
                  'Settings',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: PrototypeCard(
                  child: Row(
                    children: [
                      const BudgetBeeBrand(
                        size: BrandSize.compact,
                        showSlogan: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.appText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Save smarter with clear financial insights.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: context.appMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: PrototypeCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty == true
                                    ? user!.name[0]
                                    : 'A')
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Alex Johnson',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              user?.email ?? 'alex@email.com',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.appMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PrototypeButton(
                        label: 'Edit',
                        variant: ButtonVariant.secondary,
                        fullWidth: false,
                        height: 34,
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.editProfile),
                      ),
                    ],
                  ),
                ),
              ),
              _SettingsSection(
                title: 'Account',
                rows: [
                  _SettingsRow(
                    icon: '👤',
                    label: 'Edit Profile',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.editProfile),
                  ),
                  _SettingsRow(
                    icon: '💱',
                    label: 'Currency',
                    value: settings.currencyCode,
                    onTap: () => _chooseCurrency(context),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Preferences',
                rows: [
                  _SettingsRow(
                    icon: '🌙',
                    label: 'Theme',
                    value: _themeLabel(settings.appThemeMode),
                    onTap: () => _chooseTheme(context),
                  ),
                  _SettingsRow(
                    icon: '🔐',
                    label: 'App Lock',
                    subtitle: 'PIN / Biometric',
                    trailing: _Toggle(
                      value: lock.enabled,
                      onTap: () => _toggleLock(context, !lock.enabled),
                    ),
                  ),
                  _SettingsRow(
                    icon: '☝️',
                    label: 'Use Fingerprint',
                    value: lock.biometricEnabled ? 'On' : 'Off',
                    onTap: () =>
                        _toggleBiometric(context, !lock.biometricEnabled),
                  ),
                  _SettingsRow(
                    icon: '🔢',
                    label: 'Set / Change PIN',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                    ),
                  ),
                  _SettingsRow(
                    icon: '⏱',
                    label: 'Lock timeout',
                    value: _lockTimeoutLabel(lock.lockTimeout),
                    onTap: () => _chooseLockTimeout(context),
                  ),
                  const _SettingsRow(
                    icon: '🌐',
                    label: 'Language',
                    value: 'English',
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Data',
                rows: [
                  _SettingsRow(
                    icon: '🎯',
                    label: 'Budgets',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.budgets),
                  ),
                  _SettingsRow(
                    icon: '💳',
                    label: 'Accounts',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.accounts),
                  ),
                  _SettingsRow(
                    icon: '🏷',
                    label: 'Categories',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.categories),
                  ),
                  const _SettingsRow(icon: '📤', label: 'Export CSV'),
                ],
              ),
              _SettingsSection(
                title: 'More',
                rows: [
                  _SettingsRow(
                    icon: '⭐',
                    label: 'Rate App',
                    onTap: () => AppActions.rateApp(context),
                  ),
                  _SettingsRow(
                    icon: 'ℹ️',
                    label: 'About BudgetBee',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                  ),
                  _SettingsRow(
                    icon: '📋',
                    label: 'Privacy Policy',
                    onTap: () => AppActions.openPrivacyPolicy(context),
                  ),
                  const _SettingsRow(
                    icon: 'ℹ️',
                    label: 'App Version',
                    value: 'See About',
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: PrototypeButton(
                  label: 'Sign Out',
                  variant: ButtonVariant.expense,
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted)
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (_) => false,
                      );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  static String _themeLabel(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => 'System',
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
  };

  static String _lockTimeoutLabel(Duration timeout) =>
      switch (timeout.inSeconds) {
        0 => 'Immediately',
        30 => '30 seconds',
        60 => '1 minute',
        300 => '5 minutes',
        _ => '${timeout.inMinutes} minutes',
      };

  static Future<void> _chooseLockTimeout(BuildContext context) async {
    const options = [
      Duration.zero,
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 5),
    ];
    final selected = await showModalBottomSheet<Duration>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (timeout) => ListTile(
                  title: Text(_lockTimeoutLabel(timeout)),
                  onTap: () => Navigator.pop(sheetContext, timeout),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await context.read<AppLockService>().setLockTimeout(selected);
    }
  }

  static Future<void> _chooseTheme(BuildContext context) async {
    final controller = context.read<AppSettingsController>();
    final selected = await showModalBottomSheet<AppThemeMode>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values
              .map(
                (mode) => ListTile(
                  title: Text(_themeLabel(mode)),
                  onTap: () => Navigator.pop(context, mode),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) await controller.setThemeMode(selected);
  }

  static Future<void> _chooseCurrency(BuildContext context) async {
    final settings = context.read<AppSettingsController>();
    final auth = context.read<AuthProvider>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppCurrency.supported
              .map(
                (currency) => ListTile(
                  title: Text('${currency.code} - ${currency.name}'),
                  trailing: Text(currency.symbol),
                  onTap: () => Navigator.pop(context, currency.code),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected == null) return;
    await settings.setCurrencyCode(selected);
    final user = auth.user;
    if (user != null) {
      await auth.updateProfile({
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'currency': selected,
      });
    }
  }

  static Future<void> _toggleLock(BuildContext context, bool enable) async {
    final lock = context.read<AppLockService>();
    if (!enable) {
      await lock.setEnabled(false);
      return;
    }
    if (!await lock.hasPin()) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
      if (ok != true) return;
    }
    await lock.setEnabled(true);
  }

  static Future<void> _toggleBiometric(
    BuildContext context,
    bool enable,
  ) async {
    final lock = context.read<AppLockService>();
    if (enable && !await lock.canUseBiometrics()) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fingerprint unlock is not available on this device.',
            ),
          ),
        );
      return;
    }
    await lock.setBiometricEnabled(enable);
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrototypeSectionLabel(title),
        PrototypeCard(
          padding: EdgeInsets.zero,
          child: Column(children: rows),
        ),
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
  });
  final String icon;
  final String label;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.appBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(icon, style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: context.appText),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 11, color: context.appFaint),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (value != null)
            Text(
              value!,
              style: TextStyle(fontSize: 13, color: context.appMuted),
            )
          else if (onTap != null)
            Text('›', style: TextStyle(fontSize: 18, color: context.appFaint)),
        ],
      ),
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onTap});
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? AppColors.primary : context.appBorder,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}
