import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/analytics/presentation/premium_analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final score in [0, 9, 69, 100]) {
    testWidgets(
      'health gauge keeps score $score centered at large text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: FinancialHealthGauge(
                  score: score,
                  color: AppColors.income,
                ),
              ),
            ),
          ),
        );

        expect(find.text('$score'), findsOneWidget);
        expect(find.text('/100'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
