import '../../../data/models/account_model.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';

enum AnalyticsRangePreset {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  thisYear,
  custom,
}

class AnalyticsFilter {
  const AnalyticsFilter({
    required this.from,
    required this.to,
    this.preset = AnalyticsRangePreset.thisMonth,
    this.type,
    this.accountId,
    this.categoryId,
    this.paymentMethod,
  });

  factory AnalyticsFilter.thisMonth([DateTime? clock]) {
    final now = clock ?? DateTime.now();
    return AnalyticsFilter(
      from: DateTime(now.year, now.month),
      to: DateTime(now.year, now.month + 1, 0),
    );
  }

  final DateTime from;
  final DateTime to;
  final AnalyticsRangePreset preset;
  final String? type;
  final int? accountId;
  final int? categoryId;
  final String? paymentMethod;

  AnalyticsFilter copyWith({
    DateTime? from,
    DateTime? to,
    AnalyticsRangePreset? preset,
    String? type,
    bool clearType = false,
    int? accountId,
    bool clearAccount = false,
    int? categoryId,
    bool clearCategory = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
  }) => AnalyticsFilter(
    from: from ?? this.from,
    to: to ?? this.to,
    preset: preset ?? this.preset,
    type: clearType ? null : type ?? this.type,
    accountId: clearAccount ? null : accountId ?? this.accountId,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    paymentMethod: clearPaymentMethod
        ? null
        : paymentMethod ?? this.paymentMethod,
  );

  Map<String, dynamic> toQuery() => {
    'from': _date(from),
    'to': _date(to),
    if (type != null) 'type': type,
    if (accountId != null) 'account_id': accountId,
    if (categoryId != null) 'category_id': categoryId,
    if (paymentMethod != null) 'payment_method': paymentMethod,
  };

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class AnalyticsDataset {
  const AnalyticsDataset({
    required this.from,
    required this.to,
    required this.comparisonFrom,
    required this.comparisonTo,
    required this.openingBalance,
    required this.closingBalance,
    required this.transactions,
    required this.comparisonTransactions,
    required this.accounts,
    required this.budgets,
  });

  final DateTime from;
  final DateTime to;
  final DateTime comparisonFrom;
  final DateTime comparisonTo;
  final double openingBalance;
  final double closingBalance;
  final List<TransactionModel> transactions;
  final List<TransactionModel> comparisonTransactions;
  final List<AccountModel> accounts;
  final List<BudgetModel> budgets;

  factory AnalyticsDataset.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      dynamic value,
      T Function(Map<String, dynamic>) parser,
    ) {
      if (value is Map && value['data'] is List) value = value['data'];
      if (value is! List) return [];
      return value
          .map((item) => parser(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    DateTime parseDate(String key) =>
        DateTime.tryParse('${json[key]}') ?? DateTime.now();

    return AnalyticsDataset(
      from: parseDate('from'),
      to: parseDate('to'),
      comparisonFrom: parseDate('comparison_from'),
      comparisonTo: parseDate('comparison_to'),
      openingBalance: _double(json['opening_balance']),
      closingBalance: _double(json['closing_balance']),
      transactions: parseList(json['transactions'], TransactionModel.fromJson),
      comparisonTransactions: parseList(
        json['comparison_transactions'],
        TransactionModel.fromJson,
      ),
      accounts: parseList(json['accounts'], AccountModel.fromJson),
      budgets: parseList(json['budgets'], BudgetModel.fromJson),
    );
  }

  static double _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class PeriodTotals {
  const PeriodTotals({
    required this.income,
    required this.expense,
    required this.incomeCount,
    required this.expenseCount,
  });

  final double income;
  final double expense;
  final int incomeCount;
  final int expenseCount;
  double get net => ((income * 100).round() - (expense * 100).round()) / 100;
  double get savingsRate => income == 0 ? 0 : (net / income) * 100;
  int get transactionCount => incomeCount + expenseCount;
}

class DailyAnalytics {
  const DailyAnalytics({
    required this.date,
    required this.income,
    required this.expense,
    required this.transactions,
    required this.runningBalance,
  });

  final DateTime date;
  final double income;
  final double expense;
  final List<TransactionModel> transactions;
  final double runningBalance;
  double get net => income - expense;
  int get count => transactions.length;
  bool get hasIncome => income > 0;
  bool get hasExpense => expense > 0;
}

class CategoryAnalytics {
  const CategoryAnalytics({
    required this.id,
    required this.name,
    required this.type,
    required this.total,
    required this.count,
    required this.average,
    required this.largest,
    required this.smallest,
    required this.mostFrequentDate,
    required this.previousTotal,
    required this.budget,
    required this.transactions,
  });

  final int? id;
  final String name;
  final String type;
  final double total;
  final int count;
  final double average;
  final double largest;
  final double smallest;
  final DateTime? mostFrequentDate;
  final double previousTotal;
  final BudgetModel? budget;
  final List<TransactionModel> transactions;
  double percentageOf(double grandTotal) =>
      grandTotal == 0 ? 0 : total / grandTotal * 100;
  double get changePercent => previousTotal == 0
      ? (total == 0 ? 0 : 100)
      : (total - previousTotal) / previousTotal * 100;
  double get budgetUsage =>
      budget == null || budget!.amount == 0 ? 0 : total / budget!.amount * 100;
}

class AccountAnalytics {
  const AccountAnalytics({
    required this.account,
    required this.inflow,
    required this.outflow,
    required this.count,
    required this.average,
    required this.previousNet,
    required this.mostUsedCategory,
    required this.lastTransactionDate,
  });

  final AccountModel account;
  final double inflow;
  final double outflow;
  final int count;
  final double average;
  final double previousNet;
  final String? mostUsedCategory;
  final DateTime? lastTransactionDate;
  double get net => inflow - outflow;
}

class ComparisonAnalytics {
  const ComparisonAnalytics({
    required this.current,
    required this.previous,
    required this.incomeChange,
    required this.expenseChange,
    required this.savingsChange,
    required this.transactionCountChange,
  });

  final PeriodTotals current;
  final PeriodTotals previous;
  final double? incomeChange;
  final double? expenseChange;
  final double? savingsChange;
  final double? transactionCountChange;
}

class FinancialInsight {
  const FinancialInsight({
    required this.title,
    required this.explanation,
    required this.value,
    required this.dateRange,
    this.actionLabel,
  });

  final String title;
  final String explanation;
  final String value;
  final String dateRange;
  final String? actionLabel;
}

class FinancialHealthScore {
  const FinancialHealthScore({
    required this.score,
    required this.savingsFactor,
    required this.budgetFactor,
    required this.expenseTrendFactor,
    required this.incomeConsistencyFactor,
  });

  final int score;
  final double savingsFactor;
  final double budgetFactor;
  final double expenseTrendFactor;
  final double incomeConsistencyFactor;
  String get category => switch (score) {
    >= 80 => 'Strong',
    >= 65 => 'Healthy',
    >= 45 => 'Developing',
    _ => 'Needs attention',
  };
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.filter,
    required this.transactions,
    required this.totals,
    required this.comparison,
    required this.daily,
    required this.categories,
    required this.accounts,
    required this.budgets,
    required this.weekdayExpense,
    required this.monthlyTotals,
    required this.insights,
    required this.health,
    required this.openingBalance,
    required this.closingBalance,
    required this.highestIncome,
    required this.highestExpense,
    required this.highestIncomeDay,
    required this.highestExpenseDay,
    required this.mostActiveDay,
    required this.projectedClosingBalance,
  });

  final AnalyticsFilter filter;
  final List<TransactionModel> transactions;
  final PeriodTotals totals;
  final ComparisonAnalytics comparison;
  final List<DailyAnalytics> daily;
  final List<CategoryAnalytics> categories;
  final List<AccountAnalytics> accounts;
  final List<BudgetModel> budgets;
  final Map<int, double> weekdayExpense;
  final Map<DateTime, PeriodTotals> monthlyTotals;
  final List<FinancialInsight> insights;
  final FinancialHealthScore health;
  final double openingBalance;
  final double closingBalance;
  final TransactionModel? highestIncome;
  final TransactionModel? highestExpense;
  final DailyAnalytics? highestIncomeDay;
  final DailyAnalytics? highestExpenseDay;
  final DailyAnalytics? mostActiveDay;
  final double projectedClosingBalance;

  double get averageDailyIncome =>
      daily.isEmpty ? 0 : totals.income / daily.length;
  double get averageDailyExpense =>
      daily.isEmpty ? 0 : totals.expense / daily.length;
  double get budgetTotal => budgets.fold(0, (sum, item) => sum + item.amount);
  double get budgetUsed => categories
      .where((item) => item.type == 'expense')
      .fold(0, (sum, item) => sum + item.total);
  double get budgetRemaining => budgetTotal - budgetUsed;
}
