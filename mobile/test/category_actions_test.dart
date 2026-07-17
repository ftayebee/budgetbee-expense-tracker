import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_exception.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/presentation/providers/app_providers.dart';
import 'package:expense_tracker/presentation/screens/categories/categories_screen.dart';
import 'package:expense_tracker/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _CategoryApiClient extends ApiClient {
  _CategoryApiClient() : super(TokenStorage());

  final categories = <Map<String, dynamic>>[
    {
      'id': 1,
      'name': 'Bills',
      'type': 'expense',
      'icon': '⚡',
      'color': '#F59E0B',
      'is_default': true,
    },
    {
      'id': 2,
      'name': 'Food',
      'type': 'expense',
      'icon': '🍔',
      'color': '#EF4444',
      'is_default': true,
    },
    {
      'id': 3,
      'name': 'Health',
      'type': 'expense',
      'icon': '🏥',
      'color': '#10B981',
      'is_default': true,
    },
    {
      'id': 4,
      'name': 'Custom',
      'type': 'expense',
      'icon': '🎁',
      'color': '#6366F1',
      'is_default': false,
    },
  ];
  bool conflictOnDelete = false;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == '/categories') return categories;
    if (path == '/budgets') return [];
    return [];
  }

  @override
  Future<dynamic> delete(String path) async {
    if (conflictOnDelete) {
      throw ApiException(
        'This category is used by existing transactions and cannot be deleted.',
        statusCode: 409,
      );
    }
    final id = int.parse(path.split('/').last);
    categories.removeWhere((category) => category['id'] == id);
    return null;
  }
}

void main() {
  Future<_CategoryApiClient> pumpCategories(WidgetTester tester) async {
    final api = _CategoryApiClient();
    final repositories = Repositories(api);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => CategoryProvider(repositories.categories),
          ),
          ChangeNotifierProvider(
            create: (_) => BudgetProvider(repositories.budgets),
          ),
        ],
        child: MaterialApp(
          home: const CategoriesScreen(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets('default and custom category edit buttons are actionable', (
    tester,
  ) async {
    await pumpCategories(tester);

    expect(find.byIcon(Icons.edit), findsNWidgets(4));
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();

    expect(find.text('Edit Category'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(nameField.controller?.text, 'Bills');
    expect(find.text('Monthly Budget (Optional)'), findsOneWidget);
  });

  testWidgets('delete confirms and surfaces the backend conflict message', (
    tester,
  ) async {
    final api = await pumpCategories(tester);
    api.conflictOnDelete = true;

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete category?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This category is used by existing transactions and cannot be deleted.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('unused category deletion refreshes the visible list', (
    tester,
  ) async {
    await pumpCategories(tester);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Custom'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
  });
}
