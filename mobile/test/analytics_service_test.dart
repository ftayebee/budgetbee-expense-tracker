import 'package:expense_tracker/data/models/account_model.dart';
import 'package:expense_tracker/data/models/budget_model.dart';
import 'package:expense_tracker/data/models/category_model.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/features/analytics/domain/analytics_models.dart';
import 'package:expense_tracker/features/analytics/domain/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AnalyticsService();
  const bank = AccountModel(
    id: 1,
    name: 'Bank',
    type: 'bank',
    openingBalance: 1000,
    currentBalance: 1510.3,
  );
  const food = CategoryModel(id: 1, name: 'Food', type: 'expense');
  const salary = CategoryModel(id: 2, name: 'Salary', type: 'income');
  const budget = BudgetModel(
    id: 1,
    category: food,
    amount: 500,
    spent: 190,
    period: 'monthly',
    month: 2,
    year: 2024,
  );

  TransactionModel tx(
    int id,
    String type,
    double amount,
    DateTime date, {
    CategoryModel? category,
  }) => TransactionModel(
    id: id,
    title: '$type $id',
    type: type,
    amount: amount,
    transactionDate: date,
    account: type == 'transfer' ? null : bank,
    category: category,
    fromAccount: type == 'transfer' ? bank : null,
    toAccount: type == 'transfer'
        ? const AccountModel(
            id: 2,
            name: 'Cash',
            type: 'cash',
            openingBalance: 0,
            currentBalance: 0,
          )
        : null,
  );

  AnalyticsDataset dataset({
    required List<TransactionModel> current,
    List<TransactionModel> previous = const [],
  }) => AnalyticsDataset(
    from: DateTime(2024, 2, 1),
    to: DateTime(2024, 2, 29),
    comparisonFrom: DateTime(2024, 1, 3),
    comparisonTo: DateTime(2024, 1, 31),
    openingBalance: 1000.1,
    closingBalance: 1510.3,
    transactions: current,
    comparisonTransactions: previous,
    accounts: const [bank],
    budgets: const [budget],
  );

  final filter = AnalyticsFilter(
    from: DateTime(2024, 2, 1),
    to: DateTime(2024, 2, 29),
    preset: AnalyticsRangePreset.custom,
  );

  test('calculates decimal-safe totals and excludes account transfers', () {
    final snapshot = service.calculate(
      dataset(
        current: [
          tx(1, 'income', 700.1, DateTime(2024, 2, 2), category: salary),
          tx(2, 'income', .2, DateTime(2024, 2, 2), category: salary),
          tx(3, 'expense', 100.1, DateTime(2024, 2, 3), category: food),
          tx(4, 'expense', 90, DateTime(2024, 2, 4), category: food),
          tx(5, 'transfer', 9999, DateTime(2024, 2, 5)),
        ],
        previous: [
          tx(6, 'income', 500, DateTime(2024, 1, 5), category: salary),
          tx(7, 'expense', 200, DateTime(2024, 1, 6), category: food),
        ],
      ),
      filter,
      clock: DateTime(2024, 2, 10),
    );

    expect(snapshot.totals.income, 700.3);
    expect(snapshot.totals.expense, 190.1);
    expect(snapshot.totals.net, 510.2);
    expect(snapshot.totals.transactionCount, 4);
    expect(snapshot.daily, hasLength(29));
    expect(snapshot.categories.first.name, 'Salary');
    expect(
      snapshot.categories.firstWhere((item) => item.name == 'Food').budget,
      budget,
    );
    expect(snapshot.comparison.expenseChange, closeTo(-4.95, .001));
    expect(snapshot.closingBalance, 1510.3);
    expect(snapshot.openingBalance, 1000.1);
    expect(snapshot.highestExpenseDay?.date, DateTime(2024, 2, 3));
  });

  test('handles empty periods and division by zero without invalid values', () {
    final snapshot = service.calculate(dataset(current: []), filter);

    expect(snapshot.totals.income, 0);
    expect(snapshot.totals.savingsRate, 0);
    expect(snapshot.comparison.incomeChange, 0);
    expect(snapshot.categories, isEmpty);
    expect(snapshot.highestExpense, isNull);
    expect(snapshot.health.score, inInclusiveRange(0, 100));
    expect(snapshot.insights, isNotEmpty);
  });

  test('insights are derived from actual category and weekday data', () {
    final snapshot = service.calculate(
      dataset(
        current: [
          tx(1, 'expense', 300, DateTime(2024, 2, 3), category: food),
          tx(2, 'expense', 100, DateTime(2024, 2, 4), category: food),
        ],
        previous: [tx(3, 'expense', 200, DateTime(2024, 1, 6), category: food)],
      ),
      filter,
    );

    expect(
      snapshot.insights.any((item) => item.title == 'Spending increased'),
      isTrue,
    );
    expect(
      snapshot.insights.any((item) => item.title.contains('Food')),
      isTrue,
    );
    expect(
      snapshot.insights.any((item) => item.title.contains('Weekend')),
      isTrue,
    );
    expect(snapshot.weekdayExpense[DateTime.saturday], 300);
    expect(snapshot.weekdayExpense[DateTime.sunday], 100);
  });
}
