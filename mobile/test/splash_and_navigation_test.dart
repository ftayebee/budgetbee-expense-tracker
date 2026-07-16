import 'dart:io';

import 'package:expense_tracker/core/navigation/app_page_transitions.dart';
import 'package:expense_tracker/core/navigation/main_tab_scope.dart';
import 'package:expense_tracker/presentation/widgets/app_widgets.dart';
import 'package:expense_tracker/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native splash configuration is light for default and dark system modes',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('color: "#FFF8F3"'));
      expect(pubspec, contains('color_dark: "#FFF8F3"'));
      expect(pubspec, contains('icon_background_color: "#FFF8F3"'));
    },
  );

  testWidgets(
    'central forward transition supports natural reverse navigation',
    (tester) async {
      late BuildContext homeContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              homeContext = context;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );
      Navigator.of(homeContext).push(
        AppPageTransitions.route<void>(
          builder: (_) => const Scaffold(body: Text('Next')),
          settings: const RouteSettings(name: '/next'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);

      Navigator.of(tester.element(find.text('Next'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets('bottom navigation switches the persistent tab shell in place', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: MainTabScope(
          activeIndex: 0,
          onSelect: (index) => selected = index,
          child: const Scaffold(
            bottomNavigationBar: PrototypeBottomNav(
              active: AppRoutes.dashboard,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Transactions'));
    expect(selected, 1);
  });
}
