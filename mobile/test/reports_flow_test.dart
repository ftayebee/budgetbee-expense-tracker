import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_exception.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/features/analytics/domain/analytics_models.dart';
import 'package:expense_tracker/features/analytics/presentation/analytics_controller.dart';
import 'package:expense_tracker/features/analytics/presentation/premium_analytics_screen.dart';
import 'package:expense_tracker/presentation/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _MemoryStorage extends TokenStorage {
  String? value = 'token';
  @override
  Future<String?> read() async => value;
  @override
  Future<void> save(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

class _SequencedReportRepository extends ReportRepository {
  _SequencedReportRepository(this.responses)
    : super(ApiClient(_MemoryStorage()));

  final List<Object> responses;
  int calls = 0;

  @override
  Future<AnalyticsDataset> analytics(AnalyticsFilter filter) async {
    final response = responses[calls++];
    if (response is Exception) throw response;
    return response as AnalyticsDataset;
  }
}

AnalyticsDataset _emptyDataset() => AnalyticsDataset(
  from: DateTime(2026, 7, 1),
  to: DateTime(2026, 7, 31),
  comparisonFrom: DateTime(2026, 6, 1),
  comparisonTo: DateTime(2026, 6, 30),
  openingBalance: 0,
  closingBalance: 0,
  transactions: const [],
  comparisonTransactions: const [],
  accounts: const [],
  budgets: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'network error has a functional retry and empty response is not error',
    (tester) async {
      final repository = _SequencedReportRepository([
        ApiException('Unable to connect to the server.'),
        _emptyDataset(),
      ]);
      final controller = AnalyticsController(repository);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(home: PremiumAnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Unable to load reports. Check your internet connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.calls, 2);
      expect(
        find.text('No report data is available for the selected period.'),
        findsOneWidget,
      );
      expect(find.text('Something went wrong'), findsNothing);
    },
  );

  testWidgets('expired reports token clears session and redirects to login', (
    tester,
  ) async {
    final storage = _MemoryStorage();
    final auth = AuthProvider(AuthRepository(ApiClient(storage)), storage);
    final controller = AnalyticsController(
      _SequencedReportRepository([
        ApiException(
          'Your session has expired. Please sign in again.',
          statusCode: 401,
        ),
      ]),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: MaterialApp(
          home: const PremiumAnalyticsScreen(),
          routes: {'/login': (_) => const Scaffold(body: Text('Login screen'))},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login screen'), findsOneWidget);
    expect(storage.value, isNull);
  });

  test('malformed reports payload is rejected instead of defaulted', () {
    expect(
      () => AnalyticsDataset.fromJson({
        'from': 'not-a-date',
        'to': '2026-07-31',
        'comparison_from': '2026-06-01',
        'comparison_to': '2026-06-30',
        'opening_balance': 'NaN',
        'closing_balance': 0,
        'transactions': const [],
        'comparison_transactions': const [],
        'accounts': const [],
        'budgets': const [],
      }),
      throwsFormatException,
    );
  });

  test('timeout and server errors keep separate report states', () async {
    final timeout = AnalyticsController(
      _SequencedReportRepository([
        ApiException('The request timed out. Please try again.'),
      ]),
    );
    await timeout.load();
    expect(timeout.errorKind, AnalyticsErrorKind.timeout);

    final server = AnalyticsController(
      _SequencedReportRepository([
        ApiException('Server failure', statusCode: 500),
      ]),
    );
    await server.load();
    expect(server.errorKind, AnalyticsErrorKind.server);
  });
}
