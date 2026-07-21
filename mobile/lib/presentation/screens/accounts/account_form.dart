import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/account_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

class AccountFormModel {
  const AccountFormModel({
    required this.name,
    required this.type,
    required this.openingBalance,
  });

  final String name;
  final String type;
  final double openingBalance;

  Map<String, dynamic> toRequestPayload() => {
    'name': name.trim(),
    'type': type,
    'opening_balance': openingBalance,
  };
}

class AccountForm extends StatefulWidget {
  const AccountForm({super.key, required this.onSaved, this.onCancel});

  final ValueChanged<AccountModel> onSaved;
  final VoidCallback? onCancel;

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  String _type = 'cash';
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save(AccountProvider provider) async {
    if (_submitting || provider.loading) return;
    provider.clearErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final model = AccountFormModel(
      name: _nameController.text,
      type: _type,
      openingBalance: double.parse(_balanceController.text),
    );
    final success = await provider.save(model.toRequestPayload());
    if (!mounted) return;
    if (!success || provider.lastSaved == null) {
      setState(() => _submitting = false);
      _formKey.currentState?.validate();
      return;
    }
    widget.onSaved(provider.lastSaved!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, provider, _) => Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrototypeInput(
              key: const ValueKey('account-name-field'),
              controller: _nameController,
              label: 'Account Name',
              placeholder: 'Cash Wallet',
              icon: Icons.account_balance_wallet_outlined,
              validator: (value) =>
                  provider.fieldError('name') ?? Validators.required(value),
              onChanged: (_) => _clearServerErrors(provider),
            ),
            const SizedBox(height: 14),
            CustomDropdown<String>(
              value: _type,
              label: 'Account Type',
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
              items:
                  const {
                        'cash': 'Cash',
                        'bank': 'Bank',
                        'mobile_banking': 'Mobile banking',
                        'card': 'Card',
                        'other': 'Other',
                      }.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 14),
            PrototypeInput(
              key: const ValueKey('account-balance-field'),
              controller: _balanceController,
              label: 'Opening Balance',
              prefix: '${CurrencyFormatter.symbol()} ',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  provider.fieldError('opening_balance') ??
                  Validators.amount(value),
              onChanged: (_) => _clearServerErrors(provider),
            ),
            if (provider.error != null && provider.fieldErrors.isEmpty) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: AppColors.expense),
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (widget.onCancel != null)
              Row(
                children: [
                  Expanded(
                    child: PrototypeButton(
                      label: 'Cancel',
                      variant: ButtonVariant.outline,
                      onPressed: _submitting ? null : widget.onCancel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _saveButton(provider)),
                ],
              )
            else
              _saveButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _saveButton(AccountProvider provider) => PrototypeButton(
    label: _submitting ? 'Saving…' : 'Save Account',
    onPressed: _submitting || provider.loading ? null : () => _save(provider),
  );

  void _clearServerErrors(AccountProvider provider) {
    if (provider.fieldErrors.isNotEmpty) provider.clearErrors();
  }
}

class QuickAddAccountSheet extends StatelessWidget {
  const QuickAddAccountSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add account',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Create an account without losing this transaction.',
              style: TextStyle(color: context.appMuted),
            ),
            const SizedBox(height: 18),
            AccountForm(
              onCancel: () => Navigator.pop(context),
              onSaved: (account) => Navigator.pop(context, account),
            ),
          ],
        ),
      ),
    );
  }
}
