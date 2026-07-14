import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/models/account_model.dart';
import 'package:expense_tracker/data/models/category_model.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/features/analytics/domain/analytics_models.dart';
import 'package:expense_tracker/features/analytics/presentation/analytics_controller.dart';
import 'package:expense_tracker/features/analytics/presentation/premium_analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeReportRepository extends ReportRepository {
  _FakeReportRepository(this.dataset) : super(ApiClient(TokenStorage()));

  final AnalyticsDataset dataset;

  @override
  Future<AnalyticsDataset> analytics(AnalyticsFilter filter) async => dataset;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final from = DateTime(2026, 7, 1);
  final to = DateTime(2026, 7, 31);
  const account = AccountModel(
    id: 1,
    name: 'Bank',
    type: 'bank',
    openingBalance: 1000,
    currentBalance: 1750,
  );
  const food = CategoryModel(id: 1, name: 'Food', type: 'expense');
  const salary = CategoryModel(id: 2, name: 'Salary', type: 'income');
  final dataset = AnalyticsDataset(
    from: from,
    to: to,
    comparisonFrom: DateTime(2026, 6, 1),
    comparisonTo: DateTime(2026, 6, 30),
    openingBalance: 1000,
    closingBalance: 1750,
    transactions: [
      TransactionModel(
        id: 1,
        title: 'Salary',
        type: 'income',
        amount: 1000,
        transactionDate: DateTime(2026, 7, 1),
        account: account,
        category: salary,
      ),
      TransactionModel(
        id: 2,
        title: 'Lunch',
        type: 'expense',
        amount: 250,
        transactionDate: DateTime(2026, 7, 2),
        account: account,
        category: food,
      ),
    ],
    comparisonTransactions: [
      TransactionModel(
        id: 3,
        title: 'Lunch',
        type: 'expense',
        amount: 200,
        transactionDate: DateTime(2026, 6, 2),
        account: account,
        category: food,
      ),
    ],
    accounts: const [account],
    budgets: const [],
  );

  Future<void> pumpAnalytics(
    WidgetTester tester, {
    required ThemeMode themeMode,
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AnalyticsController(_FakeReportRepository(dataset));
    controller.filter = AnalyticsFilter(
      from: from,
      to: to,
      preset: AnalyticsRangePreset.thisMonth,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: const PremiumAnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('premium analytics renders on a small light screen', (
    tester,
  ) async {
    await pumpAnalytics(
      tester,
      themeMode: ThemeMode.light,
      size: const Size(360, 720),
    );

    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Daily income vs expense'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Daily income vs expense'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar and dark theme render on a large screen', (
    tester,
  ) async {
    await pumpAnalytics(
      tester,
      themeMode: ThemeMode.dark,
      size: const Size(800, 1100),
    );

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('July 2026'), findsWidgets);
    expect(find.text('Transaction heatmap'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
