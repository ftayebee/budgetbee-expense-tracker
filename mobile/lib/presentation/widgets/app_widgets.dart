import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../routes/app_routes.dart';

class PrototypeCard extends StatelessWidget {
  const PrototypeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.gradient,
    this.color = AppColors.card,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
    return onTap == null
        ? body
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: body,
          );
  }
}

class PrototypeButton extends StatelessWidget {
  const PrototypeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.fullWidth = true,
    this.icon,
    this.height = 50,
  });
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool fullWidth;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = switch (variant) {
      ButtonVariant.primary => (AppColors.primary, Colors.white, null),
      ButtonVariant.secondary => (
        AppColors.primarySoft,
        AppColors.primary,
        null,
      ),
      ButtonVariant.ghost => (Colors.transparent, AppColors.primary, null),
      ButtonVariant.income => (AppColors.income, Colors.white, null),
      ButtonVariant.expense => (AppColors.expense, Colors.white, null),
      ButtonVariant.outline => (
        Colors.transparent,
        AppColors.primary,
        AppColors.primary,
      ),
    };
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: colors.$1,
          foregroundColor: colors.$2,
          disabledForegroundColor: colors.$2.withValues(alpha: .5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: colors.$3 == null
                ? BorderSide.none
                : BorderSide(color: colors.$3!, width: 1.5),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: child,
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, ghost, income, expense, outline }

class PrototypeInput extends StatelessWidget {
  const PrototypeInput({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.icon,
    this.prefix,
    this.readOnly = false,
    this.onTap,
  });
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscureText;
  final IconData? icon;
  final String? prefix;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 15, color: AppColors.text),
        decoration: InputDecoration(
          hintText: placeholder,
          prefixIcon: icon == null
              ? null
              : Icon(icon, size: 18, color: AppColors.muted),
          prefixText: prefix,
        ),
      ),
    ],
  );
}

class PrototypeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const PrototypeTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.right,
  });
  final String title;
  final VoidCallback? onBack;
  final Widget? right;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    decoration: const BoxDecoration(
      color: AppColors.card,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          child: onBack == null
              ? null
              : IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 22),
                ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        SizedBox(width: 36, child: right),
      ],
    ),
  );
}

class PrototypeTag extends StatelessWidget {
  const PrototypeTag({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class PrototypeBottomNav extends StatelessWidget {
  const PrototypeBottomNav({super.key, required this.active});
  final String active;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppRoutes.dashboard, Icons.home_rounded, 'Home'),
      (AppRoutes.transactions, Icons.swap_vert_rounded, 'Transactions'),
      (AppRoutes.addTransaction, Icons.add, 'Add'),
      (AppRoutes.reports, Icons.pie_chart_rounded, 'Reports'),
      (AppRoutes.settings, Icons.settings_rounded, 'Settings'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: items.map((item) {
          final isFab = item.$1 == AppRoutes.addTransaction;
          final isActive = active == item.$1;
          return Expanded(
            child: InkWell(
              onTap: () => isFab
                  ? Navigator.pushNamed(context, item.$1)
                  : Navigator.pushReplacementNamed(context, item.$1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFab)
                    Transform.translate(
                      offset: const Offset(0, -18),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: .45),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    )
                  else
                    Icon(
                      item.$2,
                      size: 22,
                      color: isActive
                          ? AppColors.text
                          : AppColors.text.withValues(alpha: .4),
                    ),
                  if (!isFab) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.primary : AppColors.faint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PrototypeTransactionCard extends StatelessWidget {
  const PrototypeTransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });
  final TransactionModel transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final subtitle = isTransfer
        ? "${transaction.fromAccount?.name ?? 'Account'} -> ${transaction.toAccount?.name ?? 'Account'} - ${DateFormatter.display(transaction.transactionDate)}"
        : "${transaction.category?.name ?? transaction.type} - ${DateFormatter.display(transaction.transactionDate)}";
    return PrototypeCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isTransfer
                  ? AppColors.primarySoft
                  : (isIncome ? AppColors.incomeSoft : AppColors.expenseSoft),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                iconForTransaction(transaction),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            isTransfer
                ? CurrencyFormatter.format(transaction.amount)
                : '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isTransfer
                  ? AppColors.primary
                  : (isIncome ? AppColors.income : AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}

class PrototypeEmptyState extends StatelessWidget {
  const PrototypeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });
  final String icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.muted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: 200,
              child: PrototypeButton(label: actionLabel!, onPressed: onAction),
            ),
          ],
        ],
      ),
    ),
  );
}

class PrototypeSectionLabel extends StatelessWidget {
  const PrototypeSectionLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.faint,
        letterSpacing: .8,
      ),
    ),
  );
}

class AppButton extends PrototypeButton {
  const AppButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    Color background = AppColors.primary,
  });
}

class CustomTextField extends PrototypeInput {
  const CustomTextField({
    super.key,
    required super.controller,
    required super.label,
    super.validator,
    super.keyboardType,
    super.maxLines,
    super.obscureText,
  });
}

class CustomDropdown<T> extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String label;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(height: 6),
      DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: const InputDecoration(),
        validator: (v) => v == null ? 'Required' : null,
      ),
    ],
  );
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  );
}

class EmptyState extends PrototypeEmptyState {
  const EmptyState(String message, {super.key})
    : super(
        icon: '🔍',
        title: message,
        subtitle: 'Try refreshing or changing your filters.',
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => PrototypeEmptyState(
    icon: '⚠️',
    title: 'Something went wrong',
    subtitle: message,
  );
}

class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account});
  final AccountModel account;
  @override
  Widget build(BuildContext context) => PrototypeCard(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                account.type.replaceAll('_', ' '),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.format(account.currentBalance),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    ),
  );
}

class CategoryChipTile extends StatelessWidget {
  const CategoryChipTile({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });
  final CategoryModel category;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(category);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .12) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(iconForCategory(category)),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? color : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      const Spacer(),
      if (action != null) action!,
    ],
  );
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });
  final double balance, income, expense;
  @override
  Widget build(BuildContext context) => PrototypeCard(
    gradient: const LinearGradient(
      colors: [AppColors.primary, AppColors.primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Budget',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(balance),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => PrototypeCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.format(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class TransactionTile extends PrototypeTransactionCard {
  const TransactionTile({super.key, required super.transaction, super.onTap});
}

String iconForTransaction(TransactionModel tx) => tx.type == 'transfer'
    ? '↔'
    : iconForName(tx.category?.name ?? tx.title, tx.type);

String iconForCategory(CategoryModel category) =>
    iconForName(category.name, category.type);

String iconForName(String name, [String type = 'expense']) {
  final key = name.toLowerCase();
  if (key.contains('salary')) return '💰';
  if (key.contains('freelance') || key.contains('business')) return '💼';
  if (key.contains('food') || key.contains('grocery')) return '🛒';
  if (key.contains('transport')) return '🚗';
  if (key.contains('bill') || key.contains('utilit')) return '⚡';
  if (key.contains('rent') || key.contains('housing')) return '🏠';
  if (key.contains('health')) return '🏥';
  if (key.contains('entertain') || key.contains('movie')) return '📺';
  if (key.contains('fuel')) return '⛽';
  if (key.contains('shopping')) return '🛍';
  if (key.contains('education')) return '📚';
  return type == 'income' ? '💵' : '🏷';
}

Color colorForCategory(CategoryModel category) {
  final key = category.name.toLowerCase();
  if (category.type == 'income') return AppColors.income;
  if (key.contains('food')) return AppColors.categoryOrange;
  if (key.contains('transport')) return AppColors.categoryBlue;
  if (key.contains('rent') || key.contains('housing')) {
    return AppColors.categoryPurple;
  }
  if (key.contains('health')) return AppColors.expense;
  if (key.contains('entertain')) return AppColors.categoryPink;
  return AppColors.primary;
}
