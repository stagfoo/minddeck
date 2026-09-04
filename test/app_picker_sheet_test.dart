import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minddeck/app_picker_sheet.dart';
import 'package:minddeck/card_deck.dart';
import 'package:minddeck/models.dart';

final installed = [
  for (var i = 0; i < 40; i++)
    LaunchableApp(
      packageName: 'com.app$i',
      activityName: 'com.app$i.Main',
      label: 'App number $i',
    ),
];

final deck = CardDeck.seed();

/// Opens the picker on a phone-sized surface, optionally with the on-screen
/// keyboard up.
Future<void> open(
  WidgetTester tester, {
  double keyboard = 0,
  Size size = const Size(393, 451),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showAppPicker(
              context,
              card: deck.folders.first,
              deck: deck,
              installed: installed,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('does not overflow', () {
    testWidgets('with the keyboard closed', (tester) async {
      await open(tester);
      expect(tester.takeException(), isNull);
    });

    // Typing into the search field raises the keyboard, which on this phone
    // takes over half the screen. The sheet used to cap its height at a share
    // of the whole screen and *then* pad by that same inset, spending it twice
    // and overflowing by 27 pixels.
    testWidgets('with a keyboard taking most of the screen', (tester) async {
      await open(tester, keyboard: 245);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a keyboard taking two thirds of the screen',
        (tester) async {
      await open(tester, keyboard: 300);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a short screen with the keyboard up', (tester) async {
      await open(tester, keyboard: 200, size: const Size(360, 360));
      expect(tester.takeException(), isNull);
    });
  });

  group('stays usable with the keyboard up', () {
    testWidgets('the search field and the add button are both reachable',
        (tester) async {
      // A sheet that fits but hides its own confirm button is no better than
      // one that overflows.
      await open(tester, keyboard: 245);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('picking an app still updates the button', (tester) async {
      await open(tester, keyboard: 245);
      await tester.tap(find.text('App number 0'));
      await tester.pumpAndSettle();
      expect(find.text('Add 1'), findsOneWidget);
    });
  });
}
