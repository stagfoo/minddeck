import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minddeck/deck_actions.dart';

Future<void> pump(
  WidgetTester tester, {
  VoidCallback? onAdd,
  VoidCallback? onSettings,
  VoidCallback? onLongPressSettings,
}) async {
  tester.view.physicalSize = const Size(393, 451) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const Expanded(child: SizedBox()),
          DeckActions(
            onAdd: onAdd ?? () {},
            onSettings: onSettings ?? () {},
            onLongPressSettings: onLongPressSettings,
          ),
        ],
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sits at the bottom left, leaving the top edge to the deck',
      (tester) async {
    // A bar above the stack reads as a gap the cards start below, which undoes
    // the impression that they are a deck resting on the screen.
    await pump(tester);
    final add = tester.getRect(find.byIcon(Icons.add_rounded));
    final screen = tester.getRect(find.byType(Scaffold));

    expect(add.left, lessThan(screen.width / 2));
    expect(add.top, greaterThan(screen.height / 2));
  });

  testWidgets('add comes before settings', (tester) async {
    await pump(tester);
    expect(
      tester.getRect(find.byIcon(Icons.add_rounded)).left,
      lessThan(tester.getRect(find.byIcon(Icons.settings_outlined)).left),
    );
  });

  testWidgets('both buttons fire', (tester) async {
    var added = 0;
    var settings = 0;
    await pump(tester, onAdd: () => added++, onSettings: () => settings++);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(added, 1);
    expect(settings, 1);
  });

  testWidgets('long-pressing settings reports the panel geometry',
      (tester) async {
    var reported = 0;
    await pump(tester, onLongPressSettings: () => reported++);
    await tester.longPress(find.byIcon(Icons.settings_outlined));
    expect(reported, 1);
  });

  testWidgets('a plain tap on settings is not a long press', (tester) async {
    var settings = 0;
    var reported = 0;
    await pump(
      tester,
      onSettings: () => settings++,
      onLongPressSettings: () => reported++,
    );
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(settings, 1);
    expect(reported, 0);
  });
}
