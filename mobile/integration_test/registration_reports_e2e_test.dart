import 'package:expense_tracker/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('registers through Laravel and opens an empty report', (
    tester,
  ) async {
    app.main();
    await _pumpUntil(
      tester,
      () =>
          find.text('Skip').evaluate().isNotEmpty ||
          find.text('Sign Up').evaluate().isNotEmpty,
    );

    // A clean test install starts at onboarding.
    final skip = find.text('Skip');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await _pumpUntil(
        tester,
        () => find.text('Sign Up').evaluate().isNotEmpty,
      );
    }

    expect(find.text('Sign Up'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    final unique = DateTime.now().microsecondsSinceEpoch;
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(5));
    await tester.enterText(fields.at(0), 'E2E Registration User');
    await tester.enterText(fields.at(1), 'budgetbee-e2e-$unique@example.com');
    await tester.enterText(
      fields.at(2),
      '+88019${unique.toString().substring(7)}',
    );
    await tester.enterText(fields.at(3), 'ValidPass123!');
    await tester.enterText(fields.at(4), 'ValidPass123!');
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('E2E Registration User'), findsOneWidget);

    await tester.tap(find.text('Reports').last);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Analytics'), findsOneWidget);
    expect(
      find.text('No report data is available for the selected period.'),
      findsOneWidget,
    );
    expect(find.text('Something went wrong'), findsNothing);
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20 && !condition(); attempt++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(condition(), isTrue);
}
