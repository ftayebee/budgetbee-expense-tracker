import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

class CompactAddTransactionScreen extends StatefulWidget {
  const CompactAddTransactionScreen({
    super.key,
    this.transaction,
    this.initialDate,
  });
  final TransactionModel? transaction;
  final DateTime? initialDate;

  @override
  State<CompactAddTransactionScreen> createState() =>
      _CompactAddTransactionScreenState();
}

class _CompactAddTransactionScreenState
    extends State<CompactAddTransactionScreen> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  String type = 'expense';
  int? accountId;
  int? categoryId;
  int? fromAccountId;
  int? toAccountId;
  DateTime date = DateTime.now();
  String? selectionError;
  bool _submitting = false;
  bool _routeArgumentsApplied = false;

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      amount.text = _formatAmount(tx.amount);
      note.text = tx.note ?? '';
      type = tx.type;
      accountId = tx.account?.id;
      categoryId = tx.category?.id;
      fromAccountId = tx.fromAccount?.id;
      toAccountId = tx.toAccount?.id;
      date = tx.transactionDate;
    } else if (widget.initialDate != null) {
      date = widget.initialDate!;
    }
    Future.microtask(() async {
      await context.read<AccountProvider>().load();
      await context.read<CategoryProvider>().load();
    });
  }

  String _formatAmount(double value) {
    if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgumentsApplied || widget.transaction != null) return;
    _routeArgumentsApplied = true;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is String &&
        const {'income', 'expense', 'transfer'}.contains(argument)) {
      type = argument;
    }
  }

  void _changeType(String nextType) {
    if (nextType == type) return;
    setState(() {
      type = nextType;
      accountId = null;
      categoryId = null;
      fromAccountId = null;
      toAccountId = null;
      selectionError = null;
      form.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PrototypeTopBar(
        title: widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction',
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Consumer3<AccountProvider, CategoryProvider, TransactionProvider>(
          builder: (_, accounts, categories, txState, __) {
            final cats = categories.byType(type);
            final selectedCategory = cats.any((c) => c.id == categoryId)
                ? categoryId
                : null;
            final selectedAccount =
                accounts.accounts.any((a) => a.id == accountId)
                ? accountId
                : null;
            final selectedFrom =
                accounts.accounts.any((a) => a.id == fromAccountId)
                ? fromAccountId
                : null;
            final selectedTo = accounts.accounts.any((a) => a.id == toAccountId)
                ? toAccountId
                : null;
            return Form(
              key: form,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CompactTypeToggle(type: type, onChanged: _changeType),
                    const SizedBox(height: 12),
                    PrototypeInput(
                      controller: amount,
                      label: 'Amount',
                      prefix: '${CurrencyFormatter.symbol()} ',
                      keyboardType: TextInputType.number,
                      validator: Validators.amount,
                    ),
                    const SizedBox(height: 10),
                    if (type == 'transfer') ...[
                      CustomDropdown<int>(
                        value: selectedFrom,
                        label: 'From Account',
                        onChanged: (v) => setState(() => fromAccountId = v),
                        items: accounts.accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      CustomDropdown<int>(
                        value: selectedTo,
                        label: 'To Account',
                        onChanged: (v) => setState(() => toAccountId = v),
                        items: accounts.accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                      ),
                    ] else ...[
                      CustomDropdown<int>(
                        value: selectedCategory,
                        label: 'Category',
                        onChanged: (v) => setState(() => categoryId = v),
                        items: cats
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('${iconForCategory(c)} ${c.name}'),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      CustomDropdown<int>(
                        value: selectedAccount,
                        label: 'Account',
                        onChanged: (v) => setState(() => accountId = v),
                        items: accounts.accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    PrototypeInput(
                      controller: TextEditingController(
                        text: DateFormatter.api(date),
                      ),
                      label: 'Date',
                      icon: Icons.calendar_month,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: date,
                        );
                        if (picked != null) setState(() => date = picked);
                      },
                    ),
                    const SizedBox(height: 10),
                    PrototypeInput(
                      controller: note,
                      label: 'Note',
                      placeholder: 'Optional note',
                      icon: Icons.notes,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    if (txState.error != null)
                      Text(
                        txState.error!,
                        style: TextStyle(color: AppColors.expense),
                      ),
                    if (selectionError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          selectionError!,
                          style: const TextStyle(color: AppColors.expense),
                        ),
                      ),
                    PrototypeButton(
                      label: _submitting
                          ? widget.transaction != null
                                ? 'Updating…'
                                : 'Saving…'
                          : widget.transaction != null
                          ? 'Update Transaction'
                          : type == 'transfer'
                          ? 'Save Transfer'
                          : 'Save Transaction',
                      variant: type == 'income'
                          ? ButtonVariant.income
                          : type == 'expense'
                          ? ButtonVariant.expense
                          : ButtonVariant.primary,
                      onPressed:
                          txState.loading ||
                              (widget.transaction != null && _submitting)
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              setState(() => selectionError = null);
                              final value = double.parse(amount.text);
                              Map<String, dynamic> data;
                              if (type == 'transfer') {
                                if (fromAccountId == null ||
                                    toAccountId == null ||
                                    fromAccountId == toAccountId) {
                                  setState(
                                    () => selectionError =
                                        'Choose two different accounts for the transfer.',
                                  );
                                  return;
                                }
                                data = {
                                  'title':
                                      widget.transaction?.title ?? 'Transfer',
                                  'amount': value,
                                  'type': type,
                                  'from_account_id': fromAccountId,
                                  'to_account_id': toAccountId,
                                  'transaction_date': DateFormatter.api(date),
                                  'note': note.text,
                                };
                              } else {
                                if (accountId == null || categoryId == null) {
                                  setState(
                                    () => selectionError =
                                        'Choose an account and category.',
                                  );
                                  return;
                                }
                                final category = cats.firstWhere(
                                  (c) => c.id == categoryId,
                                );
                                data = {
                                  'title':
                                      widget.transaction?.title ??
                                      category.name,
                                  'amount': value,
                                  'type': type,
                                  'account_id': accountId,
                                  'category_id': categoryId,
                                  'transaction_date': DateFormatter.api(date),
                                  'payment_method':
                                      widget.transaction?.paymentMethod ??
                                      'Account',
                                  'note': note.text,
                                };
                              }
                              if (widget.transaction != null) {
                                setState(() => _submitting = true);
                              }
                              final success = await txState.save(
                                data,
                                widget.transaction?.id,
                              );
                              if (!mounted) return;
                              if (!success) {
                                if (widget.transaction != null) {
                                  setState(() => _submitting = false);
                                }
                                return;
                              }
                              await Future.wait([
                                context.read<DashboardProvider>().load(),
                                context.read<AccountProvider>().load(),
                                context.read<BudgetProvider>().load(),
                                context.read<ReportProvider>().load(),
                              ]);
                              if (mounted) Navigator.pop(context, true);
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompactTypeToggle extends StatelessWidget {
  const _CompactTypeToggle({required this.type, required this.onChanged});
  final String type;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.appBorder,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: ['expense', 'income', 'transfer'].map((t) {
        final selected = type == t;
        final selectedColor = t == 'income'
            ? AppColors.income
            : t == 'expense'
            ? AppColors.expense
            : AppColors.primary;
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(t),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: selected && t == 'income' ? selectedColor : null,
                gradient: selected && t != 'income'
                    ? AppColors.deepGradient
                    : null,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                t == 'income'
                    ? 'Income'
                    : t == 'expense'
                    ? 'Expense'
                    : 'Transfer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : context.appMuted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
