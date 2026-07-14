import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

class SafeAddBudgetScreen extends StatefulWidget {
  const SafeAddBudgetScreen({super.key});

  @override
  State<SafeAddBudgetScreen> createState() => _SafeAddBudgetScreenState();
}

class _SafeAddBudgetScreenState extends State<SafeAddBudgetScreen> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  int? categoryId;
  String period = 'monthly';
  int month = DateTime.now().month;
  int year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<CategoryProvider>().load(type: 'expense'),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    appBar: PrototypeTopBar(
      title: 'Set Budget',
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
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                CustomDropdown<int>(
                  value: expenseCats.any((c) => c.id == categoryId)
                      ? categoryId
                      : null,
                  label: 'Expense Category',
                  onChanged: (v) => setState(() => categoryId = v),
                  items: expenseCats
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${iconForCategory(c)} ${c.name}'),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                PrototypeInput(
                  controller: amount,
                  label: 'Budget Amount',
                  prefix: '${CurrencyFormatter.symbol()} ',
                  keyboardType: TextInputType.number,
                  validator: Validators.amount,
                ),
                const SizedBox(height: 14),
                CustomDropdown<String>(
                  value: period,
                  label: 'Period',
                  onChanged: (v) => setState(() => period = v ?? 'monthly'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Month',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.appMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(12, (i) {
                    final selected = month == i + 1;
                    return InkWell(
                      onTap: () => setState(() => month = i + 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? context.appPrimarySoft
                              : context.appCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : context.appBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : context.appMuted,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                PrototypeInput(
                  controller: TextEditingController(text: '$year'),
                  label: 'Year',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                if (budgets.error != null)
                  Text(
                    budgets.error!,
                    style: TextStyle(color: AppColors.expense),
                  ),
                PrototypeButton(
                  label: 'Save Budget',
                  onPressed: budgets.loading
                      ? null
                      : () async {
                          if (!form.currentState!.validate() ||
                              categoryId == null)
                            return;
                          await budgets.save({
                            'category_id': categoryId,
                            'amount': double.parse(amount.text),
                            'period': period,
                            'month': month,
                            'year': year,
                          });
                          if (mounted && budgets.error == null)
                            Navigator.pop(context);
                        },
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
