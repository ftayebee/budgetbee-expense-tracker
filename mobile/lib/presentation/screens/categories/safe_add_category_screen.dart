import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

class SafeAddCategoryScreen extends StatefulWidget {
  const SafeAddCategoryScreen({super.key});

  @override
  State<SafeAddCategoryScreen> createState() => _SafeAddCategoryScreenState();
}

class _SafeAddCategoryScreenState extends State<SafeAddCategoryScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  String selectedIcon = '🛒';
  Color selectedColor = AppColors.income;
  String type = 'expense';
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
    Future.microtask(() => context.read<CategoryProvider>().load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    appBar: PrototypeTopBar(
      title: 'Add Category',
      onBack: () => Navigator.pop(context),
    ),
    body: SafeArea(
      child: Consumer<CategoryProvider>(
        builder: (_, state, __) => Form(
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
              if (state.error != null)
                Text(state.error!, style: TextStyle(color: AppColors.expense)),
              PrototypeButton(
                label: 'Save Category',
                onPressed: state.loading
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        if (state.categories.any(
                          (c) =>
                              c.type == type &&
                              c.name.toLowerCase() ==
                                  name.text.trim().toLowerCase(),
                        ))
                          return;
                        await state.save({
                          'name': name.text.trim(),
                          'type': type,
                          'icon': selectedIcon,
                          'color':
                              '#${selectedColor.toARGB32().toRadixString(16).substring(2)}',
                        });
                        if (mounted && state.error == null)
                          Navigator.pop(context);
                      },
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
