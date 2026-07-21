import 'package:expense_tracker/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('release reaches Laravel and renders a 422 field error', (
    tester,
  ) async {
    app.main();
    await _pumpUntil(
      tester,
      () =>
          find.text('Skip').evaluate().isNotEmpty ||
          find.text('Sign Up').evaluate().isNotEmpty,
    );
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await _pumpUntil(
        tester,
        () => find.text('Sign Up').evaluate().isNotEmpty,
      );
    }

    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), List.filled(256, 'x').join());
    await tester.enterText(
      fields.at(1),
      'release-smoke-${DateTime.now().microsecondsSinceEpoch}@example.com',
    );
    await tester.enterText(fields.at(3), 'ValidPass123!');
    await tester.enterText(fields.at(4), 'ValidPass123!');
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      find.text('The name field must not be greater than 255 characters.'),
      findsOneWidget,
    );
    expect(find.text('Create Your Account'), findsOneWidget);
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20 && !condition(); attempt++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(condition(), isTrue);
}
