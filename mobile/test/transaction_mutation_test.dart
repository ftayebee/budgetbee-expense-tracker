import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_exception.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/presentation/providers/app_providers.dart';
import 'package:expense_tracker/presentation/screens/transactions/compact_add_transaction_screen.dart';
import 'package:expense_tracker/presentation/screens/transactions/transaction_details_screen.dart';
import 'package:expense_tracker/presentation/widgets/app_widgets.dart';
import 'package:expense_tracker/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(TokenStorage());

  String? method;
  String? path;
  Map<String, dynamic>? payload;
  bool failDelete = false;
  dynamic updateResponse;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == '/accounts') {
      return [
        {
          'id': 3,
          'name': 'Wallet',
          'type': 'cash',
          'opening_balance': 500,
          'current_balance': 375,
        },
      ];
    }
    if (path == '/categories') {
      return [
        {'id': 4, 'name': 'Food', 'type': 'expense'},
      ];
    }
    return [];
  }

  @override
  Future<dynamic> put(String path, {Map<String, dynamic>? data}) async {
    method = 'PUT';
    this.path = path;
    payload = data;
    return updateResponse;
  }

  @override
  Future<dynamic> delete(String path) async {
    method = 'DELETE';
    this.path = path;
    if (failDelete) throw ApiException('Server refused deletion');
    return null;
  }
}

TransactionModel transaction(int id) => TransactionModel(
  id: id,
  title: 'Groceries',
  type: 'expense',
  amount: 125,
  transactionDate: DateTime(2026, 7, 16),
);

void main() {
  testWidgets(
    'details Edit button opens the typed edit route with transaction',
    (tester) async {
      final client = _FakeApiClient();
      final repo = Repositories(client);
      final existing = TransactionModel.fromJson({
        'id': 42,
        'title': 'Food',
        'type': 'expense',
        'amount': 125.5,
        'transaction_date': '2026-07-16',
        'note': 'Lunch',
        'account': {
          'id': 3,
          'name': 'Wallet',
          'type': 'cash',
          'opening_balance': 500,
          'current_balance': 375,
        },
        'category': {'id': 4, 'name': 'Food', 'type': 'expense'},
      });
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AccountProvider(repo.accounts),
            ),
            ChangeNotifierProvider(
              create: (_) => CategoryProvider(repo.categories),
            ),
            ChangeNotifierProvider(
              create: (_) => TransactionProvider(repo.transactions),
            ),
          ],
          child: MaterialApp(
            home: const SizedBox.shrink(),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          settings: RouteSettings(arguments: existing),
          builder: (_) => const TransactionDetailsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('Update Transaction'), findsOneWidget);
      expect(find.text('Add Transaction'), findsNothing);
    },
  );

  testWidgets('transaction card Edit popup invokes the edit callback once', (
    tester,
  ) async {
    var editCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrototypeTransactionCard(
            transaction: transaction(12),
            onEdit: () => editCalls++,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Transaction actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(editCalls, 1);
  });

  testWidgets(
    'edit form pre-fills existing transaction data and labels update',
    (tester) async {
      final client = _FakeApiClient();
      final repo = Repositories(client);
      final existing = TransactionModel.fromJson({
        'id': 42,
        'title': 'Food',
        'type': 'expense',
        'amount': 125.5,
        'transaction_date': '2026-07-16',
        'note': 'Lunch',
        'payment_method': 'Account',
        'account': {
          'id': 3,
          'name': 'Wallet',
          'type': 'cash',
          'opening_balance': 500,
          'current_balance': 375,
        },
        'category': {'id': 4, 'name': 'Food', 'type': 'expense'},
      });
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AccountProvider(repo.accounts),
            ),
            ChangeNotifierProvider(
              create: (_) => CategoryProvider(repo.categories),
            ),
            ChangeNotifierProvider(
              create: (_) => TransactionProvider(repo.transactions),
            ),
          ],
          child: MaterialApp(
            home: CompactAddTransactionScreen(transaction: existing),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('Update Transaction'), findsOneWidget);
      final fields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(fields.any((field) => field.controller?.text == '125.5'), isTrue);
      expect(fields.any((field) => field.controller?.text == 'Lunch'), isTrue);
    },
  );

  test(
    'update uses the correct ID and treats an empty 204 body as success',
    () async {
      final client = _FakeApiClient()..updateResponse = null;
      final provider = TransactionProvider(TransactionRepository(client));
      provider.transactions = [transaction(42)];

      final success = await provider.save({'amount': 150}, 42);

      expect(success, isTrue);
      expect(client.method, 'PUT');
      expect(client.path, '/transactions/42');
      expect(client.payload?['amount'], 150);
      expect(provider.error, isNull);
      expect(provider.revision, 1);
    },
  );

  test(
    'successful deletion uses ID, removes immediately, and supports 204',
    () async {
      final client = _FakeApiClient();
      final provider = TransactionProvider(TransactionRepository(client));
      provider.transactions = [transaction(7)];

      final success = await provider.remove(7);

      expect(success, isTrue);
      expect(client.method, 'DELETE');
      expect(client.path, '/transactions/7');
      expect(provider.transactions, isEmpty);
      expect(provider.revision, 1);
    },
  );

  test(
    'failed deletion keeps the transaction and exposes the API error',
    () async {
      final client = _FakeApiClient()..failDelete = true;
      final provider = TransactionProvider(TransactionRepository(client));
      provider.transactions = [transaction(9)];

      final success = await provider.remove(9);

      expect(success, isFalse);
      expect(provider.transactions.single.id, 9);
      expect(provider.error, 'Server refused deletion');
      expect(provider.revision, 0);
    },
  );
}
