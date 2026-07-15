import 'package:expense_tracker/presentation/widgets/brand_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('brand widgets resolve their intended asset paths', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Column(children: [AppLogo(), AppIconImage()])),
      ),
    );

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(2));
    expect(
      (images[0].image as AssetImage).assetName,
      'lib/assets/images/app_logo.png',
    );
    expect(
      (images[1].image as AssetImage).assetName,
      'lib/assets/images/app_icon.jpg',
    );
  });

  testWidgets('logo remains constrained without adding a white card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: Center(child: AppLogo(width: 180))),
      ),
    );

    final size = tester.getSize(find.byType(Image));
    expect(size.width, 180);
    expect(size.height, lessThan(60));
    expect(
      find.descendant(
        of: find.byType(AppLogo),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
