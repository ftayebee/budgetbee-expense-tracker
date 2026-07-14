import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../presentation/screens/transactions/compact_add_transaction_screen.dart';
import '../../../presentation/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';
import '../domain/analytics_models.dart';
import 'analytics_controller.dart';

class PremiumAnalyticsScreen extends StatefulWidget {
  const PremiumAnalyticsScreen({super.key});

  @override
  State<PremiumAnalyticsScreen> createState() => _PremiumAnalyticsScreenState();
}

class _PremiumAnalyticsScreenState extends State<PremiumAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 6, vsync: this);
    Future.microtask(() => context.read<AnalyticsController>().load());
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const PrototypeBottomNav(active: AppRoutes.reports),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          _AnalyticsHeader(controller: tabs),
          Expanded(
            child: Consumer<AnalyticsController>(
              builder: (context, controller, _) {
                final snapshot = controller.snapshot;
                if (controller.loading && snapshot == null) {
                  return const _AnalyticsSkeleton();
                }
                if (controller.error != null && snapshot == null) {
                  return ErrorState(controller.error!);
                }
                if (snapshot == null) return const _AnalyticsSkeleton();
                return TabBarView(
                  controller: tabs,
                  children: [
                    _OverviewTab(snapshot: snapshot),
                    _CalendarTab(snapshot: snapshot),
                    _CategoriesTab(snapshot: snapshot),
                    _CashFlowTab(snapshot: snapshot),
                    _BudgetTab(snapshot: snapshot),
                    _InsightsTab(
                      snapshot: snapshot,
                      onAction: _handleInsightAction,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  void _handleInsightAction(String? label) {
    if (label == null) return;
    if (label.contains('category')) tabs.animateTo(2);
    if (label.contains('budget')) tabs.animateTo(4);
    if (label.contains('comparison')) tabs.animateTo(0);
    if (label.contains('day')) tabs.animateTo(1);
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appCard,
      border: Border(bottom: BorderSide(color: context.appBorder)),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Analytics',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Refresh analytics',
                onPressed: context.read<AnalyticsController>().refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        const AnalyticsFilterBar(),
        TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Calendar'),
            Tab(text: 'Categories'),
            Tab(text: 'Cash Flow'),
            Tab(text: 'Budget'),
            Tab(text: 'Insights'),
          ],
        ),
      ],
    ),
  );
}

class AnalyticsFilterBar extends StatelessWidget {
  const AnalyticsFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AnalyticsController>();
    final filter = controller.filter;
    return SizedBox(
      height: 43,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            icon: Icons.date_range_rounded,
            label: _rangeLabel(filter),
            onTap: () => _chooseRange(context),
          ),
          _FilterChip(
            icon: Icons.tune_rounded,
            label: _activeFilterLabel(filter),
            onTap: () => _showDetailedFilters(context),
          ),
          if (filter.type != null ||
              filter.accountId != null ||
              filter.categoryId != null ||
              filter.paymentMethod != null)
            _FilterChip(
              icon: Icons.filter_alt_off_rounded,
              label: 'Clear',
              onTap: () => controller.load(
                filter: filter.copyWith(
                  clearType: true,
                  clearAccount: true,
                  clearCategory: true,
                  clearPaymentMethod: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _rangeLabel(AnalyticsFilter filter) => switch (filter.preset) {
    AnalyticsRangePreset.today => 'Today',
    AnalyticsRangePreset.yesterday => 'Yesterday',
    AnalyticsRangePreset.thisWeek => 'This week',
    AnalyticsRangePreset.lastWeek => 'Last week',
    AnalyticsRangePreset.thisMonth => DateFormat(
      'MMMM yyyy',
    ).format(filter.from),
    AnalyticsRangePreset.lastMonth => DateFormat(
      'MMMM yyyy',
    ).format(filter.from),
    AnalyticsRangePreset.last3Months => 'Last 3 months',
    AnalyticsRangePreset.last6Months => 'Last 6 months',
    AnalyticsRangePreset.thisYear => '${filter.from.year}',
    AnalyticsRangePreset.custom =>
      '${DateFormat('d MMM').format(filter.from)} – ${DateFormat('d MMM').format(filter.to)}',
  };

  static String _activeFilterLabel(AnalyticsFilter filter) {
    final count = [
      filter.type,
      filter.accountId,
      filter.categoryId,
      filter.paymentMethod,
    ].where((value) => value != null).length;
    return count == 0
        ? 'All transactions'
        : '$count filter${count == 1 ? '' : 's'}';
  }

  static Future<void> _chooseRange(BuildContext context) async {
    final controller = context.read<AnalyticsController>();
    final selected = await showModalBottomSheet<AnalyticsRangePreset>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: AnalyticsRangePreset.values
              .map(
                (preset) => ListTile(
                  leading: Icon(
                    controller.filter.preset == preset
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(_presetLabel(preset)),
                  onTap: () => Navigator.pop(sheetContext, preset),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    if (selected == AnalyticsRangePreset.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: DateTimeRange(
          start: controller.filter.from,
          end: controller.filter.to,
        ),
      );
      if (range == null || !context.mounted) return;
      await controller.load(
        filter: controller.filter.copyWith(
          from: range.start,
          to: range.end,
          preset: AnalyticsRangePreset.custom,
        ),
      );
      return;
    }
    final range = _datesFor(selected, DateTime.now());
    await controller.load(
      filter: controller.filter.copyWith(
        from: range.start,
        to: range.end,
        preset: selected,
      ),
    );
  }

  static Future<void> _showDetailedFilters(BuildContext context) async {
    final controller = context.read<AnalyticsController>();
    final snapshot = controller.snapshot;
    if (snapshot == null) return;
    var type = controller.filter.type;
    var accountId = controller.filter.accountId;
    var categoryId = controller.filter.categoryId;
    var payment = controller.filter.paymentMethod;
    final methods =
        snapshot.transactions
            .map((item) => item.paymentMethod)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final categories = snapshot.categories
        .where((item) => item.id != null)
        .toList();

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Analytics filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Transaction type',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Income and expense'),
                    ),
                    DropdownMenuItem(
                      value: 'income',
                      child: Text('Income only'),
                    ),
                    DropdownMenuItem(
                      value: 'expense',
                      child: Text('Expense only'),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => type = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  initialValue: accountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All accounts'),
                    ),
                    ...snapshot.accounts.map(
                      (item) => DropdownMenuItem(
                        value: item.account.id,
                        child: Text(item.account.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => accountId = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ...categories.map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => categoryId = value),
                ),
                if (methods.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    initialValue: payment,
                    decoration: const InputDecoration(
                      labelText: 'Payment method',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All methods'),
                      ),
                      ...methods.map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      ),
                    ],
                    onChanged: (value) => setSheetState(() => payment = value),
                  ),
                ],
                const SizedBox(height: 16),
                PrototypeButton(
                  label: 'Apply filters',
                  onPressed: () => Navigator.pop(sheetContext, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (apply == true && context.mounted) {
      await controller.load(
        filter: controller.filter.copyWith(
          type: type,
          clearType: type == null,
          accountId: accountId,
          clearAccount: accountId == null,
          categoryId: categoryId,
          clearCategory: categoryId == null,
          paymentMethod: payment,
          clearPaymentMethod: payment == null,
        ),
      );
    }
  }

  static DateTimeRange _datesFor(AnalyticsRangePreset preset, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return switch (preset) {
      AnalyticsRangePreset.today => DateTimeRange(start: today, end: today),
      AnalyticsRangePreset.yesterday => DateTimeRange(
        start: today.subtract(const Duration(days: 1)),
        end: today.subtract(const Duration(days: 1)),
      ),
      AnalyticsRangePreset.thisWeek => DateTimeRange(
        start: weekStart,
        end: today,
      ),
      AnalyticsRangePreset.lastWeek => DateTimeRange(
        start: weekStart.subtract(const Duration(days: 7)),
        end: weekStart.subtract(const Duration(days: 1)),
      ),
      AnalyticsRangePreset.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      AnalyticsRangePreset.lastMonth => DateTimeRange(
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month, 0),
      ),
      AnalyticsRangePreset.last3Months => DateTimeRange(
        start: DateTime(now.year, now.month - 2),
        end: today,
      ),
      AnalyticsRangePreset.last6Months => DateTimeRange(
        start: DateTime(now.year, now.month - 5),
        end: today,
      ),
      AnalyticsRangePreset.thisYear => DateTimeRange(
        start: DateTime(now.year),
        end: DateTime(now.year, 12, 31),
      ),
      AnalyticsRangePreset.custom => DateTimeRange(start: today, end: today),
    };
  }

  static String _presetLabel(AnalyticsRangePreset preset) => switch (preset) {
    AnalyticsRangePreset.today => 'Today',
    AnalyticsRangePreset.yesterday => 'Yesterday',
    AnalyticsRangePreset.thisWeek => 'This week',
    AnalyticsRangePreset.lastWeek => 'Last week',
    AnalyticsRangePreset.thisMonth => 'This month',
    AnalyticsRangePreset.lastMonth => 'Last month',
    AnalyticsRangePreset.last3Months => 'Last 3 months',
    AnalyticsRangePreset.last6Months => 'Last 6 months',
    AnalyticsRangePreset.thisYear => 'This year',
    AnalyticsRangePreset.custom => 'Custom date range',
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _AnalyticsScroll extends StatelessWidget {
  const _AnalyticsScroll({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: context.read<AnalyticsController>().refresh,
    child: ListView(padding: const EdgeInsets.all(16), children: children),
  );
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.transactions.isEmpty) {
      return _AnalyticsScroll(
        children: const [
          PrototypeEmptyState(
            icon: '📊',
            title: 'No financial activity',
            subtitle:
                'Choose another range or add a transaction to build analytics.',
          ),
        ],
      );
    }
    return _AnalyticsScroll(
      children: [
        _SummaryGrid(snapshot: snapshot),
        const SizedBox(height: 14),
        _ComparisonCard(snapshot: snapshot),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Daily income vs expense',
          subtitle: 'Tap a bar to inspect its value',
          child: _DailyBarChart(days: snapshot.daily),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Cumulative balance',
          subtitle: 'Running balance across the selected range',
          child: _BalanceLineChart(days: snapshot.daily),
        ),
        if (snapshot.monthlyTotals.length > 1) ...[
          const SizedBox(height: 14),
          _ChartCard(
            title: 'Monthly trend',
            subtitle: 'Income and expense by month',
            child: _MonthlyBarChart(months: snapshot.monthlyTotals),
          ),
        ],
        const SizedBox(height: 14),
        _CategoryDistribution(snapshot: snapshot),
        const SizedBox(height: 14),
        _AccountOverview(snapshot: snapshot),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'Income',
        snapshot.totals.income,
        Icons.south_west_rounded,
        AppColors.income,
      ),
      (
        'Expense',
        snapshot.totals.expense,
        Icons.north_east_rounded,
        AppColors.expense,
      ),
      (
        'Net savings',
        snapshot.totals.net,
        Icons.savings_outlined,
        AppColors.primary,
      ),
      (
        'Closing balance',
        snapshot.closingBalance,
        Icons.account_balance_wallet_outlined,
        AppColors.categoryBlue,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 700
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards
              .map(
                (item) => SizedBox(
                  width: width,
                  child: PrototypeCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.$3, color: item.$4, size: 20),
                        const SizedBox(height: 10),
                        Text(
                          CurrencyFormatter.format(item.$2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$1,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) => PrototypeCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Period comparison',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Compared with the previous matching period',
          style: TextStyle(fontSize: 11, color: context.appMuted),
        ),
        const SizedBox(height: 14),
        _ChangeRow(label: 'Income', value: snapshot.comparison.incomeChange),
        _ChangeRow(
          label: 'Expense',
          value: snapshot.comparison.expenseChange,
          lowerIsBetter: true,
        ),
        _ChangeRow(label: 'Savings', value: snapshot.comparison.savingsChange),
        _ChangeRow(
          label: 'Transactions',
          value: snapshot.comparison.transactionCountChange,
        ),
      ],
    ),
  );
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.label,
    required this.value,
    this.lowerIsBetter = false,
  });
  final String label;
  final double? value;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final meaningful = value != null && value!.abs() >= .1;
    final positive = value != null && (lowerIsBetter ? value! < 0 : value! > 0);
    final color = !meaningful
        ? context.appMuted
        : positive
        ? AppColors.income
        : AppColors.expense;
    final text = value == null
        ? 'No previous baseline'
        : !meaningful
        ? 'No meaningful change'
        : '${value! > 0 ? 'Increased' : 'Decreased'} by ${value!.abs().toStringAsFixed(1)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Icon(
            meaningful
                ? (value! > 0 ? Icons.trending_up : Icons.trending_down)
                : Icons.remove,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => PrototypeCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(fontSize: 11, color: context.appMuted)),
        const SizedBox(height: 18),
        SizedBox(height: 210, child: child),
      ],
    ),
  );
}

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({required this.days});
  final List<DailyAnalytics> days;

  @override
  Widget build(BuildContext context) {
    final active = days
        .where((day) => day.income > 0 || day.expense > 0)
        .toList();
    if (active.isEmpty) return const Center(child: Text('No daily activity'));
    final groups = active
        .map(
          (day) => BarChartGroupData(
            x: day.date.millisecondsSinceEpoch,
            barsSpace: 2,
            barRods: [
              BarChartRodData(
                toY: day.income,
                color: AppColors.income,
                width: 7,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: day.expense,
                color: AppColors.expense,
                width: 7,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        )
        .toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(
          MediaQuery.sizeOf(context).width - 68,
          groups.length * 34,
        ),
        child: BarChart(
          BarChartData(
            barGroups: groups,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: context.appBorder, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 25,
                  getTitlesWidget: (value, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateTime.fromMillisecondsSinceEpoch(
                        value.toInt(),
                      ).day.toString(),
                      style: TextStyle(fontSize: 9, color: context.appMuted),
                    ),
                  ),
                ),
              ),
            ),
          ),
          duration: const Duration(milliseconds: 450),
        ),
      ),
    );
  }
}

class _BalanceLineChart extends StatelessWidget {
  const _BalanceLineChart({required this.days});
  final List<DailyAnalytics> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const Center(child: Text('No balance data'));
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, days.length - 1).toDouble(),
        lineTouchData: const LineTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: context.appBorder),
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              days.length,
              (index) => FlSpot(index.toDouble(), days[index].runningBalance),
            ),
            color: AppColors.primary,
            barWidth: 3,
            isCurved: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: .12),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 450),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.months});
  final Map<DateTime, PeriodTotals> months;

  @override
  Widget build(BuildContext context) {
    final entries = months.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return BarChart(
      BarChartData(
        barGroups: List.generate(
          entries.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entries[index].value.income,
                color: AppColors.income,
                width: 10,
              ),
              BarChartRodData(
                toY: entries[index].value.expense,
                color: AppColors.expense,
                width: 10,
              ),
            ],
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: context.appBorder),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Text(
                DateFormat('MMM').format(
                  entries[value.toInt().clamp(0, entries.length - 1)].key,
                ),
                style: TextStyle(fontSize: 10, color: context.appMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDistribution extends StatelessWidget {
  const _CategoryDistribution({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final rows = snapshot.categories
        .where((item) => item.type == 'expense' && item.total > 0)
        .take(6)
        .toList();
    return PrototypeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense distribution',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const Text('No expense categories in this range')
          else
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${row.percentageOf(snapshot.totals.expense).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.format(row.total),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (row.percentageOf(snapshot.totals.expense) / 100)
                          .clamp(0, 1),
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: context.appBorder,
                      color: AppColors.expense,
                      semanticsLabel: '${row.name} share of expenses',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountOverview extends StatelessWidget {
  const _AccountOverview({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) => PrototypeCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accounts & wallets',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...snapshot.accounts.map(
          (row) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: context.appPrimarySoft,
              foregroundColor: AppColors.primary,
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 19,
              ),
            ),
            title: Text(row.account.name),
            subtitle: Text(
              '${row.count} transactions • ${row.mostUsedCategory ?? 'No category yet'}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(row.account.currentBalance),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Net ${CurrencyFormatter.format(row.net)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: row.net >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final month = DateTime(
      snapshot.filter.from.year,
      snapshot.filter.from.month,
    );
    final localizations = MaterialLocalizations.of(context);
    final firstDayIndex = localizations.firstDayOfWeekIndex;
    final leadingDays = (month.weekday % 7 - firstDayIndex + 7) % 7;
    final weekdayLabels = List.generate(
      7,
      (index) => localizations.narrowWeekdays[(firstDayIndex + index) % 7],
    );
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final byDate = {
      for (final day in snapshot.daily)
        DateTime(day.date.year, day.date.month, day.date.day): day,
    };
    return _AnalyticsScroll(
      children: [
        PrototypeCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(context, month, -1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectMonth(context, month),
                      child: Text(
                        DateFormat('MMMM yyyy').format(month),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _goCurrentMonth(context),
                    child: const Text('Today'),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(context, month, 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Row(
                children: weekdayLabels
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.appMuted,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: .78,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: leadingDays + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingDays) return const SizedBox.shrink();
                  final date = DateTime(
                    month.year,
                    month.month,
                    index - leadingDays + 1,
                  );
                  final data = byDate[date];
                  return _CalendarDayCell(
                    date: date,
                    data: data,
                    highestExpense: snapshot.highestExpenseDay?.date == date,
                    highestIncome: snapshot.highestIncomeDay?.date == date,
                    onTap: data == null || data.count == 0
                        ? null
                        : () => _showDay(context, data),
                  );
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: const [
                  _LegendDot(label: 'Income', color: AppColors.income),
                  _LegendDot(label: 'Expense', color: AppColors.expense),
                  _LegendDot(label: 'Mixed', color: AppColors.primary),
                  _LegendDot(label: 'Period high', color: AppColors.warning),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Transaction heatmap',
          subtitle: 'Toggle spending, income, or transaction intensity',
          child: _Heatmap(days: snapshot.daily),
        ),
      ],
    );
  }

  Future<void> _changeMonth(
    BuildContext context,
    DateTime month,
    int delta,
  ) async {
    final target = DateTime(month.year, month.month + delta);
    await _loadMonth(context, target);
  }

  Future<void> _selectMonth(BuildContext context, DateTime month) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: month,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECT A MONTH',
    );
    if (selected != null && context.mounted)
      await _loadMonth(context, selected);
  }

  Future<void> _goCurrentMonth(BuildContext context) =>
      _loadMonth(context, DateTime.now());

  Future<void> _loadMonth(BuildContext context, DateTime month) async {
    final controller = context.read<AnalyticsController>();
    await controller.load(
      filter: controller.filter.copyWith(
        from: DateTime(month.year, month.month),
        to: DateTime(month.year, month.month + 1, 0),
        preset: AnalyticsRangePreset.thisMonth,
      ),
    );
  }

  Future<void> _showDay(BuildContext context, DailyAnalytics day) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .94,
        builder: (_, scrollController) =>
            _DayDetails(day: day, scrollController: scrollController),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.data,
    required this.highestExpense,
    required this.highestIncome,
    required this.onTap,
  });
  final DateTime date;
  final DailyAnalytics? data;
  final bool highestExpense;
  final bool highestIncome;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasIncome = data?.hasIncome ?? false;
    final hasExpense = data?.hasExpense ?? false;
    final activeColor = hasIncome && hasExpense
        ? AppColors.primary
        : hasIncome
        ? AppColors.income
        : hasExpense
        ? AppColors.expense
        : context.appBorder;
    return Material(
      color: highestExpense || highestIncome
          ? AppColors.warning.withValues(alpha: .14)
          : context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (data != null && data!.count > 0) ...[
                Text(
                  _compact(data!.expense > 0 ? data!.expense : data!.income),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 8,
                    color: activeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasIncome) _dot(AppColors.income),
                    if (hasExpense) _dot(AppColors.expense),
                  ],
                ),
              ] else
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _dot(Color color) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 1),
    width: 5,
    height: 5,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
  static String _compact(double value) => value >= 1000000
      ? '${(value / 1000000).toStringAsFixed(1)}m'
      : value >= 1000
      ? '${(value / 1000).toStringAsFixed(1)}k'
      : value.toStringAsFixed(0);
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: context.appMuted)),
    ],
  );
}

enum _HeatmapMetric { expense, income, frequency }

class _Heatmap extends StatefulWidget {
  const _Heatmap({required this.days});
  final List<DailyAnalytics> days;

  @override
  State<_Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<_Heatmap> {
  _HeatmapMetric metric = _HeatmapMetric.expense;

  @override
  Widget build(BuildContext context) {
    double metricValue(DailyAnalytics day) => switch (metric) {
      _HeatmapMetric.expense => day.expense,
      _HeatmapMetric.income => day.income,
      _HeatmapMetric.frequency => day.count.toDouble(),
    };
    final maxValue = widget.days.fold(
      0.0,
      (value, day) => math.max(value, metricValue(day)),
    );
    final color = switch (metric) {
      _HeatmapMetric.expense => AppColors.expense,
      _HeatmapMetric.income => AppColors.income,
      _HeatmapMetric.frequency => AppColors.primary,
    };
    return Column(
      children: [
        SegmentedButton<_HeatmapMetric>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: _HeatmapMetric.expense,
              label: Text('Expense'),
            ),
            ButtonSegment(value: _HeatmapMetric.income, label: Text('Income')),
            ButtonSegment(
              value: _HeatmapMetric.frequency,
              label: Text('Count'),
            ),
          ],
          selected: {metric},
          onSelectionChanged: (selection) =>
              setState(() => metric = selection.first),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 14,
            physics: const NeverScrollableScrollPhysics(),
            children: widget.days
                .map(
                  (day) => Tooltip(
                    message: metric == _HeatmapMetric.frequency
                        ? '${DateFormat('d MMM').format(day.date)}: ${day.count} transactions'
                        : '${DateFormat('d MMM').format(day.date)}: ${CurrencyFormatter.format(metricValue(day))}',
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: metricValue(day) == 0
                            ? context.appBorder.withValues(alpha: .45)
                            : color.withValues(
                                alpha:
                                    .18 +
                                    .72 *
                                        (metricValue(day) /
                                            math.max(1, maxValue)),
                              ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DayDetails extends StatelessWidget {
  const _DayDetails({required this.day, required this.scrollController});
  final DailyAnalytics day;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final categories = <String, double>{};
    final accounts = <String, double>{};
    for (final transaction in day.transactions) {
      categories.update(
        transaction.category?.name ?? 'Uncategorized',
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
      accounts.update(
        transaction.account?.name ?? 'No account',
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(day.date),
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                label: 'Income',
                value: day.income,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                label: 'Expense',
                value: day.expense,
                color: AppColors.expense,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                label: 'Net',
                value: day.net,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${day.count} transaction${day.count == 1 ? '' : 's'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...day.transactions.map(
          (transaction) => _TransactionRow(transaction: transaction),
        ),
        const SizedBox(height: 14),
        _BreakdownList(title: 'Category breakdown', values: categories),
        const SizedBox(height: 12),
        _BreakdownList(title: 'Account breakdown', values: accounts),
        const SizedBox(height: 16),
        PrototypeButton(
          label: 'Add transaction for this date',
          icon: Icons.add,
          onPressed: () async {
            Navigator.pop(context);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CompactAddTransactionScreen(initialDate: day.date),
              ),
            );
            if (context.mounted)
              await context.read<AnalyticsController>().refresh();
          },
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: context.appMuted)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});
  final TransactionModel transaction;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: transaction.type == 'income'
          ? context.appIncomeSoft
          : context.appExpenseSoft,
      child: Icon(
        transaction.type == 'income' ? Icons.south_west : Icons.north_east,
        color: transaction.type == 'income'
            ? AppColors.income
            : AppColors.expense,
        size: 18,
      ),
    ),
    title: Text(transaction.title),
    subtitle: Text(
      '${transaction.category?.name ?? 'Uncategorized'} • ${transaction.account?.name ?? 'No account'}',
    ),
    trailing: Text(
      '${transaction.type == 'income' ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: transaction.type == 'income'
            ? AppColors.income
            : AppColors.expense,
      ),
    ),
  );
}

class _BreakdownList extends StatelessWidget {
  const _BreakdownList({required this.title, required this.values});
  final String title;
  final Map<String, double> values;
  @override
  Widget build(BuildContext context) => PrototypeCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...values.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(entry.key)),
                Text(
                  CurrencyFormatter.format(entry.value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final categories = snapshot.categories
        .where((item) => item.total > 0)
        .toList();
    return _AnalyticsScroll(
      children: [
        if (categories.isEmpty)
          const PrototypeEmptyState(
            icon: '🏷',
            title: 'No category activity',
            subtitle: 'No categorized transactions match the active filters.',
          )
        else
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PrototypeCard(
                onTap: () => _showCategory(context, category, snapshot),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: category.type == 'income'
                              ? context.appIncomeSoft
                              : context.appExpenseSoft,
                          child: Icon(
                            Icons.category_outlined,
                            color: category.type == 'income'
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${category.count} transactions • Avg ${CurrencyFormatter.format(category.average)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.appMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(category.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${category.changePercent >= 0 ? '+' : ''}${category.changePercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    category.changePercent <= 0 &&
                                        category.type == 'expense'
                                    ? AppColors.income
                                    : context.appMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (category.budget != null) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (category.budgetUsage / 100).clamp(0, 1),
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: context.appBorder,
                        color: category.budgetUsage > 100
                            ? AppColors.expense
                            : AppColors.primary,
                        semanticsLabel: '${category.name} budget usage',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCategory(
    BuildContext context,
    CategoryAnalytics category,
    AnalyticsSnapshot snapshot,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .76,
        maxChildSize: .94,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              category.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              '${category.type == 'income' ? 'Income source' : 'Expense category'} analytics',
              style: TextStyle(color: context.appMuted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(
                  label: 'Total',
                  value: CurrencyFormatter.format(category.total),
                ),
                _StatPill(
                  label: 'Average',
                  value: CurrencyFormatter.format(category.average),
                ),
                _StatPill(
                  label: 'Largest',
                  value: CurrencyFormatter.format(category.largest),
                ),
                _StatPill(
                  label: 'Smallest',
                  value: CurrencyFormatter.format(category.smallest),
                ),
                _StatPill(
                  label: 'Share',
                  value:
                      '${category.percentageOf(category.type == 'expense' ? snapshot.totals.expense : snapshot.totals.income).toStringAsFixed(1)}%',
                ),
                _StatPill(
                  label: 'Previous period',
                  value: CurrencyFormatter.format(category.previousTotal),
                ),
              ],
            ),
            if (category.transactions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Category trend',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 170,
                child: _CategoryTrendChart(
                  transactions: category.transactions,
                  color: category.type == 'income'
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ),
            ],
            if (category.budget != null) ...[
              const SizedBox(height: 14),
              _BudgetProgress(
                title: 'Category budget',
                used: category.total,
                total: category.budget!.amount,
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Related transactions',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            ...category.transactions.map(
              (item) => _TransactionRow(transaction: item),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTrendChart extends StatelessWidget {
  const _CategoryTrendChart({required this.transactions, required this.color});
  final List<TransactionModel> transactions;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, double>{};
    for (final item in transactions) {
      final date = DateTime(
        item.transactionDate.year,
        item.transactionDate.month,
        item.transactionDate.day,
      );
      grouped.update(
        date,
        (value) => value + item.amount,
        ifAbsent: () => item.amount,
      );
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return BarChart(
      BarChartData(
        barGroups: List.generate(
          entries.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entries[index].value,
                color: color,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: context.appBorder),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${entries[index].key.day}',
                  style: TextStyle(fontSize: 9, color: context.appMuted),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: context.appMuted)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _CashFlowTab extends StatelessWidget {
  const _CashFlowTab({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) => _AnalyticsScroll(
    children: [
      _SummaryGrid(snapshot: snapshot),
      const SizedBox(height: 14),
      _ChartCard(
        title: 'Running cash flow',
        subtitle: 'Actual daily closing balance',
        child: _BalanceLineChart(days: snapshot.daily),
      ),
      const SizedBox(height: 14),
      PrototypeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forecast',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Estimated closing balance',
              style: TextStyle(fontSize: 11, color: context.appMuted),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(snapshot.projectedClosingBalance),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Estimate based on the selected period’s current daily net cash-flow rate. It is not financial advice.',
              style: TextStyle(fontSize: 11, color: context.appMuted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _AccountOverview(snapshot: snapshot),
      const SizedBox(height: 14),
      PrototypeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekday spending pattern',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...List.generate(7, (index) {
              final weekday = index + 1;
              final value = snapshot.weekdayExpense[weekday] ?? 0;
              final max = snapshot.weekdayExpense.values.fold(0.0, math.max);
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        DateFormat('EEE').format(DateTime(2026, 7, 13 + index)),
                        style: TextStyle(fontSize: 10, color: context.appMuted),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : value / max,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: context.appBorder,
                        color: AppColors.categoryBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 88,
                      child: Text(
                        CurrencyFormatter.format(value),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ],
  );
}

class _BudgetTab extends StatelessWidget {
  const _BudgetTab({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.budgets.isEmpty) {
      return _AnalyticsScroll(
        children: const [
          PrototypeEmptyState(
            icon: '🎯',
            title: 'No budgets for this range',
            subtitle:
                'Create category budgets to monitor usage and projections.',
          ),
        ],
      );
    }
    final days = math.max(1, snapshot.daily.length);
    final recommended = math.max(0, snapshot.budgetRemaining / days).toDouble();
    final projected = snapshot.averageDailyExpense * days;
    return _AnalyticsScroll(
      children: [
        _BudgetProgress(
          title: 'Overall budget',
          used: snapshot.budgetUsed,
          total: snapshot.budgetTotal,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                label: 'Remaining',
                value: snapshot.budgetRemaining,
                color: snapshot.budgetRemaining >= 0
                    ? AppColors.income
                    : AppColors.expense,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                label: 'Daily target',
                value: recommended,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                label: 'Projected',
                value: projected,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...snapshot.categories
            .where((item) => item.budget != null)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BudgetProgress(
                  title: item.name,
                  used: item.total,
                  total: item.budget!.amount,
                ),
              ),
            ),
      ],
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  const _BudgetProgress({
    required this.title,
    required this.used,
    required this.total,
  });
  final String title;
  final double used;
  final double total;
  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : used / total * 100;
    final color = percentage > 100
        ? AppColors.expense
        : percentage >= 80
        ? AppColors.warning
        : AppColors.primary;
    return PrototypeCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${CurrencyFormatter.format(used)} of ${CurrencyFormatter.format(total)}',
            style: TextStyle(fontSize: 11, color: context.appMuted),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (percentage / 100).clamp(0, 1),
            minHeight: 10,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: context.appBorder,
            color: color,
            semanticsLabel: '$title budget usage',
          ),
          if (percentage >= 80) ...[
            const SizedBox(height: 8),
            Text(
              percentage > 100
                  ? 'Over budget by ${CurrencyFormatter.format(used - total)}'
                  : 'Near budget limit',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({required this.snapshot, required this.onAction});
  final AnalyticsSnapshot snapshot;
  final ValueChanged<String?> onAction;

  @override
  Widget build(BuildContext context) => _AnalyticsScroll(
    children: [
      PrototypeCard(
        child: Row(
          children: [
            SizedBox(
              width: 94,
              height: 94,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: snapshot.health.score / 100,
                    strokeWidth: 9,
                    backgroundColor: context.appBorder,
                    color: _healthColor(snapshot.health.score),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${snapshot.health.score}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text('/ 100', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${snapshot.health.category} financial health',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Calculated locally from savings, budget adherence, expense trend, and income consistency.',
                    style: TextStyle(fontSize: 11, color: context.appMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Informational only — not professional financial advice.',
                    style: TextStyle(fontSize: 10, color: context.appFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      PrototypeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score factors',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _FactorBar(
              label: 'Savings rate',
              value: snapshot.health.savingsFactor,
            ),
            _FactorBar(
              label: 'Budget adherence',
              value: snapshot.health.budgetFactor,
            ),
            _FactorBar(
              label: 'Expense trend',
              value: snapshot.health.expenseTrendFactor,
            ),
            _FactorBar(
              label: 'Income consistency',
              value: snapshot.health.incomeConsistencyFactor,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      ...snapshot.insights.map(
        (insight) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PrototypeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      insight.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  insight.explanation,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: context.appMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.dateRange,
                        style: TextStyle(fontSize: 10, color: context.appFaint),
                      ),
                    ),
                    if (insight.actionLabel != null)
                      TextButton(
                        onPressed: () => onAction(insight.actionLabel),
                        child: Text(insight.actionLabel!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Color _healthColor(int score) => score >= 65
      ? AppColors.income
      : score >= 45
      ? AppColors.warning
      : AppColors.expense;
}

class _FactorBar extends StatelessWidget {
  const _FactorBar({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10, color: context.appMuted),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: (value / 100).clamp(0, 1),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          backgroundColor: context.appBorder,
          color: AppColors.primary,
        ),
      ],
    ),
  );
}

class _AnalyticsSkeleton extends StatelessWidget {
  const _AnalyticsSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: List.generate(
      5,
      (index) => Container(
        height: index == 0 ? 130 : 190,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary.withValues(alpha: .65),
          ),
        ),
      ),
    ),
  );
}
