import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/presentation/providers/app_providers.dart';
import 'package:expense_tracker/presentation/screens/transactions/compact_add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _EntryApiClient extends ApiClient {
  _EntryApiClient() : super(TokenStorage());

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == '/accounts') {
      return [
        {
          'id': 1,
          'name': 'Wallet',
          'type': 'cash',
          'opening_balance': 100,
          'current_balance': 100,
        },
      ];
    }
    if (path == '/categories') {
      return [
        {'id': 1, 'name': 'Salary', 'type': 'income'},
        {'id': 2, 'name': 'Food', 'type': 'expense'},
      ];
    }
    return [];
  }
}

void main() {
  Future<void> openForm(WidgetTester tester, String initialType) async {
    final repositories = Repositories(_EntryApiClient());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AccountProvider(repositories.accounts),
          ),
          ChangeNotifierProvider(
            create: (_) => CategoryProvider(repositories.categories),
          ),
          ChangeNotifierProvider(
            create: (_) => TransactionProvider(repositories.transactions),
          ),
        ],
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );
    final context = tester.element(find.byType(SizedBox).first);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(arguments: initialType),
        builder: (_) => const CompactAddTransactionScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Add Income opens Income and keeps all transaction tabs usable', (
    tester,
  ) async {
    await openForm(tester, 'income');

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('Save Transaction'), findsOneWidget);

    await tester.tap(find.text('Expense'));
    await tester.pump();
    expect(find.text('Category'), findsOneWidget);

    await tester.tap(find.text('Transfer'));
    await tester.pump();
    expect(find.text('From Account'), findsOneWidget);
    expect(find.text('To Account'), findsOneWidget);
  });

  testWidgets('Add Expense opens Expense and can switch to Income', (
    tester,
  ) async {
    await openForm(tester, 'expense');

    await tester.tap(find.text('Income'));
    await tester.pump();
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
