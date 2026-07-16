import 'package:flutter/material.dart';

import '../../../core/config/app_links.dart';
import '../../widgets/app_widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'Information collected',
      'BudgetBee stores the profile, account, category, budget, and transaction information you provide so the app can deliver its finance features.',
    ),
    (
      'How data is used',
      'Your data is used to authenticate your account, calculate balances and reports, synchronize your devices, and operate the features you choose to use.',
    ),
    (
      'Account and transaction data',
      'Financial entries may include amounts, dates, notes, categories, payment methods, and the accounts you associate with them.',
    ),
    (
      'Local storage',
      'Theme, currency, onboarding, and App Lock preferences are stored on your device. Authentication credentials and PIN verification material use protected device storage where supported.',
    ),
    (
      'API and server communication',
      'Signed-in features communicate with the BudgetBee Laravel API over the network. Avoid entering secrets or unnecessary personal information in transaction notes.',
    ),
    (
      'Authentication and biometrics',
      'Authentication tokens are used to maintain your session. Biometric checks are performed by your operating system; BudgetBee does not receive your fingerprint or face data.',
    ),
    (
      'Data retention and deletion',
      'Data may remain associated with your account until you delete individual records or request account-data deletion through the configured support channel. Backup retention can differ from active data.',
    ),
    (
      'Third-party services',
      'BudgetBee relies on platform and infrastructure services needed for authentication, secure storage, networking, diagnostics, and app distribution. Their handling is governed by their own policies.',
    ),
    (
      'Children’s privacy',
      'BudgetBee is a general personal-finance tool and is not intentionally designed to collect data from children. Local age and consent requirements may apply.',
    ),
    (
      'Security limitations',
      'Reasonable safeguards reduce risk, but no device, network, or storage system can be guaranteed completely secure. Keep your device and account credentials protected.',
    ),
    (
      'Policy updates',
      'This notice may be updated as BudgetBee changes. Material updates should be published with the application or on the configured policy page.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PrototypeTopBar(
      title: 'Privacy Policy',
      onBack: () => Navigator.pop(context),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'This in-app notice explains BudgetBee’s current data handling in plain language. It is not a substitute for any published policy that may apply to a production service.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 18),
          for (final section in _sections) ...[
            Text(
              section.$1,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              section.$2,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            AppLinks.supportEmail.isEmpty
                ? 'Contact information will appear here when a production support address is configured.'
                : 'Questions or deletion requests: ${AppLinks.supportEmail}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
