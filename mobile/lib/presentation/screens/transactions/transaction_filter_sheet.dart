import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/category_model.dart';
import '../../widgets/app_widgets.dart';

enum TransactionDatePreset {
  any,
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  custom,
}

class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.datePreset = TransactionDatePreset.any,
    this.from,
    this.to,
    this.accountId,
    this.categoryId,
    this.minimumAmount,
    this.maximumAmount,
    this.sort = 'date_desc',
  });

  final String? type;
  final TransactionDatePreset datePreset;
  final DateTime? from;
  final DateTime? to;
  final int? accountId;
  final int? categoryId;
  final double? minimumAmount;
  final double? maximumAmount;
  final String sort;

  bool get isActive =>
      type != null ||
      datePreset != TransactionDatePreset.any ||
      accountId != null ||
      categoryId != null ||
      minimumAmount != null ||
      maximumAmount != null ||
      sort != 'date_desc';

  int get activeCount => [
    type,
    datePreset == TransactionDatePreset.any ? null : datePreset,
    accountId,
    categoryId,
    minimumAmount != null || maximumAmount != null ? true : null,
    sort == 'date_desc' ? null : sort,
  ].where((value) => value != null).length;

  Map<String, dynamic> toQuery({String? search}) => {
    'search': search,
    'type': type,
    'from': from == null ? null : DateFormat('yyyy-MM-dd').format(from!),
    'to': to == null ? null : DateFormat('yyyy-MM-dd').format(to!),
    'account_id': accountId,
    'category_id': categoryId,
    'min_amount': minimumAmount,
    'max_amount': maximumAmount,
    'sort': sort,
  };

  factory TransactionFilter.fromQuery(Map<String, dynamic> query) {
    final from = DateTime.tryParse('${query['from'] ?? ''}');
    final to = DateTime.tryParse('${query['to'] ?? ''}');
    return TransactionFilter(
      type: query['type']?.toString(),
      datePreset: from == null && to == null
          ? TransactionDatePreset.any
          : TransactionDatePreset.custom,
      from: from,
      to: to,
      accountId: int.tryParse('${query['account_id'] ?? ''}'),
      categoryId: int.tryParse('${query['category_id'] ?? ''}'),
      minimumAmount: double.tryParse('${query['min_amount'] ?? ''}'),
      maximumAmount: double.tryParse('${query['max_amount'] ?? ''}'),
      sort: query['sort']?.toString() ?? 'date_desc',
    );
  }
}

class TransactionFilterSheet extends StatefulWidget {
  const TransactionFilterSheet({
    super.key,
    required this.initial,
    required this.accounts,
    required this.categories,
  });

  final TransactionFilter initial;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late String? type = widget.initial.type;
  late TransactionDatePreset preset = widget.initial.datePreset;
  late DateTime? from = widget.initial.from;
  late DateTime? to = widget.initial.to;
  late int? accountId = widget.initial.accountId;
  late int? categoryId = widget.initial.categoryId;
  late String sort = widget.initial.sort;
  late final minimum = TextEditingController(
    text: widget.initial.minimumAmount?.toString() ?? '',
  );
  late final maximum = TextEditingController(
    text: widget.initial.maximumAmount?.toString() ?? '',
  );
  String? amountError;

  @override
  void dispose() {
    minimum.dispose();
    maximum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter transactions',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const TransactionFilter()),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _dropdown<String?>(
              label: 'Transaction type',
              value: type,
              items: const {
                null: 'All',
                'income': 'Income',
                'expense': 'Expense',
                'transfer': 'Transfer',
              },
              onChanged: (value) => setState(() {
                type = value;
                if (categoryId != null &&
                    !widget.categories.any(
                      (category) =>
                          category.id == categoryId &&
                          (value == null || category.type == value),
                    )) {
                  categoryId = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            _dropdown<TransactionDatePreset>(
              label: 'Date',
              value: preset,
              items: const {
                TransactionDatePreset.any: 'Any date',
                TransactionDatePreset.today: 'Today',
                TransactionDatePreset.thisWeek: 'This week',
                TransactionDatePreset.thisMonth: 'This month',
                TransactionDatePreset.lastMonth: 'Last month',
                TransactionDatePreset.custom: 'Custom date range',
              },
              onChanged: _changePreset,
            ),
            if (from != null && to != null) ...[
              const SizedBox(height: 6),
              Text(
                '${DateFormat('d MMM yyyy').format(from!)} – ${DateFormat('d MMM yyyy').format(to!)}',
                style: TextStyle(fontSize: 12, color: context.appMuted),
              ),
            ],
            const SizedBox(height: 12),
            _dropdown<int?>(
              label: 'Account or wallet',
              value: accountId,
              items: {
                null: 'All accounts',
                for (final account in widget.accounts) account.id: account.name,
              },
              onChanged: (value) => setState(() => accountId = value),
            ),
            const SizedBox(height: 12),
            _dropdown<int?>(
              label: 'Category',
              value: categoryId,
              items: {
                null: 'All categories',
                for (final category in widget.categories.where(
                  (category) => type == null || category.type == type,
                ))
                  category.id: category.name,
              },
              onChanged: (value) => setState(() => categoryId = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minimum,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Minimum'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: maximum,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Maximum'),
                  ),
                ),
              ],
            ),
            if (amountError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  amountError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Sort by',
              value: sort,
              items: const {
                'date_desc': 'Newest first',
                'date_asc': 'Oldest first',
                'amount_desc': 'Highest amount',
                'amount_asc': 'Lowest amount',
              },
              onChanged: (value) => setState(() => sort = value ?? 'date_desc'),
            ),
            const SizedBox(height: 18),
            PrototypeButton(label: 'Apply Filter', onPressed: _apply),
          ],
        ),
      ),
    ),
  );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: items.entries
        .map(
          (entry) =>
              DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
        )
        .toList(),
    onChanged: onChanged,
  );

  Future<void> _changePreset(TransactionDatePreset? value) async {
    if (value == null) return;
    if (value == TransactionDatePreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: from != null && to != null
            ? DateTimeRange(start: from!, end: to!)
            : null,
      );
      if (picked == null || !mounted) return;
      setState(() {
        preset = value;
        from = picked.start;
        to = picked.end;
      });
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = switch (value) {
      TransactionDatePreset.any => null,
      TransactionDatePreset.today => DateTimeRange(start: today, end: today),
      TransactionDatePreset.thisWeek => DateTimeRange(
        start: today.subtract(Duration(days: today.weekday - 1)),
        end: today,
      ),
      TransactionDatePreset.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      TransactionDatePreset.lastMonth => DateTimeRange(
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month, 0),
      ),
      TransactionDatePreset.custom => null,
    };
    setState(() {
      preset = value;
      from = range?.start;
      to = range?.end;
    });
  }

  void _apply() {
    final min = minimum.text.trim().isEmpty
        ? null
        : double.tryParse(minimum.text.trim());
    final max = maximum.text.trim().isEmpty
        ? null
        : double.tryParse(maximum.text.trim());
    if ((minimum.text.isNotEmpty && min == null) ||
        (maximum.text.isNotEmpty && max == null) ||
        (min != null && min < 0) ||
        (max != null && max < 0) ||
        (min != null && max != null && min > max)) {
      setState(() => amountError = 'Enter a valid amount range.');
      return;
    }
    Navigator.pop(
      context,
      TransactionFilter(
        type: type,
        datePreset: preset,
        from: from,
        to: to,
        accountId: accountId,
        categoryId: categoryId,
        minimumAmount: min,
        maximumAmount: max,
        sort: sort,
      ),
    );
  }
}
