import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/presentation/providers/app_providers.dart';
import 'package:expense_tracker/presentation/screens/transactions/compact_add_transaction_screen.dart';
import 'package:expense_tracker/presentation/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _QuickAddApiClient extends ApiClient {
  _QuickAddApiClient() : super(TokenStorage());

  final accounts = <Map<String, dynamic>>[
    {
      'id': 1,
      'name': 'Wallet',
      'type': 'cash',
      'opening_balance': 100,
      'current_balance': 100,
    },
  ];
  int accountPosts = 0;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == '/accounts') return List<dynamic>.from(accounts);
    if (path == '/categories') {
      return [
        {'id': 1, 'name': 'Salary', 'type': 'income'},
        {'id': 2, 'name': 'Food', 'type': 'expense'},
      ];
    }
    return [];
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    if (path != '/accounts') return null;
    accountPosts++;
    final account = <String, dynamic>{
      'id': 9,
      'name': data!['name'],
      'type': data['type'],
      'opening_balance': data['opening_balance'],
      'current_balance': data['opening_balance'],
    };
    accounts.insert(0, account);
    return account;
  }
}

void main() {
  Future<_QuickAddApiClient> pumpForm(
    WidgetTester tester, {
    String initialType = 'expense',
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final client = _QuickAddApiClient();
    final repositories = Repositories(client);
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
        child: MaterialApp(
          themeMode: themeMode,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          home: const SizedBox.shrink(),
        ),
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
    return client;
  }

  testWidgets(
    'quick add creates, refreshes, selects, and preserves transaction values',
    (tester) async {
      final client = await pumpForm(tester);

      final transactionFields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      await tester.enterText(find.byWidget(transactionFields.first), '245.75');
      await tester.enterText(
        find.byWidget(transactionFields.last),
        'Dinner with family',
      );

      expect(find.byTooltip('Add account'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('quick-add-account-button')));
      await tester.pumpAndSettle();

      final nameField = find.descendant(
        of: find.byKey(const ValueKey('account-name-field')),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(nameField, 'New bank');
      await tester.tap(find.text('Save Account'));
      await tester.pumpAndSettle();

      expect(client.accountPosts, 1);
      expect(find.text('Account added successfully.'), findsOneWidget);
      expect(find.text('245.75'), findsOneWidget);
      expect(find.text('Dinner with family'), findsOneWidget);
      final dropdown = tester.widget<CustomDropdown<int>>(
        find.byKey(const ValueKey('transaction-account-dropdown')),
      );
      expect(dropdown.value, 9);
      expect(find.text('New bank'), findsOneWidget);
    },
  );

  testWidgets('quick add prevents a double account submission in dark mode', (
    tester,
  ) async {
    final client = await pumpForm(
      tester,
      initialType: 'income',
      themeMode: ThemeMode.dark,
    );

    await tester.tap(find.byKey(const ValueKey('quick-add-account-button')));
    await tester.pumpAndSettle();
    final nameField = find.descendant(
      of: find.byKey(const ValueKey('account-name-field')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(nameField, 'Savings');

    await tester.tap(find.text('Save Account'));
    await tester.tap(find.text('Save Account'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(client.accountPosts, 1);
    expect(tester.takeException(), isNull);
  });
}
