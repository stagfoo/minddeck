import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/app_picker_screen.dart';
import 'package:rolidecks/card_deck.dart';
import 'package:rolidecks/models.dart';

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
/// keyboard already up.
Future<List<String>?> open(
  WidgetTester tester, {
  double keyboard = 0,
  Size size = const Size(393, 451),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
  addTearDown(tester.view.reset);

  List<String>? chosen;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              chosen = await showAppPicker(
                context,
                card: deck.folders.first,
                deck: deck,
                installed: installed,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return chosen;
}

/// Raises the on-screen keyboard the way the platform does: the view's insets
/// change, and the app rebuilds against them.
Future<void> raiseKeyboard(WidgetTester tester, {double height = 245}) async {
  tester.view.viewInsets = FakeViewPadding(bottom: height * 3);
  await tester.pumpAndSettle();
}

void main() {
  group('the search field keeps focus', () {
    // As a bottom sheet this folded its title away once the keyboard was up,
    // to win back room. That changed the number of children in the column, so
    // the search field shifted position within it — and Flutter matches
    // unkeyed children by position, so the field's element was rebuilt against
    // the title's and lost focus, closing the keyboard as soon as it opened.
    testWidgets('and what was typed survives the keyboard opening',
        (tester) async {
      // The sharpest symptom of the rebuild: against the old shape the focus
      // node is replaced and the text typed so far is simply gone, so the
      // search resets under you as the keyboard appears.
      await open(tester);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'number 1');
      await tester.pumpAndSettle();
      final before = FocusManager.instance.primaryFocus;

      await raiseKeyboard(tester);

      expect(find.text('number 1'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(before));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('while typing with the keyboard up', (tester) async {
      await open(tester);
      await raiseKeyboard(tester);
      final before = FocusManager.instance.primaryFocus;

      await tester.enterText(find.byType(TextField), 'app number 1');
      await tester.pumpAndSettle();

      expect(FocusManager.instance.primaryFocus, same(before));
      expect(find.text('App number 1'), findsWidgets);
    });

    testWidgets('and the title never disappears to make room', (tester) async {
      // Nothing is added to or removed from the tree when the keyboard opens;
      // that is what the focus depends on.
      await open(tester);
      expect(find.textContaining('Add to'), findsOneWidget);
      await raiseKeyboard(tester);
      expect(find.textContaining('Add to'), findsOneWidget);
    });
  });

  group('does not overflow', () {
    testWidgets('with the keyboard closed', (tester) async {
      await open(tester);
      expect(tester.takeException(), isNull);
    });

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
      await open(tester, keyboard: 200, size: const Size(360, 320));
      expect(tester.takeException(), isNull);
    });
  });

  group('picking', () {
    testWidgets('the search field and the add button are both reachable',
        (tester) async {
      await open(tester, keyboard: 245);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('choosing apps updates the button and returns them',
        (tester) async {
      await open(tester);
      await tester.tap(find.text('App number 0'));
      await tester.tap(find.text('App number 1'));
      await tester.pumpAndSettle();
      expect(find.text('Add 2'), findsOneWidget);
    });

    testWidgets('backing out returns nothing', (tester) async {
      await open(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
    });
  });
}
