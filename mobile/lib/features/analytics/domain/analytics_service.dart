import 'dart:math' as math;

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import 'analytics_models.dart';

class AnalyticsService {
  const AnalyticsService();

  AnalyticsSnapshot calculate(
    AnalyticsDataset dataset,
    AnalyticsFilter filter, {
    DateTime? clock,
  }) {
    final transactions = dataset.transactions
        .where((item) => item.type == 'income' || item.type == 'expense')
        .toList(growable: false);
    final comparisonTransactions = dataset.comparisonTransactions
        .where((item) => item.type == 'income' || item.type == 'expense')
        .toList(growable: false);
    final totals = _totals(transactions);
    final previousTotals = _totals(comparisonTransactions);
    final openingBalance = _money(dataset.openingBalance);
    final closingBalance = _money(dataset.closingBalance);
    final daily = _daily(transactions, filter, openingBalance);
    final categories = _categories(
      transactions,
      comparisonTransactions,
      dataset.budgets,
      filter,
    );
    final accounts = _accounts(
      transactions,
      comparisonTransactions,
      dataset.accounts,
    );
    final comparison = ComparisonAnalytics(
      current: totals,
      previous: previousTotals,
      incomeChange: _change(totals.income, previousTotals.income),
      expenseChange: _change(totals.expense, previousTotals.expense),
      savingsChange: _change(totals.net, previousTotals.net),
      transactionCountChange: _change(
        totals.transactionCount.toDouble(),
        previousTotals.transactionCount.toDouble(),
      ),
    );
    final relevantBudgets = dataset.budgets.where((budget) {
      final month = DateTime(budget.year, budget.month);
      return filter.type != 'income' &&
          (filter.categoryId == null ||
              budget.category?.id == filter.categoryId) &&
          !month.isBefore(DateTime(filter.from.year, filter.from.month)) &&
          !month.isAfter(DateTime(filter.to.year, filter.to.month));
    }).toList();
    final weekdayExpense = <int, double>{};
    for (final transaction in transactions.where(
      (item) => item.type == 'expense',
    )) {
      weekdayExpense.update(
        transaction.transactionDate.weekday,
        (value) => _money(value + transaction.amount),
        ifAbsent: () => _money(transaction.amount),
      );
    }
    final monthlyTotals = <DateTime, PeriodTotals>{};
    for (final month in _groupByMonth(transactions).entries) {
      monthlyTotals[month.key] = _totals(month.value);
    }

    final highestIncome = _highest(transactions, 'income');
    final highestExpense = _highest(transactions, 'expense');
    final highestIncomeDay = _maxDay(daily, (item) => item.income);
    final highestExpenseDay = _maxDay(daily, (item) => item.expense);
    final mostActiveDay = _maxDay(daily, (item) => item.count.toDouble());
    final health = _health(
      totals,
      previousTotals,
      relevantBudgets,
      categories,
      daily,
    );
    final projectedClosing = _projectedClosingBalance(
      closingBalance,
      totals,
      filter,
      clock ?? DateTime.now(),
    );

    return AnalyticsSnapshot(
      filter: filter,
      transactions: transactions,
      totals: totals,
      comparison: comparison,
      daily: daily,
      categories: categories,
      accounts: accounts,
      budgets: relevantBudgets,
      weekdayExpense: weekdayExpense,
      monthlyTotals: monthlyTotals,
      insights: _insights(
        totals,
        previousTotals,
        categories,
        weekdayExpense,
        highestExpenseDay,
        relevantBudgets,
        filter,
      ),
      health: health,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      highestIncome: highestIncome,
      highestExpense: highestExpense,
      highestIncomeDay: highestIncomeDay,
      highestExpenseDay: highestExpenseDay,
      mostActiveDay: mostActiveDay,
      projectedClosingBalance: projectedClosing,
    );
  }

  PeriodTotals _totals(List<TransactionModel> transactions) {
    var incomeMinor = 0;
    var expenseMinor = 0;
    var incomeCount = 0;
    var expenseCount = 0;
    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        incomeMinor += _minor(transaction.amount);
        incomeCount++;
      } else if (transaction.type == 'expense') {
        expenseMinor += _minor(transaction.amount);
        expenseCount++;
      }
    }
    return PeriodTotals(
      income: incomeMinor / 100,
      expense: expenseMinor / 100,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
    );
  }

  List<DailyAnalytics> _daily(
    List<TransactionModel> transactions,
    AnalyticsFilter filter,
    double openingBalance,
  ) {
    final groups = <DateTime, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final date = _day(transaction.transactionDate);
      groups.putIfAbsent(date, () => []).add(transaction);
    }
    final result = <DailyAnalytics>[];
    var running = openingBalance;
    for (
      var date = _day(filter.from);
      !date.isAfter(_day(filter.to));
      date = date.add(const Duration(days: 1))
    ) {
      final items = groups[date] ?? const <TransactionModel>[];
      final totals = _totals(items);
      running = _money(running + totals.net);
      result.add(
        DailyAnalytics(
          date: date,
          income: totals.income,
          expense: totals.expense,
          transactions: items,
          runningBalance: running,
        ),
      );
    }
    return result;
  }

  List<CategoryAnalytics> _categories(
    List<TransactionModel> current,
    List<TransactionModel> previous,
    List<BudgetModel> budgets,
    AnalyticsFilter filter,
  ) {
    final currentGroups = _groupByCategory(current);
    final previousGroups = _groupByCategory(previous);
    final keys = {...currentGroups.keys, ...previousGroups.keys};
    final result = <CategoryAnalytics>[];
    for (final key in keys) {
      final items = currentGroups[key] ?? const <TransactionModel>[];
      final previousItems = previousGroups[key] ?? const <TransactionModel>[];
      final sample = items.isNotEmpty ? items.first : previousItems.first;
      final amounts = items.map((item) => item.amount).toList()..sort();
      final dateFrequency = <DateTime, int>{};
      for (final transaction in items) {
        dateFrequency.update(
          _day(transaction.transactionDate),
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      final frequentDate = dateFrequency.entries.isEmpty
          ? null
          : (dateFrequency.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key;
      final total = _sum(items);
      final budget = budgets.cast<BudgetModel?>().firstWhere(
        (item) =>
            item?.category?.id == sample.category?.id &&
            item?.month == filter.to.month &&
            item?.year == filter.to.year,
        orElse: () => null,
      );
      result.add(
        CategoryAnalytics(
          id: sample.category?.id,
          name: sample.category?.name ?? 'Uncategorized',
          type: sample.type,
          total: total,
          count: items.length,
          average: items.isEmpty ? 0 : _money(total / items.length),
          largest: amounts.isEmpty ? 0 : amounts.last,
          smallest: amounts.isEmpty ? 0 : amounts.first,
          mostFrequentDate: frequentDate,
          previousTotal: _sum(previousItems),
          budget: budget,
          transactions: items,
        ),
      );
    }
    result.sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  List<AccountAnalytics> _accounts(
    List<TransactionModel> current,
    List<TransactionModel> previous,
    List<AccountModel> accounts,
  ) {
    final result = <AccountAnalytics>[];
    for (final account in accounts) {
      final items = current
          .where((item) => item.account?.id == account.id)
          .toList();
      final previousItems = previous
          .where((item) => item.account?.id == account.id)
          .toList();
      final totals = _totals(items);
      final categoryFrequency = <String, int>{};
      for (final item in items) {
        final name = item.category?.name ?? 'Uncategorized';
        categoryFrequency.update(name, (value) => value + 1, ifAbsent: () => 1);
      }
      final topCategory = categoryFrequency.entries.isEmpty
          ? null
          : (categoryFrequency.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key;
      items.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      result.add(
        AccountAnalytics(
          account: account,
          inflow: totals.income,
          outflow: totals.expense,
          count: totals.transactionCount,
          average: totals.transactionCount == 0
              ? 0
              : _money(
                  (totals.income + totals.expense) / totals.transactionCount,
                ),
          previousNet: _totals(previousItems).net,
          mostUsedCategory: topCategory,
          lastTransactionDate: items.isEmpty
              ? null
              : items.first.transactionDate,
        ),
      );
    }
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  FinancialHealthScore _health(
    PeriodTotals current,
    PeriodTotals previous,
    List<BudgetModel> budgets,
    List<CategoryAnalytics> categories,
    List<DailyAnalytics> daily,
  ) {
    final savings = (current.savingsRate.clamp(0, 30) / 30) * 100;
    final budgetTotal = budgets.fold(0.0, (sum, item) => sum + item.amount);
    final expense = categories
        .where((item) => item.type == 'expense')
        .fold(0.0, (sum, item) => sum + item.total);
    final budget = budgetTotal == 0
        ? 60.0
        : (100 - math.max(0, (expense / budgetTotal * 100) - 100)).clamp(
            0,
            100,
          );
    final expenseTrend = previous.expense == 0
        ? 60.0
        : (100 - math.max(0, _change(current.expense, previous.expense) ?? 0))
              .clamp(0, 100);
    final incomeDays = daily.where((item) => item.income > 0).length;
    final consistency = daily.isEmpty
        ? 0.0
        : (incomeDays / math.min(daily.length, 4) * 100).clamp(0, 100);
    final score =
        (savings * .35 + budget * .30 + expenseTrend * .20 + consistency * .15)
            .round()
            .clamp(0, 100);
    return FinancialHealthScore(
      score: score,
      savingsFactor: savings,
      budgetFactor: budget.toDouble(),
      expenseTrendFactor: expenseTrend.toDouble(),
      incomeConsistencyFactor: consistency.toDouble(),
    );
  }

  List<FinancialInsight> _insights(
    PeriodTotals current,
    PeriodTotals previous,
    List<CategoryAnalytics> categories,
    Map<int, double> weekdayExpense,
    DailyAnalytics? highestExpenseDay,
    List<BudgetModel> budgets,
    AnalyticsFilter filter,
  ) {
    final range = '${_shortDate(filter.from)} – ${_shortDate(filter.to)}';
    final insights = <FinancialInsight>[];
    final expenseChange = _change(current.expense, previous.expense);
    if (expenseChange != null) {
      insights.add(
        FinancialInsight(
          title: expenseChange >= 0
              ? 'Spending increased'
              : 'Spending decreased',
          explanation:
              'Expenses were ${expenseChange.abs().toStringAsFixed(1)}% ${expenseChange >= 0 ? 'higher' : 'lower'} than the previous matching period.',
          value:
              '${expenseChange >= 0 ? '+' : '-'}${expenseChange.abs().toStringAsFixed(1)}%',
          dateRange: range,
          actionLabel: 'View comparison',
        ),
      );
    }
    final expenseCategories = categories
        .where((item) => item.type == 'expense' && item.total > 0)
        .toList();
    if (expenseCategories.isNotEmpty) {
      final top = expenseCategories.first;
      insights.add(
        FinancialInsight(
          title: '${top.name} is your top expense',
          explanation:
              '${top.percentageOf(current.expense).toStringAsFixed(1)}% of spending came from ${top.name}.',
          value: CurrencyFormatter.format(top.total),
          dateRange: range,
          actionLabel: 'Open category',
        ),
      );
    }
    final weekend =
        (weekdayExpense[DateTime.saturday] ?? 0) +
        (weekdayExpense[DateTime.sunday] ?? 0);
    final weekday = weekdayExpense.entries
        .where((entry) => entry.key <= DateTime.friday)
        .fold(0.0, (sum, entry) => sum + entry.value);
    if (weekend > 0 || weekday > 0) {
      insights.add(
        FinancialInsight(
          title: weekend > weekday
              ? 'Weekend spending is higher'
              : 'Weekday spending is higher',
          explanation:
              '${CurrencyFormatter.format(weekend)} was spent on weekends versus ${CurrencyFormatter.format(weekday)} on weekdays.',
          value: CurrencyFormatter.format(math.max(weekend, weekday)),
          dateRange: range,
        ),
      );
    }
    if (highestExpenseDay != null && highestExpenseDay.expense > 0) {
      insights.add(
        FinancialInsight(
          title: 'Highest spending day',
          explanation:
              '${_shortDate(highestExpenseDay.date)} had ${highestExpenseDay.count} transaction${highestExpenseDay.count == 1 ? '' : 's'}.',
          value: CurrencyFormatter.format(highestExpenseDay.expense),
          dateRange: range,
          actionLabel: 'View day',
        ),
      );
    }
    final budgetTotal = budgets.fold(0.0, (sum, item) => sum + item.amount);
    if (budgetTotal > 0) {
      final usage = current.expense / budgetTotal * 100;
      if (usage >= 75) {
        insights.add(
          FinancialInsight(
            title: usage > 100
                ? 'Monthly budget exceeded'
                : 'Budget is nearly used',
            explanation:
                'You have used ${usage.toStringAsFixed(1)}% of the selected month’s budget.',
            value: '${usage.toStringAsFixed(1)}%',
            dateRange: range,
            actionLabel: 'Review budget',
          ),
        );
      }
    }
    if (insights.isEmpty) {
      insights.add(
        FinancialInsight(
          title: 'More activity will unlock insights',
          explanation:
              'Insights appear when the selected range contains comparable income or expense activity.',
          value: '${current.transactionCount} transactions',
          dateRange: range,
        ),
      );
    }
    return insights;
  }

  double _projectedClosingBalance(
    double closingBalance,
    PeriodTotals totals,
    AnalyticsFilter filter,
    DateTime now,
  ) {
    if (filter.from.year != now.year ||
        filter.from.month != now.month ||
        filter.to.month != now.month) {
      return closingBalance;
    }
    final elapsed = math.max(1, now.day);
    final remaining = math.max(0, filter.to.day - now.day);
    return _money(closingBalance + (totals.net / elapsed * remaining));
  }

  Map<String, List<TransactionModel>> _groupByCategory(
    List<TransactionModel> transactions,
  ) {
    final groups = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final key = '${transaction.type}:${transaction.category?.id ?? 0}';
      groups.putIfAbsent(key, () => []).add(transaction);
    }
    return groups;
  }

  Map<DateTime, List<TransactionModel>> _groupByMonth(
    List<TransactionModel> transactions,
  ) {
    final groups = <DateTime, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final month = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
      );
      groups.putIfAbsent(month, () => []).add(transaction);
    }
    return groups;
  }

  TransactionModel? _highest(List<TransactionModel> transactions, String type) {
    final items = transactions.where((item) => item.type == type).toList();
    if (items.isEmpty) return null;
    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items.first;
  }

  DailyAnalytics? _maxDay(
    List<DailyAnalytics> days,
    double Function(DailyAnalytics) value,
  ) {
    final active = days.where((item) => value(item) > 0).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => value(b).compareTo(value(a)));
    return active.first;
  }

  double _sum(List<TransactionModel> transactions) =>
      transactions.fold(0, (sum, item) => _money(sum + item.amount));

  double? _change(double current, double previous) {
    if (previous == 0) return current == 0 ? 0 : null;
    return (current - previous) / previous.abs() * 100;
  }

  int _minor(double value) => (value * 100).round();
  double _money(double value) => _minor(value) / 100;
  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
  String _shortDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}
