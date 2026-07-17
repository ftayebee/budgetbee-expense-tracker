import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/category_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

class SafeAddCategoryScreen extends StatefulWidget {
  const SafeAddCategoryScreen({super.key, this.category});

  final CategoryModel? category;

  @override
  State<SafeAddCategoryScreen> createState() => _SafeAddCategoryScreenState();
}

class _SafeAddCategoryScreenState extends State<SafeAddCategoryScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final monthlyBudget = TextEditingController();
  String selectedIcon = '🛒';
  Color selectedColor = AppColors.income;
  String type = 'expense';
  int? _budgetId;
  final icons = const [
    '🛒',
    '🚗',
    '⚡',
    '🏠',
    '🏥',
    '📺',
    '🛍',
    '📚',
    '✈️',
    '🎮',
    '💊',
    '🎁',
    '🍔',
    '☕',
  ];
  final colors = const [
    AppColors.income,
    AppColors.expense,
    AppColors.primary,
    AppColors.warning,
    AppColors.categoryPink,
    AppColors.categoryBlue,
    AppColors.categoryOrange,
    AppColors.categoryPurple,
  ];

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    if (category != null) {
      name.text = category.name;
      selectedIcon = category.icon ?? selectedIcon;
      selectedColor = _parseColor(category.color) ?? selectedColor;
      type = category.type;
    }
    Future.microtask(() async {
      await Future.wait([
        context.read<CategoryProvider>().load(),
        context.read<BudgetProvider>().load(),
      ]);
      if (!mounted || widget.category == null) return;
      final now = DateTime.now();
      final matches = context.read<BudgetProvider>().budgets.where(
        (budget) =>
            budget.category?.id == widget.category!.id &&
            budget.month == now.month &&
            budget.year == now.year,
      );
      if (matches.isNotEmpty) {
        final budget = matches.first;
        setState(() {
          _budgetId = budget.id;
          monthlyBudget.text = _formatAmount(budget.amount);
        });
      }
    });
  }

  @override
  void dispose() {
    name.dispose();
    monthlyBudget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    appBar: PrototypeTopBar(
      title: widget.category == null ? 'Add Category' : 'Edit Category',
      onBack: () => Navigator.pop(context),
    ),
    body: SafeArea(
      child: Consumer2<CategoryProvider, BudgetProvider>(
        builder: (_, state, budgets, __) => Form(
          key: form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: .12),
                    border: Border.all(color: selectedColor, width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(selectedIcon, style: TextStyle(fontSize: 40)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrototypeInput(
                controller: name,
                label: 'Category Name',
                placeholder: 'e.g. Entertainment',
                icon: Icons.sell_outlined,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              _InlineChoices(
                title: 'Choose Icon',
                children: icons
                    .map(
                      (ic) => InkWell(
                        onTap: () => setState(() => selectedIcon = ic),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selectedIcon == ic
                                ? context.appPrimarySoft
                                : context.appCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedIcon == ic
                                  ? AppColors.primary
                                  : context.appBorder,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(ic, style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _InlineChoices(
                title: 'Choose Color',
                children: colors
                    .map(
                      (c) => InkWell(
                        onTap: () => setState(() => selectedColor = c),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedColor == c
                                  ? context.appText
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              CustomDropdown<String>(
                value: type,
                label: 'Type',
                onChanged: (v) => setState(() => type = v ?? 'expense'),
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                ],
              ),
              const SizedBox(height: 16),
              if (type == 'expense') ...[
                PrototypeInput(
                  controller: monthlyBudget,
                  label: 'Monthly Budget (Optional)',
                  prefix: '${CurrencyFormatter.symbol()} ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return Validators.amount(value);
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (state.error != null)
                Text(state.error!, style: TextStyle(color: AppColors.expense)),
              if (budgets.error != null)
                Text(
                  budgets.error!,
                  style: const TextStyle(color: AppColors.expense),
                ),
              PrototypeButton(
                label: widget.category == null
                    ? 'Save Category'
                    : 'Update Category',
                onPressed: state.loading || budgets.loading
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        if (state.categories.any(
                          (c) =>
                              c.id != widget.category?.id &&
                              c.type == type &&
                              c.name.toLowerCase() ==
                                  name.text.trim().toLowerCase(),
                        ))
                          return;
                        final success = await state.save({
                          'name': name.text.trim(),
                          'type': type,
                          'icon': selectedIcon,
                          'color':
                              '#${selectedColor.toARGB32().toRadixString(16).substring(2)}',
                        }, widget.category?.id);
                        if (!mounted || !success) return;
                        final saved = state.lastSaved;
                        if (type == 'expense' &&
                            saved != null &&
                            monthlyBudget.text.trim().isNotEmpty) {
                          final now = DateTime.now();
                          final budgetSaved = await budgets.save({
                            'name': '${name.text.trim()} Budget',
                            'category_id': saved.id,
                            'amount': double.parse(monthlyBudget.text.trim()),
                            'period': 'monthly',
                            'start_date': DateFormatter.api(
                              DateTime(now.year, now.month),
                            ),
                            'end_date': null,
                            'alert_threshold': 80,
                            'month': now.month,
                            'year': now.year,
                          }, _budgetId);
                          if (!mounted || !budgetSaved) return;
                        }
                        Navigator.pop(context, true);
                      },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatAmount(double value) => value == value.truncateToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

Color? _parseColor(String? value) {
  final hex = value?.replaceFirst('#', '');
  if (hex == null || hex.length != 6) return null;
  final parsed = int.tryParse('FF$hex', radix: 16);
  return parsed == null ? null : Color(parsed);
}

class _InlineChoices extends StatelessWidget {
  const _InlineChoices({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.appMuted,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: children),
    ],
  );
}
