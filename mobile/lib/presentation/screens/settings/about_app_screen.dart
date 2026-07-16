import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_links.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_actions.dart';
import '../../widgets/app_widgets.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const _features = <(IconData, String)>[
    (Icons.swap_vert_rounded, 'Income and expense tracking'),
    (Icons.account_balance_wallet_outlined, 'Account and wallet management'),
    (Icons.donut_large_rounded, 'Category reports and monthly analytics'),
    (Icons.savings_outlined, 'Budget and savings-goal monitoring'),
    (Icons.lock_outline_rounded, 'Secure PIN and biometric App Lock'),
    (Icons.contrast_rounded, 'Light and Dark Mode'),
    (Icons.sync_rounded, 'Authenticated data synchronization'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: PrototypeTopBar(
        title: 'About BudgetBee',
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final info = snapshot.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              children: [
                const BudgetBeeBrand(
                  size: BrandSize.large,
                  showSlogan: false,
                  centered: true,
                ),
                const SizedBox(height: 10),
                Text(
                  'Track. Save. Grow.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  info == null
                      ? 'Loading version…'
                      : 'Version ${info.version} (${info.buildNumber})',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                PrototypeCard(
                  child: Text(
                    'BudgetBee is a personal finance companion designed to help you record income, track expenses, manage budgets, understand spending patterns, and build healthier financial habits.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionLabel('WHAT BUDGETBEE DOES'),
                const SizedBox(height: 10),
                PrototypeCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < _features.length; i++) ...[
                        _FeatureRow(
                          icon: _features[i].$1,
                          label: _features[i].$2,
                        ),
                        if (i != _features.length - 1)
                          Divider(color: colors.outlineVariant),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionLabel('APP INFORMATION'),
                const SizedBox(height: 10),
                PrototypeCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.info_outline,
                        label: 'Version',
                        value: info?.version ?? '—',
                      ),
                      _InfoRow(
                        icon: Icons.build_outlined,
                        label: 'Build number',
                        value: info?.buildNumber ?? '—',
                      ),
                      _InfoRow(
                        icon: Icons.star_outline_rounded,
                        label: 'Rate BudgetBee',
                        onTap: () => AppActions.rateApp(context),
                      ),
                      _InfoRow(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () => AppActions.openPrivacyPolicy(context),
                      ),
                      _InfoRow(
                        icon: Icons.article_outlined,
                        label: 'Open-source licenses',
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: 'BudgetBee',
                          applicationVersion: info == null
                              ? null
                              : '${info.version} (${info.buildNumber})',
                          applicationIcon: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.savings_rounded,
                              size: 44,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      _InfoRow(
                        icon: Icons.support_agent_rounded,
                        label: 'Contact Support',
                        value: AppLinks.supportEmail.isEmpty
                            ? 'Not configured'
                            : null,
                        onTap: () => AppActions.contactSupport(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '© ${DateTime.now().year} BudgetBee. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    ),
  );
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.primary),
    title: Text(label),
    trailing: value != null
        ? Text(
            value!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        : onTap == null
        ? null
        : const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
