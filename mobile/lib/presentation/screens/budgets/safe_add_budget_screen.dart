import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/budget_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

class SafeAddBudgetScreen extends StatefulWidget {
  const SafeAddBudgetScreen({super.key, this.budget});

  final BudgetModel? budget;

  @override
  State<SafeAddBudgetScreen> createState() => _SafeAddBudgetScreenState();
}

class _SafeAddBudgetScreenState extends State<SafeAddBudgetScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final amount = TextEditingController();
  final threshold = TextEditingController(text: '80');
  int? categoryId;
  String period = 'monthly';
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  String? selectionError;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    if (budget != null) {
      name.text = budget.name;
      amount.text = budget.amount.toStringAsFixed(2);
      threshold.text = '${budget.alertThreshold}';
      categoryId = budget.category?.id;
      period = budget.period;
      startDate = budget.startDate ?? DateTime(budget.year, budget.month);
      endDate = budget.endDate;
    }
    Future.microtask(
      () => context.read<CategoryProvider>().load(type: 'expense'),
    );
  }

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    appBar: PrototypeTopBar(
      title: widget.budget == null ? 'Add Budget' : 'Edit Budget',
      onBack: () => Navigator.pop(context),
    ),
    body: SafeArea(
      child: Consumer2<CategoryProvider, BudgetProvider>(
        builder: (_, cats, budgets, __) {
          final expenseCats = cats.byType('expense');
          return Form(
            key: form,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              children: [
                PrototypeInput(
                  controller: name,
                  label: 'Budget Name',
                  placeholder: 'e.g. Monthly groceries',
                  validator: Validators.required,
                ),
                const SizedBox(height: 14),
                CustomDropdown<int>(
                  value: expenseCats.any((c) => c.id == categoryId)
                      ? categoryId
                      : null,
                  label: 'Expense Category',
                  onChanged: (value) => setState(() => categoryId = value),
                  items: expenseCats
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            '${iconForCategory(category)} ${category.name}',
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                PrototypeInput(
                  controller: amount,
                  label: 'Budget Amount',
                  prefix: '${CurrencyFormatter.symbol()} ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.amount,
                ),
                const SizedBox(height: 14),
                CustomDropdown<String>(
                  value: period,
                  label: 'Period',
                  onChanged: (value) =>
                      setState(() => period = value ?? 'monthly'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                ),
                const SizedBox(height: 14),
                _DateField(
                  label: 'Start Date',
                  value: startDate,
                  onTap: () => _pickDate(isEnd: false),
                ),
                const SizedBox(height: 14),
                _DateField(
                  label: 'End Date (Optional)',
                  value: endDate,
                  allowClear: true,
                  onTap: () => _pickDate(isEnd: true),
                  onClear: () => setState(() => endDate = null),
                ),
                const SizedBox(height: 14),
                PrototypeInput(
                  controller: threshold,
                  label: 'Alert Threshold (%)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 1 || parsed > 100) {
                      return 'Enter a threshold from 1 to 100.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                if (selectionError != null)
                  Text(
                    selectionError!,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                if (budgets.error != null)
                  Text(
                    budgets.error!,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                const SizedBox(height: 6),
                PrototypeButton(
                  label: budgets.loading
                      ? 'Saving…'
                      : widget.budget == null
                      ? 'Add Budget'
                      : 'Update Budget',
                  onPressed: budgets.loading ? null : _save,
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Future<void> _pickDate({required bool isEnd}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: isEnd ? (endDate ?? startDate) : startDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isEnd) {
        endDate = picked;
      } else {
        startDate = picked;
        if (endDate != null && endDate!.isBefore(picked)) endDate = null;
      }
    });
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    if (categoryId == null) {
      setState(() => selectionError = 'Choose an expense category.');
      return;
    }
    setState(() => selectionError = null);
    final provider = context.read<BudgetProvider>();
    final success = await provider.save({
      'name': name.text.trim(),
      'category_id': categoryId,
      'amount': double.parse(amount.text),
      'period': period,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': endDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(endDate!),
      'alert_threshold': int.parse(threshold.text),
      'month': startDate.month,
      'year': startDate.year,
    }, widget.budget?.id);
    if (!mounted || !success) return;
    await Future.wait([
      context.read<ReportProvider>().load(),
      context.read<DashboardProvider>().load(),
    ]);
    if (mounted) Navigator.pop(context, true);
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.allowClear = false,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool allowClear;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: allowClear && value != null
            ? IconButton(onPressed: onClear, icon: const Icon(Icons.close))
            : const Icon(Icons.calendar_month_outlined),
      ),
      child: Text(
        value == null ? 'No end date' : DateFormat('d MMM yyyy').format(value!),
      ),
    ),
  );
}
